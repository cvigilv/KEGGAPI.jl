# Benchmarking

Compares `KEGGAPI.jl` against the other common KEGG REST clients — `KEGGREST`
(R), `Bio.KEGG.REST` (Python) and raw `curl` — across the KEGG operations:

| Operation | Query                          | Covered by            |
|:----------|:-------------------------------|:----------------------|
| `Info`    | `info/kegg`                    | all                   |
| `List`    | `list/pathway`                 | all                   |
| `Find`    | `find/compound/glucose`        | all                   |
| `Get`     | `get/hsa:10458`                | all                   |
| `GetSeq`  | `get/hsa:10458/aaseq`          | all                   |
| `Conv`    | `conv/ncbi-geneid/eco:b0002`   | all                   |
| `Link`    | `link/pathway/hsa:10458`       | all                   |
| `Ddi`     | `ddi/D00564`                   | KEGGAPI.jl, curl only |

`ddi` has no wrapper in KEGGREST or Bio.KEGG.REST, so those interfaces simply
have no bar for it in the figure. The `conv` case uses `ncbi-geneid` rather than
`ncbi-proteinid` because Bio.KEGG.REST only recognises the legacy outside-database
names (`ncbi-gi | ncbi-geneid | uniprot`) and rejects the newer ones.

`KEGGAPI.jl`'s chunked `kegg_get` sleeps internally to respect KEGG's rate limit;
the Julia runner passes `timeout = 0.0` so that deliberate delay is not counted
as work, since the runner already spaces its own calls.

Each interface runs every operation inside a **single** process, so what is
measured is per-call time rather than interpreter startup. A warm-up call is
discarded before the measured replicates, and calls are spaced by `--pause`
seconds (default 0.4 s) to stay under KEGG's limit of 3 requests per second.

## Running

One-time setup of the isolated benchmarking environment:

```bash
julia --project=benchmarking -e 'using Pkg; Pkg.develop(PackageSpec(path=".")); Pkg.instantiate()'
```

Run the benchmarks (writes `benchmark_compare.csv`):

```bash
julia --project=benchmarking benchmarking/run_benchmarks.jl --nreps 15
```

Regenerate the figure used in the main README (writes `benchmark_compare.png`):

```bash
julia --project=benchmarking benchmarking/plot_benchmarks.jl
```

## Optional interfaces

Only Julia and `curl` are required. Interfaces whose dependencies are missing
are reported and skipped, so the run always completes. To include the others:

```bash
# R (KEGGREST via Bioconductor)
Rscript -e 'install.packages("BiocManager"); BiocManager::install("KEGGREST")'

# Python (Biopython). On PEP 668 "externally managed" installs, use a venv:
python3 -m venv /tmp/kegg_bench_venv
/tmp/kegg_bench_venv/bin/pip install biopython
```

The `JULIA`, `RSCRIPT` and `PYTHON` environment variables override which
interpreter is used, which is how a virtualenv is selected:

```bash
PYTHON=/tmp/kegg_bench_venv/bin/python \
  julia --project=benchmarking benchmarking/run_benchmarks.jl --nreps 15
```

## Layout

| Path                     | Purpose                                            |
|:-------------------------|:---------------------------------------------------|
| `run_benchmarks.jl`      | Orchestrator: runs each interface, writes the CSV   |
| `plot_benchmarks.jl`     | Renders the CSV to `benchmark_compare.png`          |
| `runners/bench_julia.jl` | KEGGAPI.jl timings                                  |
| `runners/bench_r.R`      | KEGGREST timings                                    |
| `runners/bench_python.py`| Bio.KEGG.REST timings                               |
| `runners/bench_curl.sh`  | Raw REST timings via `curl -w %{time_total}`        |

Each runner prints `Function,Language,seconds` — one row per replicate — so it
can also be run on its own, e.g.:

```bash
julia --project=benchmarking benchmarking/runners/bench_julia.jl 5 0.4
```

> **Note:** results are dominated by network round-trip time to `rest.kegg.jp`
> and will vary with location and server load. Compare interfaces within a
> single run rather than across runs.
