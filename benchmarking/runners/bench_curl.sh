#!/usr/bin/env bash
# curl runner: times raw REST calls and prints one CSV row per replicate.
# Usage: bash runners/bench_curl.sh <nreps> <sleep_seconds>
set -euo pipefail

NREPS="${1:-5}"
PAUSE="${2:-0.4}"

BASE="https://rest.kegg.jp"

# label|path pairs -- keep in sync with the other runners.
CASES=(
    "Info|$BASE/info/kegg"
    "List|$BASE/list/pathway"
    "Find|$BASE/find/compound/glucose"
    "Get|$BASE/get/hsa:10458"
    "GetSeq|$BASE/get/hsa:10458/aaseq"
    "Conv|$BASE/conv/ncbi-geneid/eco:b0002"
    "Link|$BASE/link/pathway/hsa:10458"
    "Ddi|$BASE/ddi/D00564"
)

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
        echo "${case%%|*},Curl,$(timeit "${case#*|}")"
        sleep "$PAUSE"
    done
done
