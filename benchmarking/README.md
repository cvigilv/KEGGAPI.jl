# Benchmarking

This benchmark compares `KEGGAPI.jl`, `KEGGREST` for R, `Bio.KEGG.REST` for
Python, and raw `curl` across these KEGG operations:

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

KEGGREST and Bio.KEGG.REST do not wrap `ddi`, so the figure omits their bars for
that operation. The `conv` case uses `ncbi-geneid` rather than
`ncbi-proteinid` because Bio.KEGG.REST only recognises the legacy outside-database
names (`ncbi-gi | ncbi-geneid | uniprot`) and rejects the newer ones.

`KEGGAPI.jl`'s chunked `kegg_get` waits between requests to respect KEGG's rate
limit. The Julia runner passes `request_delay = 0.0` because it already spaces
calls and must not time the same delay twice.

Each interface runs every operation in one process, which excludes interpreter
startup from the measurements. The runner discards a warm-up call before the
measured replicates and spaces calls by `--pause`
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

Only Julia and `curl` are required. The script reports and skips interfaces
whose dependencies are missing. To include the others:

```bash
# R (KEGGREST via Bioconductor)
Rscript -e 'install.packages("BiocManager"); BiocManager::install("KEGGREST")'

# Python (Biopython). On PEP 668 "externally managed" installs, use a venv:
python3 -m venv /tmp/kegg_bench_venv
/tmp/kegg_bench_venv/bin/pip install biopython
```

### Nix-provided R

A Nix-provided R installs packages from source but does not expose its dependency
paths to those builds, so CRAN/Bioconductor sources fail to link (`library not found
for -lintl`, `zlib.h not found`, `-lldap`, `-lkrb5`). Point `R_MAKEVARS_USER` at
a Makevars supplying the paths. Adjust the store hashes to match your system.
Find them with `otool -L $(R RHOME)/lib/libR.dylib` and
`ls -d /nix/store/*<pkg>*`:

```make
GETTEXT  = /nix/store/...-gettext-0.22.5
ZLIB_DEV = /nix/store/...-zlib-1.3.1-dev
ZLIB     = /nix/store/...-zlib-1.3.1
PNG_DEV  = /nix/store/...-libpng-apng-1.6.46-dev
PNG      = /nix/store/...-libpng-apng-1.6.46
LDAP     = /nix/store/...-openldap-2.6.9
KRB5     = /nix/store/...-krb5-1.21.3-lib

CPPFLAGS += -I$(ZLIB_DEV)/include -I$(PNG_DEV)/include
LDFLAGS  += -L$(GETTEXT)/lib -L$(ZLIB)/lib -L$(PNG)/lib -L$(LDAP)/lib -L$(KRB5)/lib
```

```bash
R_MAKEVARS_USER=/path/to/Makevars \
  Rscript -e 'BiocManager::install("KEGGREST", ask = FALSE, update = FALSE)'
```

`R_MAKEVARS_USER` applies the settings only to this installation instead of
writing them to `~/.R/Makevars`. The benchmark does not need it after the
packages are built.

### Selecting interpreters

Set `JULIA`, `RSCRIPT`, or `PYTHON` to select an interpreter. For example, use
`PYTHON` to select a virtual environment:

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

Each runner prints one `Function,Language,seconds` row per replicate. Run an
individual runner with:

```bash
julia --project=benchmarking benchmarking/runners/bench_julia.jl 5 0.4
```

Network round-trip time to `rest.kegg.jp` dominates these results. Compare
interfaces within one run because location and server load vary between runs.
