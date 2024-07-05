use clap::Parser;
use gaugemc::{CudaBackend, CudaError, SiteIndex};
use log::info;
use ndarray::{Array0, Array1, Array2, Array3, Axis};
use ndarray_npy::NpzWriter;
use serde::{Deserialize, Serialize};
use std::fs::File;
use gauge_mc_runner::Potential;

#[derive(Parser, Debug, Serialize, Deserialize)]
#[command(version, about, long_about = None)]
struct Args {
    #[arg(short = 'L', long, default_value_t = 8)]
    systemsize: usize,
    #[arg(short, long, default_value_t = 1.0)]
    k: f32,
    #[arg(long, default_value_t = 32)]
    knum: usize,
    #[arg(long, default_value = "villain")]
    potential_type: Potential,
    #[arg(short, long, default_value = "markov.npz")]
    output: String,
    #[arg(long, default_value = None)]
    device_id: Option<usize>,
    #[arg(short, long, default_value_t = 1024)]
    num_samples: usize,
    #[arg(long, default_value_t = 16)]
    num_steps_per_sample: usize,
    #[arg(long, default_value_t = 256)]
    warmup_steps: usize,
    #[arg(long, default_value_t = 0)]
    plaquette_type: u16,
    #[arg(long, default_value_t = true)]
    run_plane_shift_updates: bool,
    #[arg(long, default_value = None)]
    replica_index_low: Option<usize>,
    #[arg(long, default_value = None)]
    replica_index_high: Option<usize>,
}


