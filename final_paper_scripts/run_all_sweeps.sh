#!/usr/bin/env bash

OUTPUTDIR=output

cargo build --release --bin sweep

export RUST_LOG=info

PYEXE=$(which python)

for L in 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32; do
for POT in "cosine" "villain" "binary"; do
  mkdir -p "$OUTPUTDIR/$POT"
  $PYEXE scripts/run_rec.py \
  --output_directory "$OUTPUTDIR/$POT" \
  --system_sizes "$L" \
  --samples=4096 \
  --replicas=64 \
  --steps_per_sample=16 \
  --executable target/release/sweep \
  --potential_type=cosine \
  --iter_factor=10 \
  --iteration=7
done
done