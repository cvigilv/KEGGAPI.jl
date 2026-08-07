#!/usr/bin/env bash
# curl runner: times raw REST calls and prints one CSV row per replicate.
# Usage: bash runners/bench_curl.sh <nreps> <sleep_seconds>
set -euo pipefail

NREPS="${1:-5}"
PAUSE="${2:-0.4}"

BASE="https://rest.kegg.jp"

# label|path pairs -- keep in sync with the other runners.
CASES=(
    "info|$BASE/info/kegg"
    "list|$BASE/list/pathway"
    "find|$BASE/find/compound/glucose"
    "get|$BASE/get/hsa:10458"
    "getseq|$BASE/get/hsa:10458/aaseq"
    "conv|$BASE/conv/ncbi-geneid/eco:b0002"
    "link|$BASE/link/pathway/hsa:10458"
    "ddi|$BASE/ddi/D00564"
)

# Must match the interface name in run_benchmarks.jl.
LABEL="curl"

# `curl -w %{time_total}` reports the transfer time without shell startup cost.
timeit() {
    curl -s -o /dev/null -w '%{time_total}' "$1"
}

# Warm up before the measured replicates.
for case in "${CASES[@]}"; do
    curl -s -o /dev/null "${case#*|}"
    sleep "$PAUSE"
done

for _ in $(seq 1 "$NREPS"); do
    for case in "${CASES[@]}"; do
        echo "${case%%|*},$LABEL,$(timeit "${case#*|}")"
        sleep "$PAUSE"
    done
done
