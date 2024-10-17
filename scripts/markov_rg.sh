#!/bin/sh -l
#$ -N markov_rg
#$ -cwd
#$ -m ea
#$ -M sumnerh@bu.edu
#$ -l gpus=1
#$ -l gpu_c=6.0

OUTDIR=$1
SYSTEM_SIZE=$2
NUM_SAMPLES=$3
MAX_REPLICA_INDEX=$((3*SYSTEM_SIZE*SYSTEM_SIZE+1))

RUSTEXE=$(realpath "target/release/markov")

READ_NPY_SCRIPT=$(realpath "scripts/read_npz.py")

TASK_INDEX="$((SGE_TASK_ID-1))"
echo "Running task index: $TASK_INDEX"

echo "Run config
OUTDIR=$OUTDIR
SYSTEM_SIZE=$SYSTEM_SIZE
NUM_SAMPLES=$NUM_SAMPLES
MAX_REPLICA_INDEX=$MAX_REPLICA_INDEX
"

if [ "$SKIP_MODULE" != "true" ]; then
  module load cuda/12.2
  module load python3/3.10.12
fi


PYTHONBIN="$HOME/.virtualenvs/gaugemc/bin/python"
PARAMS=$(realpath "scripts/parameters.npz")
KVAL=$(ONLY_INDEX=0 $PYTHONBIN "$READ_NPY_SCRIPT" "$PARAMS" $TASK_INDEX)
SECOND_REL=$(ONLY_INDEX=1 $PYTHONBIN "$READ_NPY_SCRIPT" "$PARAMS" $TASK_INDEX)

# Build for GPU if needed
cargo build --release --bin markov --quiet

mkdir -p "$OUTDIR"

OUTPUT_DIR=$(realpath "$OUTDIR")
echo "OUTPUT_DIR=$OUTPUT_DIR"

cd $OUTPUT_DIR || exit
export WD=$OUTPUT_DIR

# Now run main thing
echo "Running python code"

export RAYON_NUM_THREADS=${NSLOTS:-1}
export RUST_LOG=info


echo "
$RUSTEXE --systemsize=\"$SYSTEM_SIZE\" \
--k=\"$KVAL\" \
--potential-type=\"TwoParameter($SECOND_REL)\" \
--num-samples=\"$NUM_SAMPLES\" \
--output=\"$OUTPUT_DIR/L=${SYSTEM_SIZE}_k=${KVAL}_r=${SECOND_REL}_markov.npz\" \
--replica-index-high=\"${MAX_REPLICA_INDEX}\"
"

if [ "$DRY_RUN" != "true" ]; then
  $RUSTEXE --systemsize="$SYSTEM_SIZE"\
  --k="$KVAL" \
  --potential-type="TwoParameter($SECOND_REL)" \
  --num-samples="$NUM_SAMPLES" \
  --output="$OUTPUT_DIR/L=${SYSTEM_SIZE}_k=${KVAL}_r=${SECOND_REL}_markov.npz" \
  --replica-index-high="${MAX_REPLICA_INDEX}"
fi
