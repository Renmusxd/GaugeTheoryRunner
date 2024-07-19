#!/usr/bin/bash -l
#$ -N superlarge_sweep
#$ -cwd
#$ -m ea
#$ -M sumnerh@bu.edu
#$ -l h_rt=48:00:00
#$ -l gpus=1
#$ -l gpu_c=6.0
#$ -l gpu_memory=8G

L=128
NUM_SAMPLES=1024

OUTPUTDIR=$1
HOTWARMUP=$2

export RUST_LOG=info
if [ "$SKIP_MODULE" != "true" ]; then
  module load cuda/12.2
  module load python3/3.10.12
fi
if [ -z "$PYTHONEXE" ]; then
  PYTHONEXE="$HOME/.virtualenvs/gaugemc/bin/python"
fi

mkdir -p "$OUTPUTDIR/w=0/L=$L"

cargo build --release --bin sweep -j 1
target/release/sweep \
--num-samples $NUM_SAMPLES \
--hot-warmup-samples $HOTWARMUP \
--warmup-samples 128 \
--systemsize $L \
--steps-per-sample 16 \
--global-updates-per-step 0 \
--plane-shift-updates-per-step 0 \
--tempering-updates-per-step 0 \
--replicas-ks 1 \
--klow 1.01127432 \
--khigh 1.01127432 \
--output "$OUTPUTDIR/w=0/L=$L/out-k101127432.npz"