fn main() -> Result<(), CudaError> {
    env_logger::init();
    let args = Args::parse();

    let d = args.systemsize;
    let replica_index_low = args.replica_index_low.unwrap_or(0);
    let replica_index_high = args.replica_index_high.unwrap_or_else(|| d.pow(2) + 1);
    let num_replicas = replica_index_high - replica_index_low;

    let mut vns = Array2::zeros((num_replicas, args.knum));
    ndarray::Zip::indexed(&mut vns).for_each(|(_, np), x| {
        *x = args.potential_type.eval(np as u32, args.k);
    });

    let mut state = CudaBackend::new(
        SiteIndex::new(d, d, d, d),
        vns,
        None,
        None,
        args.device_id,
        None,
    )?;

    let replica_indices = (replica_index_low..replica_index_high).collect::<Vec<_>>();
    state.initialize_wilson_loops_for_probs_incremental_square(
        replica_indices.clone(),
        args.plaquette_type,
    )?;

    let num_steps = args.warmup_steps;
    for _ in 0..num_steps {
        state.run_local_update_sweep()?;
        if args.run_plane_shift_updates {
            state.run_plane_shift(args.plaquette_type)?;
        }
    }

    let num_counts = args.num_samples;
    let num_steps = args.num_steps_per_sample;

    let mut all_transition_probs = Array3::zeros((args.num_samples, num_replicas, 2));
    all_transition_probs
        .axis_iter_mut(Axis(0))
        .enumerate()
        .try_for_each(|(i, mut x)| -> Result<(), CudaError> {
            info!("Computing count {}/{}", i, num_counts);
            for _ in 0..num_steps {
                state.run_local_update_sweep()?;
                if args.run_plane_shift_updates {
                    state.run_plane_shift(args.plaquette_type)?;
                }
            }
            state.reset_wilson_loop_transition_probs()?;
            state.calculate_wilson_loop_transition_probs()?;
            state.get_wilson_loop_transition_probs_into(x.as_slice_mut().unwrap())?;
            Ok(())
        })?;
    let average_transition_probs = all_transition_probs.mean_axis(Axis(0)).unwrap();
    let mut std_transition_probs = all_transition_probs.std_axis(Axis(0), 1.0);
    std_transition_probs
        .iter_mut()
        .zip(average_transition_probs.iter())
        .for_each(|(std, mean)| {
            *std /= mean;
        });
    let mut distribution = Array1::zeros((num_replicas,));
    let mut free_energies = Array1::zeros((num_replicas,));
    let mut std_error_free_energies = Array1::zeros((num_replicas,));
    let mut acc = 1.0;
    free_energies[0] = 0.0f64;
    std_error_free_energies[0] = 0.0f64;
    distribution[0] = 1.0f64;
    for i in 1..num_replicas {
        let delta_free = (average_transition_probs[[i - 1, 1]] as f64).ln()
            - (average_transition_probs[[i, 0]] as f64).ln();
        let delta_std_squared = (std_transition_probs[[i - 1, 1]].powi(2)
            + std_transition_probs[[i, 0]].powi(2)) as f64;

        let new_logp = -free_energies[i - 1] + delta_free;
        let std_err_new_logp = (std_error_free_energies[i - 1].powi(2) + delta_std_squared).sqrt();

        free_energies[i] = -new_logp;
        distribution[i] = new_logp.exp();
        std_error_free_energies[i] = std_err_new_logp;
        acc += distribution[i];
    }
    distribution.iter_mut().for_each(|x| *x /= acc);

    let mut npz = NpzWriter::new(File::create(args.output).expect("Could not create file."));
    npz.add_array("L", &Array0::from_elem((), args.systemsize as u64))
        .expect("Could not add L to file.");

    npz.add_array("systemsize", &Array0::from_elem((), args.systemsize as u64))
        .expect("Could not add systemsize to file.");
    npz.add_array("k", &Array0::from_elem((), args.k))
        .expect("Could not add k to file.");
    npz.add_array("knum", &Array0::from_elem((), args.knum as u64))
        .expect("Could not add knum to file.");
    if let Potential::Power(alpha) = &args.potential_type {
        npz.add_array("alpha", &Array0::from_elem((), *alpha))
            .expect("Could not add alpha to file.");
    }
    npz.add_array(
        "potential",
        &Array0::from_elem((), u8::from(args.potential_type)),
    )
        .expect("Could not add potential to file.");
    npz.add_array(
        "num_samples",
        &Array0::from_elem((), args.num_samples as u64),
    )
        .expect("Could not add num_samples to file.");
    npz.add_array(
        "num_steps_per_sample",
        &Array0::from_elem((), args.num_steps_per_sample as u64),
    )
        .expect("Could not add num_steps_per_sample to file.");
    npz.add_array(
        "warmup_steps",
        &Array0::from_elem((), args.warmup_steps as u64),
    )
        .expect("Could not add warmup_steps to file.");
    npz.add_array(
        "plaquette_type",
        &Array0::from_elem((), args.plaquette_type),
    )
        .expect("Could not add plaquette_type to file.");
    npz.add_array(
        "run_plane_shift_updates",
        &Array0::from_elem((), args.run_plane_shift_updates),
    )
        .expect("Could not add run_plane_shift_updates to file.");

    if let Some(device_id) = args.device_id {
        npz.add_array("device_id", &Array0::from_elem((), device_id as u64))
            .expect("Could not add device_id to file.");
    }
    if let Some(replica_index_low) = args.replica_index_low {
        npz.add_array(
            "replica_index_low",
            &Array0::from_elem((), replica_index_low as u64),
        )
            .expect("Could not add replica_index_low to file.");
    }
    if let Some(replica_index_high) = args.replica_index_high {
        npz.add_array(
            "replica_index_high",
            &Array0::from_elem((), replica_index_high as u64),
        )
            .expect("Could not add replica_index_high to file.");
    }

    npz.add_array(
        "replica_indices",
        &Array1::from_vec(replica_indices.into_iter().map(|x| x as u32).collect()),
    )
        .expect("Could not add replica_indices to file.");
    npz.add_array("all_transition_probs", &all_transition_probs)
        .expect("Could not add all_transition_probs to file.");
    npz.add_array("transition_probs", &average_transition_probs)
        .expect("Could not add transition_probs to file.");
    npz.add_array("sample_probs", &distribution)
        .expect("Could not add sample_probs to file.");
    npz.add_array("free_energy", &free_energies)
        .expect("Could not add free_energy to file.");
    npz.add_array("std_error_free_energies", &std_error_free_energies)
        .expect("Could not add std_error_free_energies to file.");
    npz.finish().expect("Could not write to file.");

    Ok(())
}
