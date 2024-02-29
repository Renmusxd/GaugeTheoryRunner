#!/bin/sh -l
#$ -N run_rec
#$ -cwd
#$ -m ea
#$ -M sumnerh@bu.edu
#$ -l h_rt=48:00:00
#$ -l h_vmem=4096M
#$ -l gpus=1
#$ -l gpu_c=6.0

module load cuda
module load python3

OUTPUT_DIR=$1

mkdir $OUTPUT_DIR
cd $OUTPUT_DIR || exit
export WD=$OUTPUT_DIR

# Output a lot of GPU details
echo "Running GPU checking code"
nvidia-smi --list-gpus
nvidia-smi -L
nvidia-smi -q

if [ -d GaugeTheoryRunner ]; then
  echo "Updating Repo"
  cd GaugeTheoryRunner || exit
  git pull
else
  echo "Cloning Repo into directory"
  git clone --depth 1 git@github.com:Renmusxd/GaugeTheoryRunner.git
  cd GaugeTheoryRunner || exit
fi

cargo build --release
RUSTEXE="target/release/gauge_mc_runner"

# Now run main thing
echo "Running python code"

EXE="$HOME/.virtualenvs/gaugemc/bin/python"

export RAYON_NUM_THREADS=${NSLOTS:-1}
export RUST_BACKTRACE=full
export RUST_LOG=info

POTENTIAL=$2

$EXE run_rec.py --potential_type=$POTENTIAL \
    --output_directory "../$POTENTIAL" \
    --system_sizes "${@:3}" \
    --disable_global_moves \
    --executable $RUSTEXE

cargo clean