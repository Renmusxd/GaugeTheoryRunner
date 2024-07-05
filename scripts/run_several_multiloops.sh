#!/usr/bin/env bash

export RUST_LOG=info

SYSTEMSIZE=$1
POTENTIAL=$2
BASE_DIR=$3

RUN_INDEX=$(( SYSTEMSIZE * SYSTEMSIZE * SYSTEMSIZE + 1))

mkdir -p "$BASE_DIR"
#cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k0500_n4096_s16.npz" --k=0.5 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
#cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k0600_n4096_s16.npz" --k=0.6 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
#cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k0700_n4096_s16.npz" --k=0.7 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
#cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k0750_n4096_s16.npz" --k=0.75 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
#cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k0760_n4096_s16.npz" --k=0.76 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
#cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k0770_n4096_s16.npz" --k=0.77 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
#cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k0780_n4096_s16.npz" --k=0.78 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
#cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k0790_n4096_s16.npz" --k=0.79 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
#cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k0800_n4096_s16.npz" --k=0.8 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
#cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k0850_n4096_s16.npz" --k=0.85 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
#cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k0900_n4096_s16.npz" --k=0.9 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
#cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1000_n4096_s16.npz" --k=1.0 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
#cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1200_n4096_s16.npz" --k=1.2 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
#cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1400_n4096_s16.npz" --k=1.4 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
#cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1600_n4096_s16.npz" --k=1.6 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"

cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1050_n4096_s16.npz" --k=1.05 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1100_n4096_s16.npz" --k=1.10 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1150_n4096_s16.npz" --k=1.15 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"

cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1010_n4096_s16.npz" --k=1.01 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1020_n4096_s16.npz" --k=1.02 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1030_n4096_s16.npz" --k=1.03 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1040_n4096_s16.npz" --k=1.04 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1060_n4096_s16.npz" --k=1.06 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1070_n4096_s16.npz" --k=1.07 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1080_n4096_s16.npz" --k=1.08 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1090_n4096_s16.npz" --k=1.09 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1110_n4096_s16.npz" --k=1.11 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1120_n4096_s16.npz" --k=1.12 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1130_n4096_s16.npz" --k=1.13 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1140_n4096_s16.npz" --k=1.14 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1160_n4096_s16.npz" --k=1.16 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1170_n4096_s16.npz" --k=1.17 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1180_n4096_s16.npz" --k=1.18 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1190_n4096_s16.npz" --k=1.19 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
