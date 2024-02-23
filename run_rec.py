import subprocess
import os
import datetime
import sys
import numpy

if __name__ == "__main__":
    device_id = os.getenv("CUDA_VISIBLE_DEVICES")
    if device_id:
        device_arr = ["--device-id", device_id]
    else:
        device_arr = []
    potential = sys.argv[1]
    basedir = os.path.abspath(sys.argv[2])
    Ls_str = sys.argv[3:]
    Ls = [int(L) for L in Ls_str]
    print(f"Running for L in {Ls}")
    klow = 0.5
    khigh = 1.5
    iter_factor = 4
    iterations = 5
    replicas = 64
    samples = 1024
    warmup = 128
    stepspersample = 32

    for l in Ls:
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

            with open(logfile, "w") as f:
                cmd = ["cargo", "run", "--release", "--",
                       "--klow", str(klow), "--khigh", str(khigh), "--potential-type", potential,
                       "-r", str(replicas), "-N", str(samples),
                       "-w", str(warmup), "-L", str(l),
                        "-s", str(stepspersample),
                       "--config-output", configfile, "--output-winding",
                       "-o", outputfile] + device_arr
                print("Running " + " ".join(cmd))
                subprocess.run(cmd, stdout=f, stderr=subprocess.STDOUT)

            arr = numpy.load(outputfile)
            ks = arr["ks"]
            x = arr["actions"]
            vx = numpy.array([xx.var() / (l ** 4) for xx in x.T])
            peak_k = ks[numpy.argmax(vx)]
            krange = khigh - klow

            klow = numpy.round(peak_k - (krange / (2 * iter_factor)), iternum + 2)
            khigh = numpy.round(peak_k + (krange / (2 * iter_factor)), iternum + 2)
