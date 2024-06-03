import subprocess
import os
import datetime
import sys
import numpy
import argparse
import pickle

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog='Markov Winding Study',
        description='Zooms in recursively on the phase transition region')
    parser.add_argument('--output_directory', default=".")
    parser.add_argument('--executable', default=None)
    parser.add_argument('--potential_type', type=str, default="villain")
    parser.add_argument('--system_size', metavar='L', type=int, default=8, help='System sizes to run across')
    parser.add_argument('--steps_per_sample', metavar='s', type=int, default=16,
                        help='Simulation steps between samples')
    parser.add_argument('--num_samples', metavar='N', type=int, default=1024, help='Number of samples to take')
    parser.add_argument('--load_k_array', metavar='k', type=str, default=None, help='Load k from npz')
    parser.add_argument('--eval_k_array', type=str, default=None, help='Construct k array')
    parser.add_argument('--tasks_per_k', metavar='K', type=int, default=1, help='Number of tasks per k')
    parser.add_argument('--task_id', metavar='T', type=int, default=0, help='Task number')
    parser.add_argument('--zfill', type=int, default=4, help='Zfill paramter for file names')
    args = parser.parse_args()

    print("Running markov with:")
    for k, v in vars(args).items():
        print(f"{k}\t{v}")
    print("=====")

    if args.load_k_array:
        with open(args.load_k_array, "rb") as f:
            ks = pickle.load(f)
    elif args.eval_k_array:
        ks = eval(args.eval_k_array)
    else:
        ks = list(numpy.arange(0.5, 0.7, 0.05)) + list(numpy.linspace(0.7, 0.9, 21)) + list(
            numpy.arange(0.95, 1.55, 0.05))

    if args.executable:
        executable = [args.executable]
    else:
        num_threads = os.environ.get("NSLOTS", "-1")
        executable = ["cargo", "run",
                      "--release",
                      "--bin", "markov",
                      "-j", num_threads, "--"]

    ktask = args.task_id // args.tasks_per_k
    subtask = args.task_id % args.tasks_per_k

    total_tasks = len(ks) * args.tasks_per_k
    print("Task {}/{}".format(args.task_id, total_tasks))

    k = ks[ktask]
    filename_template = "markov_{}_L{}_k{}_n{}_s{}_t{}.npz"

    now = datetime.datetime.now()
    nowstr = now.strftime('%Y-%m-%d %H:%M:%S')

    filename = filename_template.format(
        args.potential_type, args.system_size,
        str(int(k * 10 ** (args.zfill - 1))).zfill(args.zfill),
        args.num_samples,
        args.steps_per_sample,
        subtask)
    filename = os.path.join(args.output_directory, filename)
    print(nowstr, filename)
    if os.path.exists(filename):
        print("\tAlready done!")
    else:
        command = executable + [
            "--systemsize", str(args.system_size),
            "--num-samples", str(args.num_samples),
            "--k", str(k),
            "--potential-type", args.potential_type,
            "--output", filename,
            "--num-steps-per-sample", str(args.steps_per_sample)]
        print(command)
        subprocess.run(command)
