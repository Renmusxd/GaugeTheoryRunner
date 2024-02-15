use crate::StepAction::{GlobalUpdate, LocalUpdate, ParallelTempering};
use chrono::Local;
use clap::Parser;
use env_logger::Builder;
use gaugemc::{CudaBackend, CudaError, DualState, SiteIndex};
use log::LevelFilter;
use ndarray::{s, Array1, Array2, Array3, Array6, ArrayView1, ArrayView2, ArrayView3, Axis};
use ndarray_npy::NpzWriter;
use rand::prelude::SliceRandom;
use rand::Rng;
use serde::{Deserialize, Serialize};
use std::fmt::{Display, Formatter};
use std::fs::File;
use std::io::Write;
use num_complex::Complex;

/// Simple program to greet a person
#[derive(Parser, Debug, Serialize, Deserialize)]
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
    #[arg(long, default_value_t = 10)]
    log_every: usize,
    #[arg(long, default_value_t = Potential::villain)]
    potential_type: Potential,
    #[arg(short, long, default_value_t = String::from("action.npz"))]
    output_action: String,
    #[arg(long, default_value_t = false)]
    output_winding: bool,
    #[arg(long, default_value_t = 0)]
    write_output_every: usize,
    #[arg(long, default_value = None)]
    config_input: Option<String>,
    #[arg(long, default_value = None)]
    config_output: Option<String>,
}

#[derive(clap::ValueEnum, Clone, Default, Debug, Serialize, Deserialize)]
enum Potential {
    #[default]
    villain,
    cosine,
    binary,
}

impl Potential {
    fn eval(&self, n: u32, k: f32) -> f32 {
        match self {
            Potential::villain => {
                k * n.pow(2) as f32
            }
            Potential::cosine => {
                if n == 0 {
                    0.0
                } else {
                    let t = scilib::math::bessel::i_nu(n as f64, Complex::from(k as f64));
                    let b = scilib::math::bessel::i_nu(0., Complex::from(k as f64));
                    assert!(t.im < f64::EPSILON);
                    assert!(b.im < f64::EPSILON);
                    let res = - (t.re/b.re).ln();
                    res as f32
                }
            }
            Potential::binary => {
                match n {
                    0 => 0.0,
                    1 => k,
                    _ => 1000.
                }
            }
        }
    }
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
fn run(args: &Args) -> Result<(Array2<f32>, Option<Array3<i32>>, Array1<f32>), String> {
    let mut vns = Array2::zeros((args.replicas, 64));

    let ks = match args.replicas {
        1 => vec![(args.khigh + args.klow) / 2.0; 1],
        r => {
            let dk = (args.khigh - args.klow) / (r as f32 - 1.0);
            (0..r).map(|ir| ir as f32 * dk + args.klow).collect()
        }
    };
    log::debug!("Running on ks: {:?}", ks);
    let ks = Array1::from_vec(ks);

    ndarray::Zip::indexed(&mut vns).for_each(|(r, np), x| {
        *x = args.potential_type.eval(np as u32, ks[r]);
    });

    let mut state = CudaBackend::new(
        SiteIndex::new(
            args.systemsize,
            args.systemsize,
            args.systemsize,
            args.systemsize,
        ),
        vns,
        Some(DualState::new_plaquettes(Array6::zeros((
            args.replicas,
            args.systemsize,
            args.systemsize,
            args.systemsize,
            args.systemsize,
            6,
        )))),
        None,
        None,
        None,
    )
    .map_err(|x| x.to_string())?;

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
        )
        .map_err(|x| x.to_string())?;
    }
    log::info!("Done!");

    let mut action_output = Array2::zeros((args.num_samples, args.replicas));
    let mut winding_output = if args.output_winding {
        Some(Array3::zeros((args.num_samples, args.replicas, 6)))
    } else {
        None
    };

    for sample_number in 0..args.num_samples {
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
        )
        .map_err(|x| x.to_string())?;

        let energies = state.get_action_per_replica().map_err(|x| x.to_string())?;
        let mut sample = action_output.index_axis_mut(Axis(0), sample_number);
        sample.iter_mut().zip(energies).for_each(|(x, y)| *x = y);

        if let Some(winding_output) = winding_output.as_mut() {
            let windings = state.get_winding_per_replica().map_err(|x| x.to_string())?;
            let mut winding_sample = winding_output.index_axis_mut(Axis(0), sample_number);
            winding_sample
                .iter_mut()
                .zip(windings)
                .for_each(|(x, y)| *x = y);
        }

        if args.write_output_every > 0 && (sample_number + 1) % args.write_output_every == 0 {
            log::debug!("Writing output to {}", args.output_action);
            let output_subview = action_output.slice(s![..=sample_number, ..]);
            write_output(
                output_subview,
                winding_output.as_ref().map(|x| x.view()),
                ks.view(),
                &args.output_action,
            )?;
        }
    }

    log::info!("Done!");
    Ok((action_output, winding_output, ks))
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

fn write_output<Str: AsRef<str>>(
    energies: ArrayView2<f32>,
    windings: Option<ArrayView3<i32>>,
    ks: ArrayView1<f32>,
    filename: Str,
) -> Result<(), String> {
    let mut npz =
        NpzWriter::new_compressed(File::create(filename.as_ref()).map_err(|x| x.to_string())?);
    npz.add_array("energies", &energies)
        .map_err(|x| x.to_string())?;
    if let Some(windings) = windings {
        npz.add_array("windings", &windings)
            .map_err(|x| x.to_string())?;
    }
    npz.add_array("ks", &ks).map_err(|x| x.to_string())?;
    npz.finish().map_err(|x| x.to_string())?;
    Ok(())
}

fn main() -> Result<(), String> {
    env_logger::init();

    let mut args = Args::parse();

    if let Some(config_input) = args.config_input.clone() {
        log::debug!("Reading config file from {}", config_input);
        let f = File::open(&config_input).map_err(|x| x.to_string())?;
        args = serde_yaml::from_reader(f).map_err(|x| x.to_string())?;
        args.config_input = Some(config_input);
    } else if let Some(config_output) = &args.config_output {
        log::debug!("Writing config file to {}", config_output);
        let f = File::create(config_output).map_err(|x| x.to_string())?;
        serde_yaml::to_writer(f, &args).map_err(|x| x.to_string())?;
    }

    log::debug!("Config: {:?}", args);

    let (energies, winding, ks) = run(&args).map_err(|x| x.to_string())?;
    write_output(
        energies.view(),
        winding.as_ref().map(|x| x.view()),
        ks.view(),
        &args.output_action,
    )?;

    Ok(())
}
