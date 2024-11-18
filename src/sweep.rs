use crate::StepAction::{GlobalUpdate, LocalUpdate, ParallelTempering, PlaneShift};

use clap::Parser;

use gaugemc::{CudaBackend, CudaError, DualState, SiteIndex};

use ndarray::{s, Array1, Array2, Array3, Array6, Axis};
use ndarray_npy::NpzWriter;
use rand::prelude::SliceRandom;
use rand::Rng;
use serde::{Deserialize, Serialize};
use std::fs::File;
use gauge_mc_runner::Potential;


#[derive(Parser, Debug, Serialize, Deserialize)]
#[command(version, about, long_about = None)]
struct Args {
    #[arg(short, long, default_value_t = 1)]
    replicas_ks: usize,
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
    plane_shift_updates_per_step: usize,
    #[arg(short, long, default_value_t = 1)]
    tempering_updates_per_step: usize,
    #[arg(short, long, default_value_t = 100)]
    warmup_samples: usize,
    #[arg(long, default_value_t = 0.5)]
    klow: f32,
    #[arg(long, default_value_t = 1.5)]
    khigh: f32,
    #[arg(long, default_value_t = 0)]
    hot_warmup_samples: usize,
    #[arg(long, default_value_t = 2.0)]
    khot_start: f32,
    #[arg(short, long, default_value = None)]
    chemical_potential_replicas: Option<usize>,
    #[arg(long, default_value_t = 0.0)]
    chemicallow: f32,
    #[arg(long, default_value_t = 0.5)]
    chemicalhigh: f32,
    #[arg(long, default_value_t = 10)]
    log_every: usize,
    #[arg(long, default_value = "villain")]
    potential_type: Potential,
    #[arg(long, default_value_t = 64)]
    potential_values: usize,
    #[arg(long, default_value = None)]
    cap_potentials: Option<f32>,
    #[arg(short, long, default_value = "out.npz")]
    output: String,
    #[arg(long, default_value_t = false)]
    output_winding: bool,
    #[arg(long, default_value_t = false)]
    output_plaquettes: bool,
    #[arg(long, default_value = None, num_args = 0.., value_delimiter = ' ')]
    background_winding: Option<Vec<i32>>,
    #[arg(long, default_value = None)]
    config_input: Option<String>,
    #[arg(long, default_value = None)]
    config_output: Option<String>,
    #[arg(long, default_value_t = false)]
    output_tempering_debug: bool,
    #[arg(long, default_value = None)]
    device_id: Option<usize>,
}

#[derive(Copy, Clone, Debug, Eq, PartialEq)]
enum StepAction {
    LocalUpdate,
    GlobalUpdate,
    ParallelTempering,
    PlaneShift(u16),
}

struct RunResult {
    // Action
    actions: Array2<f32>,
    // Winding numbers
    windings: Option<Array3<i32>>,
    // Plaquette counts
    plaquettes: Option<Array3<u32>>,
    // The unique values of ks
    ks: Array1<f32>,
    // The value of k for each replica
    replica_ks: Array1<f32>,
    // The full V array for each replica
    potentials: Array2<f32>,
    // The unique values of mu
    mus: Option<Array1<f32>>,
    // The value of mu for each replica
    replica_mus: Option<Array1<f32>>,
    // The gpu state
    state: CudaBackend,
}

fn make_vns(potential: &Potential, ks: Array1<f32>, potential_values: usize, cap: Option<f32>) -> Array2<f32> {
    let mut vns = Array2::zeros((
        ks.shape()[0],
        potential_values,
    ));
    ndarray::Zip::indexed(&mut vns).for_each(|(r, np), x| {
        *x = potential.eval(np as u32, ks[r]);
    });
    if let Some(cap) = cap {
        vns.slice_mut(s![.., -1]).iter_mut().for_each(|x| *x = cap);
    }
    vns
}

