#!/bin/sh -l
#$ -N markov_rg
#$ -cwd
#$ -m ea
#$ -M sumnerh@bu.edu
#$ -l gpus=1
#$ -l gpu_c=6.0

READ_NPY_SCRIPT=$(realpath "scripts/read_npz.py")
PYTHONBIN="$HOME/.virtualenvs/gaugemc/bin/python"
PARAMS=$(realpath "scripts/parameters.npz")
NUMPARAMS=$(COUNT_INDEX=1 $PYTHONBIN "$READ_NPY_SCRIPT" "$PARAMS" 0)

MARKOV_SCRIPT=$(realpath "scripts/markov_rg.sh")
for TASK_ID in $(seq 1 $NUMPARAMS); do
    SGE_TASK_ID=$((TASK_ID + 1)) sh -l "$MARKOV_SCRIPT" $@
done