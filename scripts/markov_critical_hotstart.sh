#!/bin/sh -l
#$ -N markov_critical_hotstart
#$ -cwd
#$ -m ea
#$ -M sumnerh@bu.edu
#$ -l gpus=1
#$ -l gpu_c=6.0
#$ -l h_rt=72:00:00

OUTDIR=$1
POTENTIAL=$2
SYSTEM_SIZE=$3
NUM_SAMPLES=$4
KVAL=$5
WARMUP_SAMPLES=${6:-128}

SGE_TASK_ID=${SGE_TASK_ID:-1};
TASK_INDEX="$((SGE_TASK_ID-1))"
echo "Running task index: $TASK_INDEX"

REPLICAS_PER_TASK=SYSTEM_SIZE

MIN_REPLICA_INDEX="$((TASK_INDEX * REPLICAS_PER_TASK))"
MAX_REPLICA_INDEX="$((TASK_INDEX * REPLICAS_PER_TASK + REPLICAS_PER_TASK))"


RUSTEXE=$(realpath "target/release/markov")


echo "Run config
OUTDIR=$OUTDIR
SYSTEM_SIZE=$SYSTEM_SIZE
NUM_SAMPLES=$NUM_SAMPLES
TASK_INDEX=$TASK_INDEX
MIN_REPLICA_INDEX=$MIN_REPLICA_INDEX
MAX_REPLICA_INDEX=$MAX_REPLICA_INDEX
WARMUP_SAMPLES=$WARMUP_SAMPLES
"

if [ "$SKIP_MODULE" != "true" ]; then
  module load cuda/12.2
  module load python3/3.10.12
fi

PYTHONBIN="$HOME/.virtualenvs/gaugemc/bin/python"

# Build for GPU if needed
cargo build --release --bin markov --quiet

mkdir -p "$OUTDIR"

OUTPUT_DIR=$(realpath "$OUTDIR")
echo "OUTPUT_DIR=$OUTPUT_DIR"

cd $OUTPUT_DIR || exit
export WD=$OUTPUT_DIR

# Now run main thing
export RAYON_NUM_THREADS=${NSLOTS:-1}
export RUST_LOG=info

CMD="
$RUSTEXE --systemsize=\"$SYSTEM_SIZE\" \
--k=\"$KVAL\" \
--potential-type=\"$POTENTIAL\" \
--num-samples=\"$NUM_SAMPLES\" \
--output=\"$OUTPUT_DIR/markov_${POTENTIAL}_L=${SYSTEM_SIZE}_k=${KVAL}_replicas_${MIN_REPLICA_INDEX}-${MAX_REPLICA_INDEX}.npz\" \
--replica-index-low=\"${MIN_REPLICA_INDEX}\" \
--replica-index-high=\"${MAX_REPLICA_INDEX}\" \
--hot-warmup-samples=\"${WARMUP_SAMPLES}\"
"

echo "${CMD}"

if [ "$DRY_RUN" != "true" ]; then
  eval "${CMD}"
fi
