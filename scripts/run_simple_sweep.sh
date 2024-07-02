#!/bin/bash -l
#$ -N run_sweep
#$ -cwd
#$ -m ea
#$ -M sumnerh@bu.edu
#$ -l h_rt=48:00:00
#$ -l gpus=1
#$ -l gpu_c=6.0
#$ -l gpu_memory=16G

module load cuda/12.2

OUTPUT=$1

target/release/gauge_mc_runner --klow 1.010 --khigh 1.015 --replicas-ks 16 --num-samples 1024 --warmup-samples 128 --systemsize 64 --steps-per-sample 16 --output $OUTPUT --global-updates-per-step 0