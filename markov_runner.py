import subprocess
import os
import datetime
import sys
import numpy

if __name__ == "__main__":
    num_samples = 1024
    system_sizes = [4, 6, 8, 10, 12, 14]
    ks = list(numpy.arange(0.5, 0.7, 0.05)) + list(numpy.linspace(0.7, 0.9, 21)) + list(numpy.arange(0.95, 1.55, 0.05))
    print(f"Running on Ls: {system_sizes}")
    print(f"Running on ks: {ks}")
    for system_size in system_sizes:
        filename_template = "markov_L{}_k{}_n{}.npz"

        now = datetime.datetime.now()
        nowstr = now.strftime('%Y-%m-%d %H:%M:%S')

        for k in ks:
            filename = filename_template.format(system_size, str(int(k * 100)).zfill(3), num_samples)
            print(f"{nowstr}\tL={system_size}\tk={k:.3f}\t{filename}")
            subprocess.run(["cargo", "run", "--release", "--bin", "markov", "--",
                            "--systemsize", str(system_size),
                            "-n", str(num_samples),
                            "-k", str(k)])
