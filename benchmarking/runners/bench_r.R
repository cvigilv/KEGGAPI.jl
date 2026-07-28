# R runner: times KEGGREST calls and prints one CSV row per replicate.
# Usage: Rscript runners/bench_r.R <nreps> <sleep_seconds>
suppressMessages(library(KEGGREST))

args <- commandArgs(trailingOnly = TRUE)
nreps <- if (length(args) >= 1) as.integer(args[1]) else 5
pause <- if (length(args) >= 2) as.numeric(args[2]) else 0.4

# (label, thunk) pairs -- keep in sync with the other runners. KEGGREST has no
# ddi wrapper, so that case is absent here and reported as unsupported.
# NOTE: keggList (not keggInfo) is the counterpart of the list operation.
cases <- list(
    list("Info", function() keggInfo("kegg")),
    list("List", function() keggList("pathway")),
    list("Find", function() keggFind("compound", "glucose")),
    list("Get", function() keggGet("hsa:10458")),
    list("GetSeq", function() keggGet("hsa:10458", "aaseq")),
    list("Conv", function() keggConv("ncbi-geneid", "eco:b0002")),
    list("Link", function() keggLink("pathway", "hsa:10458"))
)

timeit <- function(fn) {
    t0 <- Sys.time()
    invisible(fn())
    as.numeric(difftime(Sys.time(), t0, units = "secs"))
}

# Warm up before the measured replicates.
for (case in cases) {
    invisible(case[[2]]())
    Sys.sleep(pause)
}

for (i in seq_len(nreps)) {
    for (case in cases) {
        cat(sprintf("%s,R,%s\n", case[[1]], timeit(case[[2]])))
        Sys.sleep(pause)
    }
}
