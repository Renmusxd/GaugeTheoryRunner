#!/usr/bin/env bash

OUTPUTDIR=output

cargo build --release --bin sweep

export RUST_LOG=info

PYEXE=$(which python)

for w in 0 1 2 3 4; do
# First, do the normal sizes and all potentials
for L in 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32; do
for POT in "cosine" "villain" "binary"; do
  if ! [ -f "$OUTPUTDIR/w=$w/$POT/L=$L/done" ]; then
    mkdir -p "$OUTPUTDIR/w=$w/$POT"
    $PYEXE scripts/run_rec.py \
    --output_directory "$OUTPUTDIR/w=$w/$POT" \
    --system_sizes "$L" \
    --potential_type=$POT \
    --background_windings $w \
    --samples=1024 \
    --warmup=128 \
    --replicas=64 \
    --steps_per_sample=16 \
    --executable target/release/sweep \
    --iter_factor=8 \
    --iteration=7 \
    --disable_global_moves \
    --disable_output_winding
    touch "$OUTPUTDIR/w=$w/$POT/L=$L/done"
  else
    echo "Already done with w=$w/$POT/L=$L"
  fi
done
done
# Now for large sizes, only zoom in on the transition region.
POT="cosine"
for L in 48 64; do
  if ! [ -f "$OUTPUTDIR/w=$w/$POT/L=$L/done" ]; then
      mkdir -p "$OUTPUTDIR/w=$w/$POT"
      $PYEXE scripts/run_rec.py \
      --output_directory "$OUTPUTDIR/w=$w/$POT" \
      --system_sizes "$L" \
      --potential_type=$POT \
      --background_windings $w \
      --samples=1024 \
      --warmup=128 \
      --replicas=16 \
      --steps_per_sample=16 \
      --executable target/release/sweep \
      --iter_factor=4 \
      --iteration=3 \
      --klow=1.0 \
      --khigh=1.02 \
      --disable_global_moves \
      --disable_output_winding
      touch "$OUTPUTDIR/w=$w/$POT/L=$L/done"
    else
      echo "Already done with w=$w/$POT/L=$L"
    fi
done
done