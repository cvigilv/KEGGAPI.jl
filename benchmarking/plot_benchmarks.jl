#!/usr/bin/env julia
#
# Render benchmark_compare.csv to benchmark_compare.png (the figure used in the
# README).
#
#     julia --project=benchmarking benchmarking/plot_benchmarks.jl
#
using DelimitedFiles
using Plots
using StatsPlots  # provides `groupedbar`

const BENCHDIR = @__DIR__
const CSV = joinpath(BENCHDIR, "benchmark_compare.csv")

isfile(CSV) || error("$CSV not found. Run run_benchmarks.jl first.")

raw, _ = readdlm(CSV, ',', header = true)
functions = String.(raw[:, 1])
languages = String.(raw[:, 2])
means = Float64.(raw[:, 3])
sds = Float64.(raw[:, 4])

# One grouped bar per operation, one series per language.
fn_order = unique(functions)
lang_order = unique(languages)

matrix = fill(NaN, length(fn_order), length(lang_order))
errors = zeros(length(fn_order), length(lang_order))
for i in eachindex(functions)
    r = findfirst(==(functions[i]), fn_order)
    c = findfirst(==(languages[i]), lang_order)
    matrix[r, c] = means[i]
    errors[r, c] = sds[i]
end

plt = groupedbar(
    fn_order,
    matrix;
    yerror = errors,
    label = permutedims(lang_order),
    xlabel = "KEGG operation",
    ylabel = "Time per call (s)",
    title = "KEGGAPI.jl benchmarks",
    legend = :topleft,
    bar_width = 0.7,
    framestyle = :box,
    size = (800, 450),
    dpi = 200,
)

out = joinpath(BENCHDIR, "benchmark_compare.png")
savefig(plt, out)
@info "Wrote $out"
