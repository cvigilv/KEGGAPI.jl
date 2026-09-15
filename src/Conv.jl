"""
    kegg_conv(target_db::String, source_db::String)

Convert KEGG identifiers to/from outside identifiers.

# Arguments
- `target_db::String`: Target database
- `source_db::String`: Source database

# Examples
```julia
using KEGGAPI

KEGGAPI.kegg_conv("eco", "ncbi-geneid")
KEGGAPI.kegg_conv("ncbi-geneid", "eco")
KEGGAPI.kegg_conv("genes", "ncbi-geneid:948364")
```

# Extended help

This operation can be used to convert entry identifiers (accession numbers) of outside databases
to KEGG identifiers, and vice versa. The first form allows database to database mapping, while
the second form allows conversion of a selected number of entries. The database name "genes" may
be used only in the second form.

## References

- [KEGG API](https://www.kegg.jp/kegg/rest/keggapi.html#conv)

"""
function kegg_conv(target_db::String, source_db::String)
    url = "https://rest.kegg.jp/conv/$target_db/$source_db"
    response_text = request(url)
    kegg_data = conv_parser(response_text, url)
    return kegg_data
end


"""
    kegg_conv(target_db::String, dbentries::Vector{String}; request_delay::Real = 0.4, timeout = nothing)

Convert KEGG identifiers to/from outside identifiers.

For gene identifiers:

    <dbentries> = database entries of the following <database>
    <database>  = <org> | genes | ncbi-geneid | ncbi-proteinid | uniprot
    <org>       = KEGG organism code or T number

For chemical substance identifiers:

    <dbentries> = database entries of the following <database>
    <database>  = compound | glycan | drug | pubchem | chebi

# Arguments
- `target_db::String`: Target database
- `dbentries::Vector{String}`: Database entries of the available databases
- `request_delay::Real`: Seconds to wait between batched requests. Defaults to
  0.4. No delay occurs when the input fits in one request.
- `timeout::Real`: Deprecated alias for `request_delay`. If both keywords are
  supplied, their values must be equal.

# Throws
- `ArgumentError`: If a delay is negative or non-finite, or if `request_delay`
  and `timeout` conflict.

# Examples
```julia
using KEGGAPI

KEGGAPI.kegg_conv("ncbi-proteinid", ["hsa:10458", "ece:Z5100"])
```
"""
function kegg_conv(
        target_db::String, dbentries::Vector{String};
        request_delay::Union{Nothing, Real} = nothing,
        timeout::Union{Nothing, Real} = nothing,
    )
    return _kegg_conv(target_db, dbentries, request, sleep; request_delay, timeout)
end

function _kegg_conv(
        target_db::String, dbentries::Vector{String}, requester::F, sleep_function::S;
        request_delay::Union{Nothing, Real} = nothing,
        timeout::Union{Nothing, Real} = nothing,
    ) where {F, S}
    request_count = cld(length(dbentries), KEGG_BATCH_SIZE)
    delay = resolve_request_delay(request_delay, timeout, :kegg_conv, request_count)
    urls = String[]
    data = []
    foreach_request_batch(dbentries, delay, sleep_function) do chunk
        url = "https://rest.kegg.jp/conv/$(target_db)/$(join(chunk, "+"))"
        push!(urls, url)
        response_text = requester(url)
        for datum in eachline(IOBuffer(response_text))
            id, d = split(datum, '\t') .|> String
            push!(data, [id, d])
        end
    end
    return KeggTupleList(urls, ["source", target_db], data)
end
