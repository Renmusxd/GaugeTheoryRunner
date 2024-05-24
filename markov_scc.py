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
    parser.add_argument('--executable', default=None)
    parser.add_argument('--potential_type', choices=["villain", "cosine", "binary"], default="villain")
    parser.add_argument('--system_size', metavar='L', type=int, default=8, help='System sizes to run across')
    parser.add_argument('--num_samples', metavar='N', type=int, default=1024, help='Number of samples to take')
    parser.add_argument('--steps_per_shard', metavar='S', type=int, default=None, help='Replica indices per shard')
    parser.add_argument('--max_replica_index', metavar='M', type=int, default=None, help='System sizes to run across')
    parser.add_argument('--load_k_array', metavar='k', type=str, default=None, help='Load k from npz')
    parser.add_argument('--report_shards', action="store_true", default=False,
                        help='Report number of shards')
    parser.add_argument('--task_id', metavar='H', type=int, default=0, help='Task number')
    args = parser.parse_args()

    if not args.report_shards:
        print("Running markov with:")
        for k, v in vars(args).items():
            print(f"{k}\t{v}")
        print("=====")

    if args.load_k_array:
        ks = numpy.load(args.load_k_array)["ks"]
    else:
        ks = list(numpy.arange(0.5, 0.7, 0.05)) + list(numpy.linspace(0.7, 0.9, 21)) + list(
            numpy.arange(0.95, 1.55, 0.05))

    if args.max_replica_index:
        max_replica_index = args.max_replica_index
    else:
        max_replica_index = args.system_size * args.system_size + 1

    if args.steps_per_shard:
        steps_per_shard = args.steps_per_shard
    else:
        steps_per_shard = max_replica_index

    steps = list(range(0, max_replica_index, steps_per_shard))
    if max_replica_index not in steps:
        steps = steps + [max_replica_index]

    shard_configs = [(k, low, high) for k in ks for (low, high) in zip(steps[:-1], steps[1:])]

    new_environ = os.environ.copy()
    num_threads = os.environ.get("NSLOTS", "-1")
    new_environ["RAYON_NUM_THREADS"] = num_threads
    if args.executable:
        executable = [args.executable]
    else:
        executable = ["cargo", "run",
                      "--release",
                      "--bin", "markov",
                      "-j", num_threads, "--"]

    if args.report_shards:
        print(len(shard_configs))
    else:
        k, low, high = shard_configs[args.task_id]

        filename_template = "markov_L{}_k{}_n{}_r{}-{}.npz"

        now = datetime.datetime.now()
        nowstr = now.strftime('%Y-%m-%d %H:%M:%S')

        filename = filename_template.format(args.system_size, str(int(k * 1000)).zfill(4), args.num_samples, low, high)
        filename = os.path.join(args.output_directory, filename)
        print(nowstr, filename)
        if os.path.exists(filename):
            print("\tAlready done!")
        else:
            subprocess.run(executable + [
                "--systemsize", str(args.system_size),
                "--num-samples", str(args.num_samples),
                "--k", str(k),
                "--potential-type", args.potential_type,
                "--output", filename,
                "--replica-index-low", str(low),
                "--replica-index-high", str(high)],
                           env=new_environ)
