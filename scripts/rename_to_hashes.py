import os
import numpy
import sys
import shutil

if __name__ == "__main__":
    basedir = sys.argv[1]
    outdir = sys.argv[2]

    os.makedirs(outdir, exist_ok=True)

    for f in os.listdir(basedir):
        filename = os.path.join(basedir, f)
        if not filename.endswith(".npz"):
            continue
        arr = numpy.load(filename)

        configs = [
            "potential",
            "L",
            "k",
            "knum",
            "num_samples",
            "num_steps_per_sample",
            "warmup_steps",
            "plaquette_type",
            "run_plane_shift_updates",
        ]
        optional_configs = [
            "replica_index_low",
            "replica_index_high",
            "alpha"
        ]

        for opt_config in optional_configs:
            if opt_config in arr:
                configs = configs + [opt_config]

        key = tuple(arr[k][()] for k in configs)
        h = hash(key)
        shutil.copy(filename, os.path.join(outdir, f"{h}.npz"))
