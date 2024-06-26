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

OUTDIR=$1
OUTPUT_DIR=$(realpath $OUTDIR)

echo "OUTPUT_DIR=$OUTPUT_DIR"

mkdir -p $OUTPUT_DIR
cd $OUTPUT_DIR || exit
export WD=$OUTPUT_DIR

# Output a lot of GPU details
echo "Running GPU checking code"
nvidia-smi --list-gpus
nvidia-smi -L
nvidia-smi -q

OWNDIR="$OUTPUT_DIR/build/$JOB_ID.$SGE_TASK_ID"
GITDIR="$OWNDIR/GaugeTheoryRunner"

echo "OWNDIR=$OWNDIR"
echo "GITDIR=$GITDIR"

mkdir -p $OWNDIR

cd $OWNDIR || exit
if [ -d GaugeTheoryRunner ]; then
  echo "Updating Repo"
  cd "$GITDIR" || exit
  git pull
  git checkout nodata
else
  echo "Cloning Repo into directory"
  git clone -b nodata --single-branch --depth 1 git@github.com:Renmusxd/GaugeTheoryRunner.git
  cd "$GITDIR" || exit
fi

cargo build --quiet --release -j ${NSLOTS:-1}
cd $OUTPUT_DIR || exit
RUSTEXE="$GITDIR/target/release/gauge_mc_runner"
PYTHONEXE="$GITDIR/scripts/run_rec.py"

# Now run main thing
echo "Running python code"

EXE="$HOME/.virtualenvs/gaugemc/bin/python"

export RAYON_NUM_THREADS=${NSLOTS:-1}
export RUST_BACKTRACE=full
export RUST_LOG=info

POTENTIAL=$2

TASK_INDEX="$((SGE_TASK_ID-1))"
echo "Running task index: $TASK_INDEX"

echo "
$EXE $PYTHONEXE --potential_type=$POTENTIAL \
--output_directory \"$POTENTIAL\" \
--system_sizes \"${@:3}\" \
--disable_global_moves \
--executable $RUSTEXE \
--device_id 0 \
--task_id \"$TASK_INDEX\"
"

$EXE $PYTHONEXE --potential_type=$POTENTIAL \
--output_directory "$POTENTIAL" \
--system_sizes "${@:3}" \
--disable_global_moves \
--executable $RUSTEXE \
--device_id 0 \
--task_id "$TASK_INDEX"

cd $GITDIR || exit
cargo clean
