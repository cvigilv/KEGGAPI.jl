#!/usr/bin/env bash
# curl runner: times raw REST calls and prints one CSV row per replicate.
# Usage: bash runners/bench_curl.sh <nreps> <sleep_seconds>
set -euo pipefail

NREPS="${1:-5}"
PAUSE="${2:-0.4}"

# `curl -w %{time_total}` reports the transfer time without shell startup cost.
timeit() {
    curl -s -o /dev/null -w '%{time_total}' "$1"
}

# Warm up before the measured replicates.
curl -s -o /dev/null "https://rest.kegg.jp/info/kegg"
sleep "$PAUSE"

for _ in $(seq 1 "$NREPS"); do
    echo "Info,Curl,$(timeit https://rest.kegg.jp/info/kegg)"
    sleep "$PAUSE"
    echo "List,Curl,$(timeit https://rest.kegg.jp/list/pathway)"
    sleep "$PAUSE"
    echo "Get,Curl,$(timeit https://rest.kegg.jp/get/hsa:10458)"
    sleep "$PAUSE"
done
