use std::fmt::{Display, Formatter};
use std::fs::File;
use clap::Parser;
use log::info;
use gaugemc::{CudaBackend, CudaError, SiteIndex};
use ndarray::{Array0, Array1, Array2};
use ndarray_npy::NpzWriter;
use num_complex::Complex;
use serde::{Deserialize, Serialize};

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
    #[arg(long, default_value_t = 128)]
    num_steps_per_sample: usize,
}

#[derive(clap::ValueEnum, Clone, Default, Debug, Serialize, Deserialize)]
#[serde(rename_all_fields = "kebab-case")]
enum Potential {
    #[default]
    Villain,
    Cosine,
    Binary,
}

impl Potential {
    fn eval(&self, n: u32, k: f32) -> f32 {
        match self {
            Potential::Villain => k * n.pow(2) as f32,
            Potential::Cosine => {
                if n == 0 {
                    0.0
                } else {
                    let t = scilib::math::bessel::i_nu(n as f64, Complex::from(k as f64));
                    let b = scilib::math::bessel::i_nu(0., Complex::from(k as f64));
                    assert!(t.im < f64::EPSILON);
                    assert!(b.im < f64::EPSILON);
                    let res = -(t.re / b.re).ln();
                    res as f32
                }
            }
            Potential::Binary => match n {
                0 => 0.0,
                1 => k,
                _ => 1000.,
            },
        }
    }
}

impl Display for Potential {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_str(&format!("{:?}", self))
    }
}

fn main() -> Result<(), CudaError> {
    env_logger::init();
    let args = Args::parse();

    let d: usize = args.systemsize;
    let num_replicas = d.pow(2) + 1;
    let mut vns = Array2::zeros((
        num_replicas,
        args.knum,
    ));
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

    state.initialize_wilson_loops_for_probs_incremental_square((0..num_replicas).collect(), 0)?;

    let num_counts = args.num_samples;
    let num_steps = args.num_steps_per_sample;
    for i in 0..num_counts {
        info!("Computing count {}/{}", i, num_counts);
        for _ in 0..num_steps {
            state.run_local_update_sweep()?;
        }

        state.calculate_wilson_loop_transition_probs()?;
    }
    let transition_probs = state.get_wilson_loop_transition_probs()?;

    let mut distribution = Array1::zeros((num_replicas, ));
    let mut free_energies = Array1::zeros((num_replicas, ));
    let mut acc = 1.0;
    free_energies[0] = 0.0;
    distribution[0] = 1.0;
    for i in 1..num_replicas {
        let new_logp = -free_energies[i - 1] + transition_probs[[i - 1, 1]].ln() as f64 - transition_probs[[i, 0]].ln() as f64;
        free_energies[i] = -new_logp;
        distribution[i] = new_logp.exp();
        acc += distribution[i];
    }
    distribution.iter_mut().for_each(|x| *x /= acc);

    let mut npz = NpzWriter::new(File::create(args.output).expect("Could not create file."));
    npz.add_array("L", &Array0::from_elem((), args.systemsize as u64)).expect("Could not add array to file.");
    npz.add_array("k", &Array0::from_elem((), args.k)).expect("Could not add array to file.");
    npz.add_array("transition_probs", &transition_probs).expect("Could not add array to file.");
    npz.add_array("sample_probs", &distribution).expect("Could not add array to file.");
    npz.add_array("free_energy", &free_energies).expect("Could not add array to file.");
    npz.finish().expect("Could not write to file.");

    Ok(())
}