import subprocess
import os
import datetime
import sys
import numpy
import argparse

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog='Recursive Gauge Runner',
        description='Zooms in recursively on the phase transition region')
    parser.add_argument('--output_directory', default=".")
    parser.add_argument('--potential_type', choices=["villain", "cosine", "binary"], default="villain")
    parser.add_argument('--peak_choice', choices=["gradient", "variance"], default="gradient")
    parser.add_argument('--system_sizes', metavar='L', type=int, nargs='+', default=[4, 6, 8],
                        help='System sizes to run across')
    parser.add_argument('--device_id', type=int, help="Cuda device id to run on", default=None)
    parser.add_argument("--klow", default=0.5, type=float, help="Initial value of klow")
    parser.add_argument("--khigh", default=1.5, type=float, help="Initial value of khigh")
    parser.add_argument("--iter_factor", default=4, type=int, help="Zoom factor for ks each iteration")
    parser.add_argument("--iterations", default=5, type=int, help="Total number of iterations")
    parser.add_argument("--warmup", default=128, type=int, help="Number of warmup steps before sampling")
    parser.add_argument("--replicas", default=64, type=int, help="Number of replicas in array")
    parser.add_argument("--samples", default=1024, type=int, help="Number of samples to take for each klow-khigh")
    parser.add_argument("--steps_per_sample", default=32, type=int, help="Number of steps between samples")
    parser.add_argument("--tempering_steps", default=1, type=int, help="Number parallel tempering steps")
    parser.add_argument('--task_id', default=None, type=int, help="Task id if system sizes should be broken into tasks")
    parser.add_argument("--executable", help="Replace cargo-run with an executable")
    parser.add_argument('--log_to_file', action="store_true", help="Enable file logging")
    parser.add_argument("--disable_global_moves", action="store_true", help="Disable global moves to be included",
                        default=False)
    parser.add_argument("--disable_output_winding", action="store_true", help="Disables logging windings",
                        default=False)
    parser.add_argument('--background_windings', metavar='W', type=int, nargs='+', default=[0, 0, 0, 0, 0, 0],
                        help='Background planes to insert at start')
    parser.add_argument("--dont_round_ks", action="store_true", help="Disable rounding k values",
                        default=False)
    parser.add_argument("--round_starting_digits", type=int, help="Number of offset digits for rounding",
                        default=2)

    args = parser.parse_args()

    print("Running recursive with:")
    for k, v in vars(args).items():
        print(f"{k}\t{v}")
    print("=====")

    Ls = args.system_sizes
    potential = args.potential_type
    basedir = args.output_directory
    should_log_output = args.log_to_file
    device_id = args.device_id
    o_klow = args.klow
    o_khigh = args.khigh
    iter_factor = args.iter_factor
    iterations = args.iterations
    replicas = args.replicas
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

    if args.executable:
        executable = [args.executable]
    else:
        executable = ["cargo", "run", "--release", "--bin", "gauge_mc_runner", "--"]

    if args.task_id is not None:
        Ls = [Ls[args.task_id]]

    if not args.disable_output_winding:
        output_windings = ["--output-winding"]
    else:
        output_windings = []

    for l in Ls:
        khigh = o_khigh
        klow = o_klow
        print(f"Running on L={l}")
        lbasedir = os.path.join(basedir, f"L={l}")
        os.makedirs(lbasedir, exist_ok=True)
        for iternum in range(iterations):
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
                                 "--replicas-ks", str(replicas),
                                 "--num-samples", str(samples),
                                 "--warmup-samples", str(warmup),
                                 "--systemsize", str(l),
                                 "--steps-per-sample", str(stepspersample),
                                 "--config-output", configfile,
                                 "--plane-shift-updates-per-step", str(0),
                                 "--tempering-updates-per-step", str(args.tempering_steps),
                                 "--background-winding", " ".join(map(str, args.background_windings)),
                                 "--output", outputfile] + output_windings
                   + device_arr + global_move_arr)
            print("Running " + " ".join(cmd))
            if args.log_to_file:
                with open(logfile, "w") as f:
                    subprocess.run(cmd, stdout=f, stderr=subprocess.STDOUT)
            else:
                subprocess.run(cmd)

            arr = numpy.load(outputfile)
            ks = arr["ks"]
            x = arr["actions"]

            grad_x = numpy.gradient(x.mean(axis=0), ks)
            peak_k_grad = ks[numpy.argmax(numpy.abs(grad_x))]

            vx = numpy.array([xx.var() / (l ** 4) for xx in x.T])
            peak_k_var = ks[numpy.argmax(vx)]
            print(f"Peak gradient at k={peak_k_grad:.5f} \t Peak variance at k={peak_k_var:.5f}")

            if args.peak_choice == "gradient":
                print(f"Peak gradient at k={peak_k_grad:.5f}\t (Peak variance at k={peak_k_var:.5f})")
                peak_k = peak_k_grad
            elif args.peak_choice == "variance":
                print(f"Peak variance at k={peak_k_var:.5f}\t (Peak gradient at k={peak_k_grad:.5f} )")
                peak_k = peak_k_var
            else:
                raise ValueError("Invalid peak choice algorithm")

            krange = khigh - klow

            klow = numpy.round(peak_k - (krange / (2 * iter_factor)), args.round_starting_digits + iternum)
            khigh = numpy.round(peak_k + (krange / (2 * iter_factor)), args.round_starting_digits + iternum)
