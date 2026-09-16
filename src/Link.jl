# ---------------------------------------------------------------------------- Constants
# RDF output formats. These are only available for the drug/atc/jtc databases and
# return non-tabular text, so the raw response is returned unparsed.
const KEGG_LINK_RDF_OPTIONS = ("turtle", "n-triple")

# ---------------------------------------------------------------------------- Main functions
"""
    kegg_link(target_db::String, source_db::String, option::String = "") -> Union{KeggTupleList, String}

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

# Returns
- `KeggTupleList`: The linked identifiers, request URL, and column names for
  tabular responses.
- `String`: The raw RDF response when `option` is `"turtle"` or `"n-triple"`.

# Examples
```jldoctest
julia> links = kegg_link("pathway", "hsa:10458");

julia> links isa KEGGAPI.KeggTupleList && !isempty(links.data)
true

julia> rdf = kegg_link("atc", "D00564", "turtle");

julia> rdf isa String && !isempty(rdf)
true
```

# Extended help

`kegg_link` retrieves cross-references within KEGG and between KEGG and outside
databases. Pass database names to retrieve all links between two databases, or
pass entry identifiers to retrieve links for selected entries.
"""
function kegg_link(target_db::String, source_db::String, option::String = "")
    option_str = isempty(option) ? "" : "/$option"
    url = "https://rest.kegg.jp/link/$target_db/$source_db$option_str"
    response_text = request(url)
    option in KEGG_LINK_RDF_OPTIONS && return response_text
    return conv_parser(response_text, url)
end

"""
    kegg_link(target_db::String, dbentries::Vector{String}, option::String = ""; request_delay::Real = 0.4, timeout = nothing) -> Union{KeggTupleList, String}

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
- `dbentries::Vector{String}`, entries from the source database
- `option::String`, optional refinement of the query. A taxonomic rank
  (`species | genus | family | order | class | phylum`) for `genome`/`taxonomy`
  links, or an RDF output format (`turtle | n-triple`) for the `drug`/`atc`/`jtc`
  databases (in which case the raw response text is returned).
- `request_delay::Real`, seconds to wait between batched requests. Defaults to
  0.4. No delay occurs when the input fits in one request.
- `timeout::Real`, deprecated alias for `request_delay`. If both keywords are
  supplied, their values must be equal.

# Returns
- `KeggTupleList`: The linked identifiers, request URLs, and column names for
  tabular responses.
- `String`: The concatenated raw RDF responses when `option` is `"turtle"` or
  `"n-triple"`.

# Throws
- `ArgumentError`: If a delay is negative or non-finite, or if `request_delay`
  and `timeout` conflict.

# Examples
```jldoctest
julia> links = kegg_link("pathway", ["hsa:10458", "hsa:10459"]);

julia> links isa KEGGAPI.KeggTupleList && links.url isa Vector{String} && !isempty(links.data)
true
```

The vector form sends at most 10 entries per request. It waits `request_delay`
seconds between requests, but does not wait after the final request.
"""
function kegg_link(
        target_db::String, dbentries::Vector{String}, option::String = "";
        request_delay::Union{Nothing, Real} = nothing,
        timeout::Union{Nothing, Real} = nothing,
    )
    return _kegg_link(target_db, dbentries, option, request, sleep; request_delay, timeout)
end

function _kegg_link(
        target_db::String, dbentries::Vector{String}, option::String, requester::F,
        sleep_function::S; request_delay::Union{Nothing, Real} = nothing,
        timeout::Union{Nothing, Real} = nothing,
    ) where {F, S}
    option_str = isempty(option) ? "" : "/$option"
    is_rdf = option in KEGG_LINK_RDF_OPTIONS
    request_count = cld(length(dbentries), KEGG_BATCH_SIZE)
    delay = resolve_request_delay(request_delay, timeout, :kegg_link, request_count)

    urls = String[]
    data = []
    rdf_text = ""
    foreach_request_batch(dbentries, delay, sleep_function) do chunk
        url = "https://rest.kegg.jp/link/$(target_db)/$(join(chunk, "+"))$option_str"
        push!(urls, url)
        response_text = requester(url)
        if is_rdf
            rdf_text *= response_text
        else
            for datum in eachline(IOBuffer(response_text))
                id, d = split(datum, '\t') .|> String
                push!(data, [id, d])
            end
        end
    end

    is_rdf && return rdf_text
    return KeggTupleList(urls, ["source", target_db], data)
end