fn run(args: &Args) -> Result<RunResult, String> {
    let chemical_potential_replicas = args.chemical_potential_replicas.unwrap_or(1);

    let ks = match args.replicas_ks {
        1 => vec![(args.khigh + args.klow) / 2.0; 1],
        r => {
            let dk = (args.khigh - args.klow) / (r as f32 - 1.0);
            (0..r).map(|ir| ir as f32 * dk + args.klow).collect()
        }
    };
    log::debug!("Running on ks: {:?}", ks);
    let ks = Array1::from_vec(ks);

    let mus = match args.chemical_potential_replicas {
        None => vec![0.0; 1],
        Some(1) => vec![(args.chemicalhigh + args.chemicallow) / 2.0; 1],
        Some(r) => {
            let dk = (args.chemicalhigh - args.chemicallow) / (r as f32 - 1.0);
            (0..r).map(|ir| ir as f32 * dk + args.chemicallow).collect()
        }
    };
    log::debug!("Running on mus: {:?}", mus);
    let mus = Array1::from_vec(mus);

    let mut replica_ks = Array1::zeros(args.replicas_ks * chemical_potential_replicas);
    replica_ks.iter_mut().enumerate().for_each(|(r, k)| *k = ks[r % args.replicas_ks]);
    let vns = make_vns(&args.potential_type, replica_ks, args.potential_values, args.cap_potentials);

    let mut replica_ks = Array1::zeros(args.replicas_ks * chemical_potential_replicas);
    ndarray::Zip::indexed(&mut replica_ks).for_each(|r, x| {
        let kr = r % args.replicas_ks;
        *x = ks[kr];
    });
    let mut replica_mus = Array1::zeros(args.replicas_ks * chemical_potential_replicas);
    ndarray::Zip::indexed(&mut replica_mus).for_each(|r, x| {
        let mur = r / args.replicas_ks;
        *x = mus[mur];
    });

    let state = if let Some(background_windings) = args.background_winding.as_ref() {
        let mut background_windings = background_windings.clone();
        background_windings.extend((background_windings.len()..6).map(|_| 0));

        let mut plaquettes = Array6::zeros((
            vns.shape()[0],
            args.systemsize,
            args.systemsize,
            args.systemsize,
            args.systemsize,
            6,
        ));
        plaquettes
            .slice_mut(s![.., .., .., 0, 0, 0])
            .iter_mut()
            .for_each(|x| *x = background_windings[0]);
        plaquettes
            .slice_mut(s![.., .., 0, .., 0, 1])
            .iter_mut()
            .for_each(|x| *x = background_windings[1]);
        plaquettes
            .slice_mut(s![.., .., 0, 0, .., 2])
            .iter_mut()
            .for_each(|x| *x = background_windings[2]);
        plaquettes
            .slice_mut(s![.., 0, .., .., 0, 3])
            .iter_mut()
            .for_each(|x| *x = background_windings[3]);
        plaquettes
            .slice_mut(s![.., 0, .., 0, .., 4])
            .iter_mut()
            .for_each(|x| *x = background_windings[4]);
        plaquettes
            .slice_mut(s![.., 0, 0, .., .., 5])
            .iter_mut()
            .for_each(|x| *x = background_windings[5]);

        Some(DualState::new_plaquettes(plaquettes))
    } else {
        None
    };

    let mut state = CudaBackend::new(
        SiteIndex::new(
            args.systemsize,
            args.systemsize,
            args.systemsize,
            args.systemsize,
        ),
        vns.clone(),
        state,
        None,
        args.device_id,
        args.chemical_potential_replicas
            .map(|_| replica_mus.clone()),
    )
        .map_err(|x| x.to_string())?;
    state.set_parallel_tracking(args.output_tempering_debug);

    let mut rng = rand::thread_rng();
    let mut local_versus_global = (0..args.local_updates_per_step)
        .map(|_| LocalUpdate)
        .chain((0..args.global_updates_per_step).map(|_| GlobalUpdate))
        .chain((0..args.plane_shift_updates_per_step).flat_map(|_| (0..6).map(PlaneShift)))
        .chain((0..args.tempering_updates_per_step).map(|_| ParallelTempering))
        .collect::<Vec<_>>();

    let mut parallel_perms = vec![];
    let perm_ks_a = (0..chemical_potential_replicas)
        .flat_map(|mur| {
            (0..args.replicas_ks / 2).map(move |kr| {
                (
                    (2 * kr) + mur * args.replicas_ks,
                    (2 * kr + 1) + mur * args.replicas_ks,
                )
            })
        })
        .collect();
    parallel_perms.push(perm_ks_a);

    let perm_ks_b = (0..chemical_potential_replicas)
        .flat_map(|mur| {
            (0..(args.replicas_ks - 1) / 2)
                .map(move |kr| {
                    (
                        (2 * kr + 1) + mur * args.replicas_ks,
                        (2 * (kr + 1)) + mur * args.replicas_ks,
                    )
                })
                .collect::<Vec<_>>()
        })
        .collect();
    parallel_perms.push(perm_ks_b);

    if let Some(chemical_potential_replicas) = args.chemical_potential_replicas {
        let perm_mus_a = (0..args.replicas_ks)
            .flat_map(|kr| {
                (0..chemical_potential_replicas / 2).map(move |mur| {
                    (
                        kr + (2 * mur) * args.replicas_ks,
                        kr + (2 * mur + 1) * args.replicas_ks,
                    )
                })
            })
            .collect();
        parallel_perms.push(perm_mus_a);

        let perm_mus_b = (0..args.replicas_ks)
            .flat_map(|kr| {
                (0..(chemical_potential_replicas - 1) / 2).map(move |mur| {
                    (
                        kr + (2 * mur + 1) * args.replicas_ks,
                        kr + (2 * (mur + 1)) * args.replicas_ks,
                    )
                })
            })
            .collect();
        parallel_perms.push(perm_mus_b);
    };
    log::debug!("Permutations: {:?}", parallel_perms);

    if args.hot_warmup_samples > 0 {
        log::info!("Hot Warmup at k={}", args.khot_start);

        let mut replica_ks = Array1::zeros(args.replicas_ks * chemical_potential_replicas);
        replica_ks.iter_mut().for_each(|k| *k = args.khot_start);
        let hot_vns = make_vns(&args.potential_type, replica_ks, args.potential_values, args.cap_potentials);

        state.set_vns(hot_vns.view())
            .map_err(|x| x.to_string())?;
        for warmup_sample in 0..args.hot_warmup_samples {
            if warmup_sample % args.log_every == 0 {
                log::info!("Hot warmup {}/{}", warmup_sample, args.hot_warmup_samples);
            }
            steps(
                args,
                &mut local_versus_global,
                &mut state,
                &parallel_perms,
                &mut rng,
            )
                .map_err(|x| x.to_string())?;
        }
        state.set_vns(vns.view())
            .map_err(|x| x.to_string())?;
        log::info!("Done!");
    }

    for warmup_sample in 0..args.warmup_samples {
        if warmup_sample % args.log_every == 0 {
            log::info!("Warmup {}/{}", warmup_sample, args.warmup_samples);
        }
        steps(
            args,
            &mut local_versus_global,
            &mut state,
            &parallel_perms,
            &mut rng,
        )
            .map_err(|x| x.to_string())?;
    }
    log::info!("Done!");

    let mut action_output = Array2::zeros((
        args.num_samples,
        args.replicas_ks * chemical_potential_replicas,
    ));
    let mut winding_output = if args.output_winding {
        Some(Array3::zeros((
            args.num_samples,
            args.replicas_ks * chemical_potential_replicas,
            6,
        )))
    } else {
        None
    };
    let mut plaquette_output = if args.output_plaquettes {
        Some(Array3::zeros((
            args.num_samples,
            args.replicas_ks * chemical_potential_replicas,
            args.potential_values * 2 - 1,
        )))
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
            &parallel_perms,
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
        if let Some(plaquette_output) = plaquette_output.as_mut() {
            let plaqs = state.get_plaquette_counts().map_err(|x| x.to_string())?;
            let mut plaqs_sample = plaquette_output.index_axis_mut(Axis(0), sample_number);
            plaqs_sample
                .iter_mut()
                .zip(plaqs)
                .for_each(|(x, y)| *x = y);
        }
    }

    let mus = args.chemical_potential_replicas.map(|_| mus);
    let replica_mus = args.chemical_potential_replicas.map(|_| replica_mus);

    let result = RunResult {
        actions: action_output,
        windings: winding_output,
        plaquettes: plaquette_output,
        ks,
        mus,
        potentials: vns,
        replica_mus,
        replica_ks,
        state,
    };

    log::info!("Done!");
    Ok(result)
}

