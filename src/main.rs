use crate::StepAction::{GlobalUpdate, LocalUpdate, ParallelTempering};
use chrono::Local;
use clap::Parser;
use env_logger::Builder;
use gaugemc::{CudaBackend, CudaError, DualState, SiteIndex};
use log::LevelFilter;
use ndarray::{Array2, Array6, Axis};
use ndarray_npy::NpzWriter;
use rand::prelude::SliceRandom;
use rand::Rng;
use std::fmt::{Display, Formatter};
use std::fs::File;
use std::io::Write;

/// Simple program to greet a person
#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    #[arg(short, long, default_value_t = 1)]
    replicas: usize,
    #[arg(short = 'L', long, default_value_t = 8)]
    systemsize: usize,
    #[arg(short = 'N', long, default_value_t = 100)]
    num_samples: usize,
    #[arg(short, long, default_value_t = 10)]
    steps_per_sample: usize,
    #[arg(short, long, default_value_t = 8)]
    local_updates_per_step: usize,
    #[arg(short, long, default_value_t = 1)]
    global_updates_per_step: usize,
    #[arg(short, long, default_value_t = 1)]
    tempering_updates_per_step: usize,
    #[arg(short, long, default_value_t = 100)]
    warmup_samples: usize,
    #[arg(long, default_value_t = 0.5)]
    klow: f32,
    #[arg(long, default_value_t = 1.5)]
    khigh: f32,
    #[arg(long, default_value_t = false)]
    verbose: bool,
    #[arg(long, default_value_t = 10)]
    log_every: usize,
    #[arg(long, default_value_t = Potential::villain)]
    potential_type: Potential,
    #[arg(short, long, default_value_t = String::from("out.npz"))]
    output: String,
}

#[derive(clap::ValueEnum, Clone, Default, Debug)]
enum Potential {
    #[default]
    villain,
    cosine,
    binary,
}

impl Display for Potential {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_str(&format!("{:?}", self))
    }
}

#[derive(Copy, Clone, Debug, Eq, PartialEq)]
enum StepAction {
    LocalUpdate,
    GlobalUpdate,
    ParallelTempering,
}
fn run(args: &Args) -> Result<Array2<f32>, CudaError> {
    let init_state = Array6::zeros((
        args.replicas,
        args.systemsize,
        args.systemsize,
        args.systemsize,
        args.systemsize,
        6,
    ));
    let mut vns = Array2::zeros((args.replicas, 64));

    let ks = match args.replicas {
        1 => vec![(args.khigh + args.klow) / 2.0; 1],
        r => {
            let dk = (args.khigh - args.klow) / (r as f32 - 1.0);
            (0..r).map(|ir| ir as f32 * dk + args.klow).collect()
        }
    };
    if args.verbose {
        println!("Running on ks: {:?}", ks);
    }

    ndarray::Zip::indexed(&mut vns).for_each(|(r, np), x| {
        *x = match args.potential_type {
            Potential::villain => ks[r] * (np.pow(2) as f32),
            Potential::cosine => {
                todo!()
            }
            Potential::binary => {
                todo!()
            }
        };
    });

    vns.axis_iter_mut(Axis(0))
        .enumerate()
        .for_each(|(i, mut v)| {
            v.iter_mut().enumerate().for_each(|(j, v)| {
                *v = ((i + 1) * (j.pow(2))) as f32 / 8.0;
            })
        });

    let mut state = CudaBackend::new(
        SiteIndex::new(
            args.systemsize,
            args.systemsize,
            args.systemsize,
            args.systemsize,
        ),
        vns,
        Some(DualState::new_plaquettes(init_state)),
        None,
        None,
        None,
    )?;

    let mut rng = rand::thread_rng();
    let mut local_versus_global = (0..args.local_updates_per_step)
        .map(|_| LocalUpdate)
        .chain((0..args.global_updates_per_step).map(|_| GlobalUpdate))
        .chain((0..args.tempering_updates_per_step).map(|_| ParallelTempering))
        .collect::<Vec<_>>();

    let perms_a = (0..args.replicas / 2)
        .map(|x| (2 * x, 2 * x + 1))
        .collect::<Vec<_>>();
    let perms_b = (0..(args.replicas - 1) / 2)
        .map(|x| (2 * x + 1, 2 * (x + 1)))
        .collect::<Vec<_>>();

    for warmup_sample in 0..args.warmup_samples {
        if warmup_sample % args.log_every == 0 {
            log::info!("Warmup {}/{}", warmup_sample, args.warmup_samples);
        }
        steps(
            args,
            &mut local_versus_global,
            &mut state,
            &perms_a,
            &perms_b,
            &mut rng,
        )?;
    }
    log::info!("Done!");

    let mut output = Array2::zeros((args.num_samples, args.replicas));
    output.axis_iter_mut(Axis(0)).enumerate().try_for_each(
        |(sample_number, mut sample)| -> Result<(), CudaError> {
            if sample_number % args.log_every == 0 {
                log::info!("Sampling {}/{}", sample_number, args.num_samples);
            }
            steps(
                args,
                &mut local_versus_global,
                &mut state,
                &perms_a,
                &perms_b,
                &mut rng,
            )?;
            let energies = state.get_action_per_replica()?;
            sample.iter_mut().zip(energies).for_each(|(x, y)| *x = y);
            Ok(())
        },
    )?;
    log::info!("Done!");
    Ok(output)
}

fn steps<R: Rng>(
    args: &Args,
    local_versus_global: &mut Vec<StepAction>,
    state: &mut CudaBackend,
    perms_a: &[(usize, usize)],
    perms_b: &[(usize, usize)],
    rng: &mut R,
) -> Result<(), CudaError> {
    for i in 0..args.steps_per_sample {
        local_versus_global.shuffle(rng);
        for update in local_versus_global.iter() {
            match update {
                LocalUpdate => state.run_local_update_sweep()?,
                GlobalUpdate => state.run_global_update_sweep()?,
                ParallelTempering => {
                    state.parallel_tempering_step(if i % 2 == 0 { &perms_a } else { &perms_b })?
                }
            }
        }
    }
    Ok(())
}

fn main() -> Result<(), String> {
    Builder::new()
        .format(|buf, record| {
            writeln!(
                buf,
                "{} [{}] - {}",
                Local::now().format("%Y-%m-%d %H:%M:%S"),
                record.level(),
                record.args()
            )
        })
        .filter(None, LevelFilter::Info)
        .init();

    let args = Args::parse();
    let output = run(&args).map_err(|x| x.to_string())?;
    let mut npz = NpzWriter::new(File::create(args.output).map_err(|x| x.to_string())?);
    npz.add_array("energies", &output)
        .map_err(|x| x.to_string())?;
    npz.finish().map_err(|x| x.to_string())?;
    Ok(())
}
