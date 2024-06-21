#!/bin/sh -l
# $ -N run_rec
# $ -cwd
# $ -m ea
# $ -M sumnerh@bu.edu
# $ -l h_rt=24:00:00
# $ -l gpus=1
# $ -l gpu_c=6.0

POTENTIAL=$1
K=$2
SYSTEMSIZE=$3
OUTPUT=$4

RUSTEXE=target/release/markov
REPLICAS_PER_TASK=128
TASK_INDEX="$((SGE_TASK_ID-1))"

if [ "$SKIP_MODULE" != "true" ]; then
  module load cuda/12.2
  module load python3/3.10.12
fi

EXE="$HOME/.virtualenvs/gaugemc/bin/python"
PYTHONEXE="scripts/large_winding_qsub.py"

export RAYON_NUM_THREADS=${NSLOTS:-1}
export RUST_BACKTRACE=full
export RUST_LOG=info


$EXE "$PYTHONEXE" \
--executable "$RUSTEXE" \
--system_size "$SYSTEMSIZE" \
--num_samples 10 \
--replicas_per_task "$REPLICAS_PER_TASK" \
--max_replica_number $(( SYSTEMSIZE * SYSTEMSIZE * 8 + 1 )) \
--task_id "$TASK_INDEX" \
--potential "$POTENTIAL" \
--k "$K" \
--output_directory "$OUTPUT"
