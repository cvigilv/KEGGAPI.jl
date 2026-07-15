using KEGGAPI
using Documenter

DocMeta.setdocmeta!(KEGGAPI, :DocTestSetup, :(using KEGGAPI); recursive = true)

makedocs(;
    modules = [KEGGAPI],
    authors = "Nicholas Geoffrion, Maria Victoria Aguilar Pontes, Carlos Vigil-Vásquez",
    repo = "https://github.com/cvigilv/KEGGAPI.jl/blob/{commit}{path}#{line}",
    sitename = "KEGGAPI.jl",
    # `@example` blocks make live KEGG API calls at build time, so a transient
    # KEGG outage or endpoint hiccup must not hard-fail the docs deploy.
    warnonly = [:example_block],
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://cvigilv.github.io/KEGGAPI.jl",
        edit_link = "main",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "Manual" => Any[
            "Getting started" => "man/getting-started.md",
            "Examples" => "man/examples.md",
            "API reference" => "man/api.md",
        ],
    ],
)

deploydocs(;
    repo = "github.com/cvigilv/KEGGAPI.jl",
    devbranch = "main",
)
