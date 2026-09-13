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

- `KeggTupleList`: Rows whose first field is `ID`. Two-field responses also name
  the second field `Details`; additional fields are left unnamed.
- `KeggGenesList`: Rows with `ID`, `Type`, `Chromosomal Position`, and `Gene Name`
  fields when `query_type` is `"genes"`.

# Extended help

This operation can be used to obtain a list of all entries in each database. The
database names shown in the tables above, excluding the composite database names
of genes and kegg, may be given. To obtain a list of KEGG organisms with their
three- or four-letter organism codes, use the `genome` database.

When the organism code is known, the second form can be used to obtain a list of
organism-specific pathways.

The third form is a similar option for brite hierarchies (`br | jp | ko | <org>`).

The fourth form lists the genomes for a KEGG organism group name or a taxonomy
`<rank_id>` (phylum, class, order, family, genus or species).

# References

- https://www.kegg.jp/kegg/rest/keggapi.html#list
```
"""
function kegg_list(query::String, query_type::String = "")
    url = "https://rest.kegg.jp/list/$query"

    # Check request type
    if query_type == "genes"
        response_text = KEGGAPI.request(url)
        result = genomic_feature_parser(response_text, url)
    else
        url *= "/$query_type"
        # issue #28: parse the complete response so network chunks cannot split rows.
        response_text = KEGGAPI.request(url)
        result = tuple_parser(response_text, url)
    end

    # Return the parsed data or an empty array if the data is not available.
    return result
end

"""
    kegg_list(dbentries::Vector{String}; timeout::Float64 = 0.4) -> KeggTupleList

Get a list of entry identifiers and associated names

# Arguments
- `dbentries::Vector{String}`: The list of entries to list.

# Returns
- `KeggTupleList`: Rows with `ID` and `Details` fields.

# Extended help

The input is limited up to 10 entries; if more are provided the query will be
split into chunks of 10 entries and multiple requests will be made with a `timeout`
between each request (KEGG API indicates that the maximum API calls per seconds
is 3, so a default timeout of 0.4 seconds is set to ensure that).
"""
function kegg_list(dbentries::Vector{String}; timeout::Float64 = 0.4)
    urls = String[]
    data = []
    for chunk in chunk_vector(dbentries, 10)
        url = "https://rest.kegg.jp/list/$(join(chunk, "+"))"
        push!(urls, url)
        response_text = request(url)
        for datum in eachline(IOBuffer(response_text))
            id, d = split(datum, '\t') .|> String
            push!(data, [id, d])
        end
        sleep(timeout)
    end
    return KeggTupleList(urls, ["ID", "Details"], data)
end
