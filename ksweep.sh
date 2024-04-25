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
OUTPUT_DIR=$(realpath "$OUTDIR")
L=$2

OWNDIR="$OUTPUT_DIR/L=$L/$JOB_ID.$SGE_TASK_ID"
mkdir -p "$OWNDIR"

cd $OWNDIR || exit
if [ -d GaugeTheoryRunner ]; then
  echo "Updating Repo"
  cd "$OWNDIR/GaugeTheoryRunner" || exit
  git pull
  git checkout nodata
else
  echo "Cloning Repo into directory"
  git clone -b nodata --single-branch --depth 1 git@github.com:Renmusxd/GaugeTheoryRunner.git
  cd "$OWNDIR/GaugeTheoryRunner" || exit
fi
cargo build --quiet --release -j "${NSLOTS:-1}"
cd "$OWNDIR" || exit

RUSTEXE="$OWNDIR/GaugeTheoryRunner/target/release/gauge_mc_runner"

echo "
RUST_LOG=info $RUSTEXE \
 -r 1024 -L \"$L\" -N 1024 -s 32 -w 1024 \
  --klow 0.25 --khigh 0.85 --output \"$OWNDIR/sweep.npz\" \
  --output-winding --log-every 1 \
  --config-output \"$OWNDIR/config.yaml\"
"

RUST_LOG=info $RUSTEXE \
 -r 1024 -L "$L" -N 1024 -s 32 -w 1024 \
  --klow 0.25 --khigh 0.85 --output "$OWNDIR/sweep.npz" \
  --output-winding --log-every 1 \
  --config-output "$OWNDIR/config.yaml"

cd "GaugeTheoryRunner" || exit
cargo clean
