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

# Output a lot of GPU details
echo "Running GPU checking code"
nvidia-smi --list-gpus
nvidia-smi -L
nvidia-smi -q

OUTDIR=${1:-"/tmp"}
POTENTIAL=${2:-"cosine"}
SYSTEM_SIZE=${3:-"4"}
KLOW=${4:-"1.0"}
KHIGH=${5:-"1.2"}
REPLICAS=${6:-"16"}
SAMPLES=${7:-"256"}
KHOT=${8:-"2.0"}
HOTSAMPLES=${9:-"256"}
GITDIR=${10:-$( pwd )}

mkdir -p $OUTDIR
OUTPUT_DIR="$(realpath $OUTDIR)/$POTENTIAL/L=$SYSTEM_SIZE"
BUILDDIR="$(realpath $OUTDIR)/build/$JOB_ID.$SGE_TASK_ID"

echo "OUTPUT_DIR=$OUTPUT_DIR"
echo "GITDIR=$GITDIR"
echo "BUILDDIR=$BUILDDIR"

mkdir -p $OUTPUT_DIR
mkdir -p $BUILDDIR
cd $GITDIR || exit
TO_RUN="cargo build --quiet --release -j ${NSLOTS:-1} --target-dir=\"$BUILDDIR/target\""
echo $TO_RUN
eval $TO_RUN
RUSTEXE="$BUILDDIR/target/release/sweep"


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