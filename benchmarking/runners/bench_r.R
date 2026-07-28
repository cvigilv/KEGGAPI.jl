# R runner: times KEGGREST calls and prints one CSV row per replicate.
# Usage: Rscript runners/bench_r.R <nreps> <sleep_seconds>
suppressMessages(library(KEGGREST))

args <- commandArgs(trailingOnly = TRUE)
nreps <- if (length(args) >= 1) as.integer(args[1]) else 5
pause <- if (length(args) >= 2) as.numeric(args[2]) else 0.4

timeit <- function(expr) {
    t0 <- Sys.time()
    force(expr)
    as.numeric(difftime(Sys.time(), t0, units = "secs"))
}

# Warm up before the measured replicates.
invisible(keggInfo("kegg"))
Sys.sleep(pause)

for (i in seq_len(nreps)) {
    cat(sprintf("Info,R,%s\n", timeit(keggInfo("kegg"))))
    Sys.sleep(pause)
    # NOTE: keggList (not keggInfo) is the counterpart of the list operation.
    cat(sprintf("List,R,%s\n", timeit(keggList("pathway"))))
    Sys.sleep(pause)
    cat(sprintf("Get,R,%s\n", timeit(keggGet("hsa:10458"))))
    Sys.sleep(pause)
}
