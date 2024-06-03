import subprocess
import os
import datetime
import sys
import numpy
import argparse

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog='Chemical Potential Gauge Runner',
        description='Sweeps chemical potentials and stiffness')
    parser.add_argument('--output_directory', default=".")
    parser.add_argument('--potential_type', choices=["villain", "cosine", "binary"], default="villain")
    parser.add_argument('--system_sizes', metavar='L', type=int, nargs='+', default=[4, 6, 8],
                        help='System sizes to run across')
    parser.add_argument('--device_id', type=int, help="Cuda device id to run on", default=None)
    parser.add_argument("--klow", default=0.5, type=float, help="Value of klow")
    parser.add_argument("--khigh", default=1.5, type=float, help="Value of khigh")
    parser.add_argument("--kreplicas", default=16, type=int, help="Number of k replicas in array")
    parser.add_argument("--mulow", default=-0.1, type=float, help="Value of mulow")
    parser.add_argument("--muhigh", default=0.1, type=float, help="Value of muhigh")
    parser.add_argument("--mureplicas", default=16, type=int, help="Number of mu replicas in array")
    parser.add_argument("--warmup", default=128, type=int, help="Number of warmup steps before sampling")
    parser.add_argument("--samples", default=1024, type=int, help="Number of samples to take for each klow-khigh")
    parser.add_argument("--steps_per_sample", default=32, type=int, help="Number of steps between samples")
    parser.add_argument('--task_id', default=None, type=int, help="Task id if system sizes should be broken into tasks")
    parser.add_argument("--executable", help="Replace cargo-run with an executable")
    parser.add_argument('--log_to_file', action="store_true", help="Enable file logging")
    parser.add_argument("--disable_global_moves", action="store_true", help="Disable global moves to be included",
                        default=False)
    parser.add_argument("--log-debug-tempering", action="store_true", help="If enabled, log tempering information",
                        default=False)

    args = parser.parse_args()

    print("Running chemical with:")
    for k, v in vars(args).items():
        print(f"{k}\t{v}")
    print("=====")

    Ls = args.system_sizes
    potential = args.potential_type
    basedir = args.output_directory
    should_log_output = args.log_to_file
    device_id = args.device_id

    klow = args.klow
    khigh = args.khigh
    kreplicas = args.kreplicas

    mulow = args.mulow
    muhigh = args.muhigh
    mureplicas = args.mureplicas

    samples = args.samples
    warmup = args.warmup
    stepspersample = args.steps_per_sample

    if device_id is not None:
        device_id = int(device_id)
        device_arr = ["--device-id", str(device_id)]
    else:
        device_arr = []

    if args.disable_global_moves:
        global_move_arr = ["--global-updates-per-step", "0"]
    else:
        global_move_arr = []

    if args.log_debug_tempering:
        debug_tempering_arr = ["--output-tempering-debug"]
    else:
        debug_tempering_arr = []

    if args.executable:
        executable = [args.executable]
    else:
        executable = ["cargo", "run", "--release", "--"]

    if args.task_id is not None:
        Ls = [Ls[args.task_id]]

    for l in Ls:
        print(f"Running on L={l}")
        lbasedir = os.path.join(basedir, f"L={l}")
        os.makedirs(lbasedir, exist_ok=True)

        klowstr = str(klow).replace('.', '')
        khighstr = str(khigh).replace('.', '')
        filetemp = f"out-k{klowstr}-k{khighstr}"
        now = datetime.datetime.now()
        nowstr = now.strftime('%Y-%m-%d %H:%M:%S')
        print(f"{nowstr}\t{filetemp}")
        configfile = os.path.join(lbasedir, filetemp + ".yaml")
        outputfile = os.path.join(lbasedir, filetemp + ".npz")
        logfile = os.path.join(lbasedir, filetemp + ".log")

        cmd = (executable + ["--klow", str(klow), "--khigh", str(khigh), "--potential-type", potential,
                             "--replicas-ks", str(kreplicas),
                             "--chemicallow={}".format(str(mulow)), "--chemicalhigh={}".format(str(muhigh)),
                             "--chemical-potential-replicas", str(mureplicas),
                             "--num-samples", str(samples),
                             "--warmup-samples", str(warmup),
                             "--systemsize", str(l),
                             "--steps-per-sample", str(stepspersample),
                             "--config-output", configfile,
                             "--output-winding",
                             "--output", outputfile]
               + device_arr + global_move_arr + debug_tempering_arr)
        print("Running " + " ".join(cmd))
        if args.log_to_file:
            with open(logfile, "w") as f:
                subprocess.run(cmd, stdout=f, stderr=subprocess.STDOUT)
        else:
            subprocess.run(cmd)
