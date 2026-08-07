"""Python runner: times Bio.KEGG.REST calls, one CSV row per replicate.

Usage: python3 runners/bench_python.py <nreps> <sleep_seconds>
"""
import sys
import time

import Bio.KEGG.REST as BK

NREPS = int(sys.argv[1]) if len(sys.argv) > 1 else 5
PAUSE = float(sys.argv[2]) if len(sys.argv) > 2 else 0.4

# (label, thunk) pairs -- keep in sync with the other runners. Bio.KEGG.REST has
# no ddi wrapper, so that case is absent here and reported as unsupported.
CASES = [
    ("info", lambda: BK.kegg_info("kegg")),
    ("list", lambda: BK.kegg_list("pathway")),
    ("find", lambda: BK.kegg_find("compound", "glucose")),
    ("get", lambda: BK.kegg_get("hsa:10458")),
    ("getseq", lambda: BK.kegg_get("hsa:10458", "aaseq")),
    ("conv", lambda: BK.kegg_conv("ncbi-geneid", "eco:b0002")),
    ("link", lambda: BK.kegg_link("pathway", "hsa:10458")),
]

# Must match the interface name in run_benchmarks.jl.
LABEL = "Bio.KEGG.REST (Python)"


def timeit(fn):
    t0 = time.perf_counter()
    fn().read()
    return time.perf_counter() - t0


# Warm up (connection setup, imports) before the measured replicates.
for _, thunk in CASES:
    thunk().read()
    time.sleep(PAUSE)

for _ in range(NREPS):
    for label, thunk in CASES:
        print("{},{},{}".format(label, LABEL, timeit(thunk)))
        time.sleep(PAUSE)
