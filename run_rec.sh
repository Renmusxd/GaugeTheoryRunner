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

echo "Cloning Repo into directory"
git clone --depth 1 git@github.com:Renmusxd/GaugeTheoryRunner.git
cd GaugeTheoryRunner || exit
cargo build --release

# Now run main thing
echo "Running python code"

EXE="$HOME/.virtualenvs/gaugemc/bin/python"

export RAYON_NUM_THREADS=${NSLOTS:-1}
export RUST_BACKTRACE=full
export RUST_LOG=info

POTENTIAL=$2
echo "Running $EXE run_rec.py $POTENTIAL \"../$POTENTIAL\" \"${@:3}\""
$EXE run_rec.py $POTENTIAL "../$POTENTIAL" "${@:3}"

cargo clean