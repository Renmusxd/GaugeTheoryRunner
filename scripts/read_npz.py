import numpy as np
import sys
import os

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python read_npz.py <filename>+ <index>")
    else:
        index = int(sys.argv[-1])

        arrays = []
        lengths = []
        for filename in sys.argv[1:-1]:
            arr = np.load(filename)
            for f in sorted(arr.files):
                arrays.append(arr[f].flatten())
                lengths.append(len(arrays[-1]))
        lengths = np.array(lengths)
        prod_cumulatives = np.concatenate([[1], np.cumprod(lengths)])[:-1]
        indices = (index // prod_cumulatives) % lengths

        value_strs = []
        for ii, array in zip(indices, arrays):
            value_strs.append(str(array[ii]))

        if os.environ.get("ONLY_INDEX", None) is not None:
            print(value_strs[int(os.environ.get("ONLY_INDEX"))])
        else:
            print(" ".join(value_strs))
