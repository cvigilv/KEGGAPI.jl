"""Python runner: times Bio.KEGG.REST calls, one CSV row per replicate.

Usage: python3 runners/bench_python.py <nreps> <sleep_seconds>
"""
import sys
import time

import Bio.KEGG.REST as BK

NREPS = int(sys.argv[1]) if len(sys.argv) > 1 else 5
PAUSE = float(sys.argv[2]) if len(sys.argv) > 2 else 0.4


def timeit(fn):
    t0 = time.perf_counter()
    fn().read()
    return time.perf_counter() - t0


# Warm up (connection setup, imports) before the measured replicates.
BK.kegg_info("kegg").read()
time.sleep(PAUSE)

for _ in range(NREPS):
    print("Info,Python,{}".format(timeit(lambda: BK.kegg_info("kegg"))))
    time.sleep(PAUSE)
    print("List,Python,{}".format(timeit(lambda: BK.kegg_list("pathway"))))
    time.sleep(PAUSE)
    print("Get,Python,{}".format(timeit(lambda: BK.kegg_get("hsa:10458"))))
    time.sleep(PAUSE)
