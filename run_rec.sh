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

OUTPUT_DIR=$1

mkdir $OUTPUT_DIR
cd $OUTPUT_DIR || exit
export WD=$OUTPUT_DIR

# Output a lot of GPU details
echo "Running GPU checking code"
nvidia-smi --list-gpus
nvidia-smi -L
nvidia-smi -q

if [ -d GaugeTheoryRunner ]; then
  echo "Updating Repo"
  cd GaugeTheoryRunner || exit
  git pull
else
  echo "Cloning Repo into directory"
  git clone --depth 1 git@github.com:Renmusxd/GaugeTheoryRunner.git
  cd GaugeTheoryRunner || exit
fi

#cargo build -j 1
#RUSTEXE="target/debug/gauge_mc_runner"
cargo build --release -j 1
RUSTEXE="target/release/gauge_mc_runner"

# Now run main thing
echo "Running python code"

EXE="$HOME/.virtualenvs/gaugemc/bin/python"

export RAYON_NUM_THREADS=${NSLOTS:-1}
export RUST_BACKTRACE=full
export RUST_LOG=info

POTENTIAL=$2

if [ -z "${SGE_TASK_ID}" ]; then
  TASK_INDEX="$((SGE_TASK_ID-1))"
  echo "Running task index: $TASK_INDEX"
  $EXE run_rec.py --potential_type=$POTENTIAL \
      --output_directory "../$POTENTIAL" \
      --system_sizes "${@:3}" \
      --disable_global_moves \
      --executable $RUSTEXE \
      --device_id 0 \
      --task_id "$TASK_INDEX"
else
  echo "Running without tasks"
  $EXE run_rec.py --potential_type=$POTENTIAL \
      --output_directory "../$POTENTIAL" \
      --system_sizes "${@:3}" \
      --disable_global_moves \
      --executable $RUSTEXE \
      --device_id 0
fi

cargo clean
