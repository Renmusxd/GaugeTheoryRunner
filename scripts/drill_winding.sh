#!/usr/bin/env bash

export RUST_LOG=info

SYSTEMSIZE=$1
POTENTIAL=$2
BASE_DIR=$3

WSAMPLES=128
WREPLICAS=64
STEPSPERSAMPLE=8

MAXWINDING=8

# Compute free energies up to winding number W
RUN_INDEX=$(( SYSTEMSIZE * SYSTEMSIZE * MAXWINDING + 1))

mkdir -p "${BASE_DIR}/${POTENTIAL}"

cargo build --release --bin gauge_mc_runner
EXE=target/release/gauge_mc_runner

# First, run_rec to get the transition in detail for a few different winding numbers
for w in {0..8}; do
python scripts/run_rec.py --output_directory "${BASE_DIR}/${POTENTIAL}/w${w}" \
--system_sizes "$SYSTEMSIZE" \
--samples=$WSAMPLES \
--replicas=$WREPLICAS \
--steps_per_sample=$STEPSPERSAMPLE \
--executable "$EXE" \
--potential_type=villain \
--iter_factor=4 \
--iteration=10 \
--background_winding=$w
done

mkdir -p "${BASE_DIR}/${POTENTIAL}/markov"

cargo build --release --bin markov
EXE=target/release/markov

ks="0.5 0.6 0.7 0.8 0.9 1.0 1.005 1.01 1.015 1.02 1.025 1.03 1.035 1.04 1.045 1.05 1.1 1.2 1.3 1.4 1.5"
for k in $ks; do
$EXE --systemsize="${SYSTEMSIZE}" --output="${BASE_DIR}/${POTENTIAL}/markov/markov_${POTENTIAL}_L${SYSTEMSIZE}_k${k}_n4096_s16.npz" --k="$k" --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
done