#!/usr/bin/env julia
#
# Render benchmark_compare.csv to benchmark_compare.png (the figure used in the
# README).
#
#     julia --project=benchmarking benchmarking/plot_benchmarks.jl
#
using DelimitedFiles
using Plots
using Plots.PlotMeasures  # provides `mm` for margins
using StatsPlots  # provides `groupedbar`

const BENCHDIR = @__DIR__
const CSV = joinpath(BENCHDIR, "benchmark_compare.csv")

isfile(CSV) || error("$CSV not found. Run run_benchmarks.jl first.")

# Read as text so blank medians (unsupported/skipped pairs) survive parsing.
raw, _ = readdlm(CSV, ',', String, header = true)
functions = strip.(raw[:, 1])
languages = strip.(raw[:, 2])
medians = [isempty(strip(s)) ? NaN : parse(Float64, strip(s)) for s in raw[:, 3]]

# One grouped bar per operation, one series per interface. Operations follow the
# canonical KEGG order rather than the CSV's order; anything not listed is
# appended so new cases still plot.
const CANONICAL = ["info", "list", "find", "get", "getseq", "conv", "link", "ddi"]
present = unique(functions)
fn_order = [f for f in CANONICAL if f in present]
append!(fn_order, sort([f for f in present if f ∉ CANONICAL]))
lang_order = unique(languages)

# Blank cells -- e.g. ddi, which KEGGREST and Bio.KEGG.REST do not wrap -- stay
# NaN so no bar is drawn for them.
matrix = fill(NaN, length(fn_order), length(lang_order))
for i in eachindex(functions)
    r = findfirst(==(functions[i]), fn_order)
    c = findfirst(==(languages[i]), lang_order)
    matrix[r, c] = medians[i]
end

plt = groupedbar(
    fn_order,
    matrix;
    label = permutedims(lang_order),
    xlabel = "KEGG operation",
    ylabel = "Median time per call (s)",
    title = "KEGGAPI.jl benchmarks",
    legend = :topleft,
    # Headroom so the tallest bar is not clipped by the axis.
    ylims = (0, 1.08 * maximum(filter(!isnan, matrix))),
    bar_width = 0.7,
    framestyle = :box,
    size = (1000, 500),
    dpi = 200,
    left_margin = 8mm,
    bottom_margin = 8mm,
)

out = joinpath(BENCHDIR, "benchmark_compare.png")
savefig(plt, out)
@info "Wrote $out"
