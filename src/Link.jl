# ---------------------------------------------------------------------------- Constants
# RDF output formats. These are only available for the drug/atc/jtc databases and
# return non-tabular text, so the raw response is returned unparsed.
const KEGG_LINK_RDF_OPTIONS = ("turtle", "n-triple")

# ---------------------------------------------------------------------------- Main functions
"""
    kegg_link(target_db::String, source_db::String, option::String = "")

Find related entries by using database cross-references.

The available KEGG databases are:

    pathway | brite    | module | ko      | <org>   | ag     | vg      |
    vp      | genome   | vtax   | vgenome | compound| glycan | reaction|
    rclass  | rmodule  | enzyme | network | ntmap   | variant | disease |
    drug    | dgroup   | <outside_db>

and the available external databases are:

    pubmed | taxonomy | atc | jtc | ndc | yk

# Arguments
- `target_db::String`: Target database
- `source_db::String`: Source database
- `option::String`: Optional refinement of the query. For `genome`/`taxonomy`
  links a taxonomic rank may be given (`species | genus | family | order | class
  | phylum`). For the `drug`/`atc`/`jtc` databases an RDF output format may be
  requested (`turtle | n-triple`), in which case the raw response text is
  returned instead of a `KeggTupleList`.

# Examples
```julia
using KEGGAPI

KEGGAPI.kegg_link("pathway", "hsa")
KEGGAPI.kegg_link("atc", "D00564", "turtle")   # raw RDF (turtle) String
```

# Extended help

This operation allows retrieval of cross-references within all KEGG databases, as
well as between KEGG databases and outside databases. It is useful for finding
various relationships, such as relationships between genes and pathways. This form
allows retrieval of database to database cross-references.
"""
function kegg_link(target_db::String, source_db::String, option::String = "")
    option_str = isempty(option) ? "" : "/$option"
    url = "https://rest.kegg.jp/link/$target_db/$source_db$option_str"
    response_text = request(url)
    option in KEGG_LINK_RDF_OPTIONS && return response_text
    return conv_parser(response_text, url)
end

"""
    kegg_link(target_db::String, dbentries::Vector{String}, option::String = ""; [timeout::Float64 = 0.4])

Find related entries by using database cross-references.

The available KEGG databases are:

    pathway | brite    | module | ko      | <org>   | ag     | vg      |
    vp      | genome   | vtax   | vgenome | compound| glycan | reaction|
    rclass  | rmodule  | enzyme | network | ntmap   | variant | disease |
    drug    | dgroup   | <outside_db>

and the available external databases are:

    pubmed | taxonomy | atc | jtc | ndc | yk

# Arguments

- `target_db::String`, target database
- `dbentries::Vector{String}`, KEGG database entries of the available databases
- `option::String`, optional refinement of the query. A taxonomic rank
  (`species | genus | family | order | class | phylum`) for `genome`/`taxonomy`
  links, or an RDF output format (`turtle | n-triple`) for the `drug`/`atc`/`jtc`
  databases (in which case the raw response text is returned).
- `timeout::Float64`, time to wait between requests (default: 0.4 seconds)
"""
function kegg_link(target_db::String, dbentries::Vector{String}, option::String = ""; timeout::Float64 = 0.4)
    option_str = isempty(option) ? "" : "/$option"
    is_rdf = option in KEGG_LINK_RDF_OPTIONS

    urls = String[]
    data = []
    rdf_text = ""
    for chunk in chunk_vector(dbentries, 10)
        url = "https://rest.kegg.jp/link/$(target_db)/$(join(chunk, "+"))$option_str"
        push!(urls, url)
        response_text = request(url)
        if is_rdf
            rdf_text *= response_text
        else
            for datum in eachline(IOBuffer(response_text))
                id, d = split(datum, '\t') .|> String
                push!(data, [id, d])
            end
        end
        sleep(timeout)
    end

    is_rdf && return rdf_text
    return KeggTupleList(urls, ["source", target_db], data)
end
