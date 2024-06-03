#!/usr/bin/env bash

export RUST_LOG=info

SYSTEMSIZE=$1
POTENTIAL=$2
BASE_DIR=$3

RUN_INDEX=$(( SYSTEMSIZE * SYSTEMSIZE * SYSTEMSIZE + 1))

mkdir -p "$BASE_DIR"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k0500_n4096_s16.npz" --k=0.5 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k0600_n4096_s16.npz" --k=0.6 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k0700_n4096_s16.npz" --k=0.7 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k0750_n4096_s16.npz" --k=0.75 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k0760_n4096_s16.npz" --k=0.76 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k0770_n4096_s16.npz" --k=0.77 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k0780_n4096_s16.npz" --k=0.78 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k0790_n4096_s16.npz" --k=0.79 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k0800_n4096_s16.npz" --k=0.8 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k0850_n4096_s16.npz" --k=0.85 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k0900_n4096_s16.npz" --k=0.9 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1000_n4096_s16.npz" --k=1.0 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1200_n4096_s16.npz" --k=1.2 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1400_n4096_s16.npz" --k=1.4 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"
cargo run --release --bin markov -- --systemsize="${SYSTEMSIZE}" --output="$BASE_DIR/markov_${POTENTIAL}_L${SYSTEMSIZE}_k1600_n4096_s16.npz" --k=1.6 --num-samples=4096 --replica-index-high="$RUN_INDEX" --potential-type="$POTENTIAL"