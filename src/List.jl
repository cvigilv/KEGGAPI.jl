"""
    kegg_list(query::String, query_type::String = "") -> Union{KeggTupleList, KeggGenesList}

Get a list of entry identifiers and associated names

Allowed `database` values are:
```
pathway  | brite   | module   | ko      | <org>    | ag     | vg      |
vp       | genome  | vtax     | vgenome | compound | glycan | reaction|
rclass   | rmodule | enzyme   | network | ntmap    | variant| disease |
drug     | dgroup
```

# Returns

- `KeggTupleList`: Rows from a two-column response, a response with an
  unrecognized width, or an empty response.
- `KeggGenesList`: The four columns in an organism-specific gene response.

# Extended help

This operation can be used to obtain a list of all entries in each database. The
database names shown in the tables above, excluding the composite database names
of genes and kegg, may be given. To obtain a list of KEGG organisms with their
three- or four-letter organism codes, use the `genome` database.

The optional `query_type` becomes the second URL segment. For pathway queries,
pass an organism code to list organism-specific pathways. For BRITE queries,
pass `"br"`, `"jp"`, `"ko"`, or an organism code. For genome queries, pass an
organism group name or taxonomy `<rank_id>` such as a phylum, class, order,
family, genus, or species identifier.

# References

- https://www.kegg.jp/kegg/rest/keggapi.html#list
```
"""
function kegg_list(query::String, query_type::String = "")
    return _kegg_list(query, query_type, request)
end

function _kegg_list(query::String, query_type::String, request_function::F) where {F}
    url = "https://rest.kegg.jp/list/$query"
    isempty(query_type) || (url *= "/$query_type")
    response_text = request_function(url)
    return list_parser(response_text, url)
end

"""
    kegg_list(dbentries::Vector{String}; request_delay::Real = 0.4, timeout = nothing) -> KeggTupleList

Get a list of entry identifiers and associated names

# Arguments
- `dbentries::Vector{String}`: The list of entries to list.
- `request_delay::Real`: Seconds to wait between batched requests. Defaults to
  0.4. No delay occurs when the input fits in one request.
- `timeout::Real`: Deprecated alias for `request_delay`. If both keywords are
  supplied, their values must be equal.

# Throws
- `ArgumentError`: If a delay is negative or non-finite, or if `request_delay`
  and `timeout` conflict.

# Returns
- `data::KeggTupleList`: A data structure containing the `url`, the `data` retrieved,
  and the `columns` names for the data.

# Extended help

The input is limited to 10 entries per request. Larger inputs are split into
batches, with `request_delay` seconds between requests and no wait after the
final request. The default of 0.4 seconds keeps batched calls below KEGG's limit
of three requests per second.
"""
function kegg_list(
        dbentries::Vector{String}; request_delay::Union{Nothing, Real} = nothing,
        timeout::Union{Nothing, Real} = nothing,
    )
    return _kegg_list(dbentries, request, sleep; request_delay, timeout)
end

function _kegg_list(
        dbentries::Vector{String}, requester::F, sleep_function::S;
        request_delay::Union{Nothing, Real} = nothing,
        timeout::Union{Nothing, Real} = nothing,
    ) where {F, S}
    request_count = cld(length(dbentries), KEGG_BATCH_SIZE)
    delay = resolve_request_delay(request_delay, timeout, :kegg_list, request_count)
    urls = String[]
    data = []
    foreach_request_batch(dbentries, delay, sleep_function) do chunk
        url = "https://rest.kegg.jp/list/$(join(chunk, "+"))"
        push!(urls, url)
        response_text = requester(url)
        append!(data, list_parser(response_text, url).data)
    end
    colnames = inferred_list_colnames(data)
    return KeggTupleList(urls, colnames, data)
end
