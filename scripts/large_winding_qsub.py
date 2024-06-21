import argparse
import subprocess
import os

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        prog='Run large winding numbers',
        description='Sweeps chemical potentials and stiffness')
    parser.add_argument('--output_directory', default=".")
    parser.add_argument('--system_size', type=int, default=32)
    parser.add_argument('--potential', type=str, default='cosine')
    parser.add_argument('--k', type=float, default=1.0)
    parser.add_argument('--replicas_per_task', type=int, default=256)
    parser.add_argument('--max_replica_number', type=int, default=None)
    parser.add_argument('--min_replica_number', type=int, default=0)
    parser.add_argument('--num_samples', type=int, default=4096)
    parser.add_argument('--steps_per_sample', type=int, default=16)
    parser.add_argument('--executable', type=str, default=None)
    parser.add_argument('--task_id', type=int, default=0)
    parser.add_argument('--dry_run', action="store_true")
    parser.add_argument('--check_output', action="store_true")
    args = parser.parse_args()

    replica_base = args.task_id * args.replicas_per_task + args.min_replica_number

    if args.max_replica_number is None:
        replica_max = replica_base + args.replicas_per_task
    else:
        replica_max = min(replica_base + args.replicas_per_task, args.max_replica_number + 1)

    if args.executable:
        executable = [args.executable]
    else:
        num_threads = os.environ.get("NSLOTS", "-1")
        executable = ["cargo", "run",
                      "--release",
                      "--bin", "markov",
                      "-j", num_threads, "--"]

    kstr = str(int(args.k * 1e6)).zfill(7)

    filename = f"markov_{args.potential}_L{args.system_size}_k{kstr}_n{args.num_samples}_s{args.steps_per_sample}_r{replica_base}-{replica_max}.npz"
    filename = os.path.join(args.output_directory, filename)

    command = executable + [
        "--replica-index-low", str(replica_base),
        "--replica-index-high", str(replica_max),
        "--systemsize", str(args.system_size),
        "--num-samples", str(args.num_samples),
        "--k", str(args.k),
        "--potential-type", args.potential,
        "--output", filename,
        "--num-steps-per-sample", str(args.steps_per_sample)]
    print(" ".join(command))
    if not args.dry_run:
        os.makedirs(args.output_directory, exist_ok=True)
        subprocess.run(command)
        if args.check_output:
            import numpy

            arr = numpy.load(filename)
            print(arr["all_transition_probs"].shape)
