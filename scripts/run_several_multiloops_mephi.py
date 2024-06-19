import subprocess
import os
import sys

import numpy


def run_for_l_and_ks(potential, L, ks, zfill=3, num_samples=4096, nr=8, basedir="."):
    run_index = L * L * nr + 1

    for k in ks:
        kstr = str(int(k * (10 ** zfill))).zfill(zfill + 1)
        filename = f"{basedir}/markov_{potential}_L{L}_k{kstr}_n{num_samples}_s16.npz"
        cmd = f"""
        cargo run --release --bin markov -- 
        --systemsize={L}
        --output={filename} 
        --k={k}
        --num-samples={num_samples} 
        --replica-index-high={run_index} 
        --potential-type={potential}
        """.split("\n")
        cmd = " ".join(map(lambda x: x.strip(), cmd)).strip()
        print("Running " + cmd)
        subprocess.run(cmd.split(" "))


if __name__ == "__main__":
    basedir = sys.argv[1]
    L = int(sys.argv[2])
    os.makedirs(basedir, exist_ok=True)

    cosine_ks = sorted(set(numpy.concatenate([
        numpy.linspace(0.5, 1.5, 10),
        numpy.linspace(0.9, 1.2, 10),
        numpy.linspace(1.0, 1.1, 10),
        numpy.linspace(1.0, 1.15, 10),
    ])))
    run_for_l_and_ks("cosine", L, cosine_ks, basedir=basedir)

    villain_ks = sorted(set(numpy.concatenate([
        numpy.linspace(0.5, 1.5, 10),
        numpy.linspace(0.6, 0.9, 10),
        numpy.linspace(0.7, 0.85, 10),
        numpy.linspace(0.75, 0.8, 10),
    ])))
    run_for_l_and_ks("villain", L, villain_ks, basedir=basedir)

    binary_ks = sorted(set(numpy.concatenate([
        numpy.linspace(0.5, 1.5, 10),
        numpy.linspace(0.6, 0.9, 10),
        numpy.linspace(0.7, 0.85, 10),
        numpy.linspace(0.75, 0.8, 10),
    ])))
    run_for_l_and_ks("binary", L, binary_ks, basedir=basedir)
