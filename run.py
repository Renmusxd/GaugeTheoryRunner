import subprocess
import os
import datetime
import sys

if __name__ == "__main__":
    potential = sys.argv[1]
    basedir = f"outputs/{potential}/"
    Ls = [4, 6, 8, 10, 12, 16, 20, 24, 28]
    klows = [0.75, 0.76, 0.77, 0.775]
    khighs = [0.85, 0.79, 0.78, 0.777]
    for l in Ls:
        print(f"Running on L={l}")
        lbasedir = os.path.join(basedir, f"L={l}")
        os.makedirs(lbasedir, exist_ok=True)
        for (klow, khigh) in zip(klows, khighs):
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
                subprocess.run(["cargo", "run", "--release", "--",
                                "--klow", str(klow), "--khigh", str(khigh), "--potential-type", potential,
                                "-r", "64", "-N", "2000", "-w", "100", "-L", str(l),
                                "--config-output", configfile, "--output-winding",
                                "-o", outputfile], stdout=f, stderr=subprocess.STDOUT)
