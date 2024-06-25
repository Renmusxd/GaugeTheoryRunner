import subprocess
import os
import sys

import numpy


def rename_files(zfill=7, basedir="."):
    potentials = ["villain", "cosine", "binary", "power"]
    for file in os.listdir(basedir):
        filename = os.path.join(basedir, file)
        if filename.endswith(".npz"):
            arr = numpy.load(filename)
            potential = potentials[arr["potential"][()]]
            L = int(arr["L"][()])
            k = arr["k"][()]
            kstr = str(int(k * (10 ** zfill))).zfill(zfill + 1)
            num_samples = arr["num_samples"][()]
            new_filename = os.path.join(f"{basedir}", f"markov_{potential}_L{L}_k{kstr}_n{num_samples}_s16.npz")
            if filename != new_filename:
                print(f"Renaming {filename} to {new_filename}")
                os.rename(filename, new_filename)


def run_for_l_and_ks(potential, L, ks, zfill=5, num_samples=4096, nr=8, basedir=".", executable=None):
    if executable is None:
        executable = "cargo run --release --bin markov --"
    run_index = L * L * nr + 1

    for k in ks:
        kstr = str(int(k * (10 ** zfill))).zfill(zfill + 1)
        filename = f"{basedir}/markov_{potential}_L{L}_k{kstr}_n{num_samples}_s16.npz"
        if os.path.exists(filename):
            continue
        cmd = f"""
        {executable} 
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
    if len(sys.argv) > 3:
        executable = sys.argv[3]
    else:
        executable = None
    os.makedirs(basedir, exist_ok=True)

    # First check for existing and rename if needed
    rename_files(basedir=basedir)

    cosine_ks = sorted(set(numpy.concatenate([
        numpy.linspace(0.5, 1.5, 10),
        numpy.linspace(0.9, 1.2, 10),
        numpy.linspace(1.0, 1.1, 10),
        numpy.linspace(1.010, 1.015, 10),
        numpy.linspace(1.0, 1.15, 10),
    ])))
    villain_ks = sorted(set(numpy.concatenate([
        numpy.linspace(0.5, 1.5, 10),
        numpy.linspace(0.6, 0.9, 10),
        numpy.linspace(0.7, 0.85, 10),
        numpy.linspace(0.75, 0.8, 10),
        numpy.linspace(0.77, 0.78, 10),
    ])))
    binary_ks = sorted(set(numpy.concatenate([
        numpy.linspace(0.5, 1.5, 10),
        numpy.linspace(0.6, 0.9, 10),
        numpy.linspace(0.7, 0.85, 10),
        numpy.linspace(0.75, 0.8, 10),
        numpy.linspace(0.76, 0.77, 10),
    ])))

    run_for_l_and_ks("cosine", L, cosine_ks, basedir=basedir, executable=executable)

    run_for_l_and_ks("villain", L, villain_ks, basedir=basedir, executable=executable)

    run_for_l_and_ks("binary", L, binary_ks, basedir=basedir, executable=executable)
