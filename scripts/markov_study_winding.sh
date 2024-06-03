#!/bin/sh -l
#$ -N markov_winding
#$ -cwd
#$ -m ea
#$ -M sumnerh@bu.edu
#$ -l gpus=1
#$ -l gpu_c=6.0

OUTDIR=$1
SYSTEM_SIZE=$2
NUM_SAMPLES=$3
POTENTIAL=$4
TASK_COPIES=$5
RUSTEXE=$(realpath "$6")
PYTHONEXE=$(realpath "$7")

TASK_INDEX="$((SGE_TASK_ID-1))"
echo "Running task index: $TASK_INDEX"

echo "Run config
OUTDIR=$OUTDIR
SYSTEM_SIZE=$SYSTEM_SIZE
NUM_SAMPLES=$NUM_SAMPLES
MAX_REPLICA_INDEX=$MAX_REPLICA_INDEX
POTENTIAL=$POTENTIAL
TASK_COPIES=$TASK_COPIES
RUSTEXE=$RUSTEXE
PYTHONEXE=$PYTHONEXE
"

if [ "$SKIP_MODULE" != "true" ]; then
  module load cuda/12.2
  module load python3/3.10.12
fi

mkdir -p "$OUTDIR"

OUTPUT_DIR=$(realpath "$OUTDIR")
echo "OUTPUT_DIR=$OUTPUT_DIR"

cd $OUTPUT_DIR || exit
export WD=$OUTPUT_DIR

# Now run main thing
echo "Running python code"

EXE="$HOME/.virtualenvs/gaugemc/bin/python"

export RAYON_NUM_THREADS=${NSLOTS:-1}
export RUST_LOG=info

echo "
$EXE \"$PYTHONEXE\" \
--system_size \"$SYSTEM_SIZE\" \
--num_samples \"$NUM_SAMPLES\" \
--executable \"$RUSTEXE\" \
--task_id \"$TASK_INDEX\" \
--tasks_per_k \"$TASK_COPIES\" \
--potential \"$POTENTIAL\"
"

if [ "$DRY_RUN" != "true" ]; then
  $EXE "$PYTHONEXE" \
  --system_size "$SYSTEM_SIZE" \
  --num_samples "$NUM_SAMPLES" \
  --executable "$RUSTEXE" \
  --tasks_per_k "$TASK_COPIES" \
  --task_id "$TASK_INDEX" \
  --potential "$POTENTIAL"
fi
