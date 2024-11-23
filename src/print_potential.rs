use clap::Parser;
use gauge_mc_runner::Potential;
use serde::{Deserialize, Serialize};

#[derive(Parser, Debug, Serialize, Deserialize)]
#[command(version, about, long_about = None)]
struct Args {
    #[arg(long, default_value_t = 1.0)]
    k: f32,
    #[arg(long, default_value = "villain")]
    potential_type: Potential,
    #[arg(long, default_value_t = 8)]
    potential_values: usize,
}
fn main() {
    let args = Args::parse();

    println!("n\tvn");
    for n in 0..args.potential_values {
        println!("{}:\t{}", n, args.potential_type.eval(n as u32, args.k))
    }
}