fn steps<R: Rng>(
    args: &Args,
    local_versus_global: &mut Vec<StepAction>,
    state: &mut CudaBackend,
    parallel_perms: &[Vec<(usize, usize)>],
    rng: &mut R,
) -> Result<(), CudaError> {
    for i in 0..args.steps_per_sample {
        local_versus_global.shuffle(rng);
        for update in local_versus_global.iter() {
            match update {
                LocalUpdate => state.run_local_update_sweep()?,
                GlobalUpdate => state.run_global_update_sweep()?,
                ParallelTempering => {
                    state.parallel_tempering_step(&parallel_perms[i % parallel_perms.len()])?
                }
                PlaneShift(p) => {
                    state.run_plane_shift(*p)?
                }
            }
        }
    }
    Ok(())
}

fn write_output<Str: AsRef<str>>(runresult: &RunResult, filename: Str) -> Result<(), String> {
    let mut npz =
        NpzWriter::new_compressed(File::create(filename.as_ref()).map_err(|x| x.to_string())?);
    npz.add_array("actions", &runresult.actions)
        .map_err(|x| x.to_string())?;
    if let Some(windings) = runresult.windings.as_ref() {
        npz.add_array("windings", windings)
            .map_err(|x| x.to_string())?;
    }
    if let Some(plaquettes) = runresult.plaquettes.as_ref() {
        npz.add_array("plaquettes", plaquettes)
            .map_err(|x| x.to_string())?;
    }
    npz.add_array("ks", &runresult.ks)
        .map_err(|x| x.to_string())?;
    npz.add_array("replica_ks", &runresult.replica_ks)
        .map_err(|x| x.to_string())?;
    npz.add_array("potentials", &runresult.potentials)
        .map_err(|x| x.to_string())?;
    if let Some(mus) = runresult.mus.as_ref() {
        npz.add_array("mus", mus).map_err(|x| x.to_string())?;
    }
    if let Some(replica_mus) = runresult.replica_mus.as_ref() {
        npz.add_array("replica_mus", replica_mus)
            .map_err(|x| x.to_string())?;
    }
    if let Some(parallel_debug) = runresult.state.get_parallel_tracking() {
        let nreplicas = runresult.replica_ks.shape()[0];
        let mut result = Array2::zeros((nreplicas, nreplicas));
        parallel_debug.iter().for_each(|((a, b), (succ, att))| {
            result[[*a, *b]] = (*succ as f32) / (*att as f32);
            result[[*b, *a]] = result[[*a, *b]];
        });
        npz.add_array("tempering", &result)
            .map_err(|x| x.to_string())?;
    }
    npz.finish().map_err(|x| x.to_string())?;
    Ok(())
}

fn main() -> Result<(), String> {
    env_logger::init();

    let mut args = Args::parse();
    let original_output = args.output.clone();
    let original_config_output = args.config_output.clone();

    if let Some(config_input) = args.config_input.clone() {
        log::debug!("Reading config file from {}", config_input);
        let f = File::open(&config_input).map_err(|x| x.to_string())?;
        args = serde_yaml::from_reader(f).map_err(|x| x.to_string())?;
        args.config_input = Some(config_input);
    }
    log::debug!(
        "Overwriting outputs: {} -> {} \t {:?} -> {:?}",
        args.output,
        original_output,
        args.config_output,
        original_config_output
    );
    args.output = original_output;
    args.config_output = original_config_output;

    if let Some(config_output) = &args.config_output {
        log::debug!("Writing config file to {}", config_output);
        let f = File::create(config_output).map_err(|x| x.to_string())?;
        serde_yaml::to_writer(f, &args).map_err(|x| x.to_string())?;
    }

    log::debug!("Config: {:?}", args);

    let result = run(&args).map_err(|x| x.to_string())?;
    write_output(&result, &args.output)?;

    Ok(())
}
