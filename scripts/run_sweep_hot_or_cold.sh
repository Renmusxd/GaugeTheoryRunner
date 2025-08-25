#!/bin/sh -l
#$ -N run_rec
#$ -cwd
#$ -m ea
#$ -M sumnerh@bu.edu
#$ -l h_rt=12:00:00
#$ -l gpus=1
#$ -l gpu_c=6.0

module load cuda/12.2
module load python3/3.10.12

OUTDIR=${1:-"/tmp"}
POTENTIAL=${2:-"cosine"}
SYSTEM_SIZE=${3:-"4"}
KLOW=${4:-"1.0"}
KHIGH=${5:-"1.2"}
REPLICAS=${6:-"16"}
SAMPLES=${7:-"256"}
KHOT=${8:-"2.0"}
HOTSAMPLES=${9:-"256"}

SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT")
GITDIR=$(dirname $SCRIPT_DIR)

OUTPUT_DIR="$(realpath $OUTDIR)/$POTENTIAL/L=$SYSTEM_SIZE"

echo "OUTPUT_DIR=$OUTPUT_DIR"
mkdir -p $OUTPUT_DIR
cd $OUTPUT_DIR || exit
export WD=$OUTPUT_DIR

# Output a lot of GPU details
echo "Running GPU checking code"
nvidia-smi --list-gpus
nvidia-smi -L
nvidia-smi -q

OWNDIR="$(realpath $OUTDIR)/build/$JOB_ID.$SGE_TASK_ID"
echo "SCRIPT_DIR=$SCRIPT_DIR"
echo "GITDIR=$GITDIR"
echo "OWNDIR=$OWNDIR"

cd $GITDIR || exit
TO_RUN="cargo build --quiet --release -j ${NSLOTS:-1} --target-dir=\"$OWNDIR/target\""
echo $TO_RUN
eval $TO_RUN

cd $OUTPUT_DIR || exit
RUSTEXE="$OWNDIR/target/release/sweep"

export RAYON_NUM_THREADS=${NSLOTS:-1}
export RUST_BACKTRACE=full
export RUST_LOG=info

TORUN="
$RUSTEXE --systemsize=\"$SYSTEM_SIZE\" \
--potential-type=\"$POTENTIAL\" \
--klow=\"$KLOW\" \
--khigh=\"$KHIGH\" \
--replicas-ks=\"$REPLICAS\" \
--num-samples=\"$SAMPLES\" \
--hot-warmup-samples=\"$HOTSAMPLES\" \
--khot-start=\"$KHOT\" \
--plane-shift-updates-per-step=0 \
--tempering-updates-per-step=0 \
--output=\"$OUTPUT_DIR/out-k$KLOW-$KHIGH-data.npz\"
"

echo $TORUN
eval $TORUN