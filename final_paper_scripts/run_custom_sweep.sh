#!/usr/bin/bash -l
#$ -N large_sweep
#$ -cwd
#$ -m ea
#$ -M sumnerh@bu.edu
#$ -l h_rt=48:00:00
#$ -l gpus=1
#$ -l gpu_c=6.0
#$ -l gpu_memory=8G

NUM_SAMPLES=1024

OUTPUTDIR=$1
L=$2
REPLICAS=$3
HOTWARMUP=$4

export RUST_LOG=info
if [ "$SKIP_MODULE" != "true" ]; then
  module load cuda/12.2
  module load python3/3.10.12
fi

POT=villain

mkdir -p "$OUTPUTDIR/w=0/$POT/L=$L"

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
--replicas-ks $REPLICAS \
--klow 1.28700 \
--khigh 1.28866 \
--potential-type $POT \
--output "$OUTPUTDIR/w=0/$POT/L=$L/out-k128700-128866.npz"