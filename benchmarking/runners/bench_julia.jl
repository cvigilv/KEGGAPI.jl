# Julia runner: times KEGGAPI.jl calls and prints one CSV row per replicate.
# Usage: julia --project=. runners/bench_julia.jl <nreps> <sleep_seconds>
using KEGGAPI
using Logging

const NREPS = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 5
const PAUSE = length(ARGS) >= 2 ? parse(Float64, ARGS[2]) : 0.4

# The chunked `kegg_get` methods sleep internally to respect KEGG's rate limit.
# This runner already spaces its own calls, so that sleep is disabled here to
# measure the actual request/parse work; the resulting @warn is silenced.
get_entry(args...) = with_logger(NullLogger()) do
    KEGGAPI.kegg_get(args...; timeout = 0.0)
end

# (label, thunk) pairs -- keep in sync with the other runners.
const CASES = [
    ("info", () -> KEGGAPI.kegg_info("kegg")),
    ("list", () -> KEGGAPI.kegg_list("pathway")),
    ("find", () -> KEGGAPI.kegg_find("compound", "glucose")),
    ("get", () -> get_entry("hsa:10458")),
    ("getseq", () -> get_entry("hsa:10458", :aaseq)),
    ("conv", () -> KEGGAPI.kegg_conv("ncbi-geneid", "eco:b0002")),
    ("link", () -> KEGGAPI.kegg_link("pathway", "hsa:10458")),
    ("ddi", () -> KEGGAPI.kegg_ddi("D00564")),
]

# Must match the interface name in run_benchmarks.jl.
const LABEL = "KEGGAPI.jl"

# Warm up so compilation latency is not attributed to the first replicate.
for (_, thunk) in CASES
    thunk()
    sleep(PAUSE)
end

function timeit(f)
    t0 = time_ns()
    f()
    return (time_ns() - t0) / 1.0e9
end

for _ in 1:NREPS, (label, thunk) in CASES
    println("$label,$LABEL,", timeit(thunk))
    sleep(PAUSE)
end
