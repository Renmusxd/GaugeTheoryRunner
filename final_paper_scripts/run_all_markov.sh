#!/usr/bin/env bash

export RUST_LOG=info

OUTPUTDIR=output

Ls=( "4" "6" "8" "10" "12" "14" "16" )
NUM_SAMPLES=4096

# Express the K values in terms of integers so that our filenames aren't wonky.
COMMON_KS=$( python -c "import numpy; ks = numpy.linspace(0.5,1.5,11); mapf = lambda x: str(int(x*1e7)).zfill(8); kstrs = list(map(mapf, ks)); print(' '.join(kstrs))" )

COSINE_BROAD_KS=$( python -c "import numpy; ks = numpy.linspace(0.9,1.1,11); mapf = lambda x: str(int(x*1e7)).zfill(8); kstrs = list(map(mapf, ks)); print(' '.join(kstrs))" )
VILLAIN_BROAD_KS=$( python -c "import numpy; ks = numpy.linspace(1.2,1.4,11); mapf = lambda x: str(int(x*1e7)).zfill(8); kstrs = list(map(mapf, ks)); print(' '.join(kstrs))" )
BINARY_BROAD_KS=$( python -c "import numpy; ks = numpy.linspace(1.2,1.4,11); mapf = lambda x: str(int(x*1e7)).zfill(8); kstrs = list(map(mapf, ks)); print(' '.join(kstrs))" )

COSINE_FINE_KS=$( python -c "import numpy; ks = numpy.linspace(1.0,1.02,11); mapf = lambda x: str(int(x*1e7)).zfill(8); kstrs = list(map(mapf, ks)); print(' '.join(kstrs))" )
VILLAIN_FINE_KS=$( python -c "import numpy; ks = numpy.linspace(1.279,1.299,11); mapf = lambda x: str(int(x*1e7)).zfill(8); kstrs = list(map(mapf, ks)); print(' '.join(kstrs))" )
BINARY_FINE_KS=$( python -c "import numpy; ks = numpy.linspace(1.297,1.317,11); mapf = lambda x: str(int(x*1e7)).zfill(8); kstrs = list(map(mapf, ks)); print(' '.join(kstrs))" )

cargo build --release --bin markov

for L in ${Ls[*]}; do
  NRS=$(( L > 8 ? 8 : L ))
  RUN_INDEX=$(( L * L * NRS + 1))
  for POTENTIAL in "cosine" "villain" "binary"; do
    mkdir -p "$OUTPUTDIR/markov/${POTENTIAL}/L=${L}"
    for KSTR in $COMMON_KS; do
      FILENAME="$OUTPUTDIR/markov/${POTENTIAL}/L=${L}/k=${KSTR}.npz"
      if ! [ -f $FILENAME ]; then
        KFLOAT=$( python -c "print(int('${KSTR}')/1e7)" )
        target/release/markov --systemsize="${L}" \
        --output=$FILENAME \
        --k="$KFLOAT" \
        --num-samples="$NUM_SAMPLES" \
        --replica-index-high="$RUN_INDEX" \
        --potential-type="$POTENTIAL"
      else
        echo "Already done with $FILENAME"
      fi
    done
  done

  POTENTIAL="cosine"
  for KSTR in $COSINE_BROAD_KS; do
    FILENAME="$OUTPUTDIR/markov/${POTENTIAL}/L=${L}/k=${KSTR}.npz"
    if ! [ -f $FILENAME ]; then
      KFLOAT=$( python -c "print(int('${KSTR}')/1e7)" )
      target/release/markov --systemsize="${L}" \
      --output=$FILENAME \
      --k="$KFLOAT" \
      --num-samples="$NUM_SAMPLES" \
      --replica-index-high="$RUN_INDEX" \
      --potential-type="$POTENTIAL"
    else
      echo "Already done with $FILENAME"
    fi
  done
  POTENTIAL="villain"
  for KSTR in $VILLAIN_BROAD_KS; do
    FILENAME="$OUTPUTDIR/markov/${POTENTIAL}/L=${L}/k=${KSTR}.npz"
    if ! [ -f $FILENAME ]; then
      KFLOAT=$( python -c "print(int('${KSTR}')/1e7)" )
      target/release/markov --systemsize="${L}" \
      --output=$FILENAME \
      --k="$KFLOAT" \
      --num-samples="$NUM_SAMPLES" \
      --replica-index-high="$RUN_INDEX" \
      --potential-type="$POTENTIAL"
    else
      echo "Already done with $FILENAME"
    fi
  done
  POTENTIAL="binary"
  for KSTR in $BINARY_BROAD_KS; do
    FILENAME="$OUTPUTDIR/markov/${POTENTIAL}/L=${L}/k=${KSTR}.npz"
    if ! [ -f $FILENAME ]; then
      KFLOAT=$( python -c "print(int('${KSTR}')/1e7)" )
      target/release/markov --systemsize="${L}" \
      --output=$FILENAME \
      --k="$KFLOAT" \
      --num-samples="$NUM_SAMPLES" \
      --replica-index-high="$RUN_INDEX" \
      --potential-type="$POTENTIAL"
    else
      echo "Already done with $FILENAME"
    fi
  done

  POTENTIAL="cosine"
  for KSTR in $COSINE_FINE_KS; do
    FILENAME="$OUTPUTDIR/markov/${POTENTIAL}/L=${L}/k=${KSTR}.npz"
    if ! [ -f $FILENAME ]; then
      KFLOAT=$( python -c "print(int('${KSTR}')/1e7)" )
      target/release/markov --systemsize="${L}" \
      --output=$FILENAME \
      --k="$KFLOAT" \
      --num-samples="$NUM_SAMPLES" \
      --replica-index-high="$RUN_INDEX" \
      --potential-type="$POTENTIAL"
    else
      echo "Already done with $FILENAME"
    fi
  done
  POTENTIAL="villain"
  for KSTR in $VILLAIN_FINE_KS; do
    FILENAME="$OUTPUTDIR/markov/${POTENTIAL}/L=${L}/k=${KSTR}.npz"
    if ! [ -f $FILENAME ]; then
      KFLOAT=$( python -c "print(int('${KSTR}')/1e7)" )
      target/release/markov --systemsize="${L}" \
      --output=$FILENAME \
      --k="$KFLOAT" \
      --num-samples="$NUM_SAMPLES" \
      --replica-index-high="$RUN_INDEX" \
      --potential-type="$POTENTIAL"
    else
      echo "Already done with $FILENAME"
    fi
  done
  POTENTIAL="binary"
  for KSTR in $BINARY_FINE_KS; do
    FILENAME="$OUTPUTDIR/markov/${POTENTIAL}/L=${L}/k=${KSTR}.npz"
    if ! [ -f $FILENAME ]; then
      KFLOAT=$( python -c "print(int('${KSTR}')/1e7)" )
      target/release/markov --systemsize="${L}" \
      --output=$FILENAME \
      --k="$KFLOAT" \
      --num-samples="$NUM_SAMPLES" \
      --replica-index-high="$RUN_INDEX" \
      --potential-type="$POTENTIAL"
    else
      echo "Already done with $FILENAME"
    fi
  done
done