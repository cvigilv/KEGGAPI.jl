#!/usr/bin/env julia
#
# Benchmark KEGGAPI.jl against KEGGREST (R), Bio.KEGG.REST (Python) and raw curl.
#
#     julia --project=benchmarking benchmarking/run_benchmarks.jl [--nreps N] [--pause S]
#
# Each interface runs the same three operations (info/kegg, list/pathway,
# get/hsa:10458) inside a single process, so what is measured is per-call time
# rather than interpreter startup. Interfaces whose dependencies are missing are
# reported and skipped, so this runs even with only Julia available.
#
# Writes benchmark_compare.csv (Function,Language,Mean,SD) next to this script.

using Statistics
using Printf

const BENCHDIR = @__DIR__
const RUNNERS = joinpath(BENCHDIR, "runners")

# ------------------------------------------------------------------ CLI parsing
function parse_args(args)
    nreps, pause = 5, 0.4
    i = 1
    while i <= length(args)
        if args[i] == "--nreps"
            nreps = parse(Int, args[i + 1]); i += 2
        elseif args[i] == "--pause"
            pause = parse(Float64, args[i + 1]); i += 2
        else
            error("Unknown argument: $(args[i])")
        end
    end
    return nreps, pause
end

const NREPS, PAUSE = parse_args(ARGS)

# ------------------------------------------------------------------ Interfaces
# `probe` must succeed for the interface to be benchmarked.
struct Interface
    name::String
    probe::Cmd
    run::Cmd
end

# Interpreters are overridable so a virtualenv / custom R can be used, e.g.
#   PYTHON=/path/to/venv/bin/python julia --project=benchmarking ...
const JULIA = get(ENV, "JULIA", "julia")
const RSCRIPT = get(ENV, "RSCRIPT", "Rscript")
const PYTHON = get(ENV, "PYTHON", "python3")

interfaces = [
    Interface(
        "Julia",
        `$JULIA --version`,
        `$JULIA --project=$BENCHDIR $(joinpath(RUNNERS, "bench_julia.jl")) $NREPS $PAUSE`,
    ),
    Interface(
        "R",
        `$RSCRIPT -e "suppressMessages(library(KEGGREST))"`,
        `$RSCRIPT $(joinpath(RUNNERS, "bench_r.R")) $NREPS $PAUSE`,
    ),
    Interface(
        "Python",
        `$PYTHON -c "import Bio.KEGG.REST"`,
        `$PYTHON $(joinpath(RUNNERS, "bench_python.py")) $NREPS $PAUSE`,
    ),
    Interface(
        "Curl",
        `curl --version`,
        `bash $(joinpath(RUNNERS, "bench_curl.sh")) $NREPS $PAUSE`,
    ),
]

available(iface) = success(pipeline(iface.probe, stdout = devnull, stderr = devnull))

# ------------------------------------------------------------------ Run
# Rows are (Function, Language) => vector of per-call seconds.
samples = Dict{Tuple{String, String}, Vector{Float64}}()

for iface in interfaces
    if !available(iface)
        @warn "Skipping $(iface.name): dependencies not installed" probe = iface.probe
        continue
    end

    @info "Benchmarking $(iface.name) ($NREPS replicates)..."
    output = try
        read(iface.run, String)
    catch e
        @warn "Skipping $(iface.name): runner failed" exception = e
        continue
    end

    for line in eachline(IOBuffer(output))
        fields = split(strip(line), ',')
        length(fields) == 3 || continue  # NOTE: ignore any incidental stdout noise
        fn, lang, secs = fields
        push!(get!(samples, (String(fn), String(lang)), Float64[]), parse(Float64, secs))
    end
end

isempty(samples) && error("No interface could be benchmarked.")

# ------------------------------------------------------------------ Summarise
outfile = joinpath(BENCHDIR, "benchmark_compare.csv")
open(outfile, "w") do io
    println(io, "Function,Language,Mean,SD")
    for key in sort(collect(keys(samples)))
        fn, lang = key
        times = samples[key]
        sd = length(times) > 1 ? std(times) : 0.0
        println(io, "$fn,$lang,$(mean(times)),$sd")
    end
end

@info "Wrote $outfile"
println()
@printf("%-10s %-10s %10s %10s\n", "Function", "Language", "Mean (s)", "SD (s)")
for key in sort(collect(keys(samples)))
    fn, lang = key
    times = samples[key]
    sd = length(times) > 1 ? std(times) : 0.0
    @printf("%-10s %-10s %10.4f %10.4f\n", fn, lang, mean(times), sd)
end
println("\nRegenerate the figure with:\n  julia --project=benchmarking benchmarking/plot_benchmarks.jl")
