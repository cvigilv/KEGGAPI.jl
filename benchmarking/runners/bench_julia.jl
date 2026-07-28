# Julia runner: times KEGGAPI.jl calls and prints one CSV row per replicate.
# Usage: julia --project=. runners/bench_julia.jl <nreps> <sleep_seconds>
using KEGGAPI

const NREPS = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 5
const PAUSE = length(ARGS) >= 2 ? parse(Float64, ARGS[2]) : 0.4

# Warm up so compilation latency is not attributed to the first replicate.
KEGGAPI.kegg_info("kegg")
sleep(PAUSE)

function timeit(f)
    t0 = time_ns()
    f()
    return (time_ns() - t0) / 1.0e9
end

for _ in 1:NREPS
    println("Info,Julia,", timeit(() -> KEGGAPI.kegg_info("kegg")))
    sleep(PAUSE)
    println("List,Julia,", timeit(() -> KEGGAPI.kegg_list("pathway")))
    sleep(PAUSE)
    println("Get,Julia,", timeit(() -> KEGGAPI.kegg_get("hsa:10458")))
    sleep(PAUSE)
end
