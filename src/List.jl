using HTTP

"""
    kegg_list(database::String)
    kegg_list(pathway::String, org::String)
    kegg_list(brite::String, option::String)
    kegg_list(genome::String, option::String)

Get a list of entry identifiers and associated names

Allowed `database` values are:
```
pathway  | brite   | module   | ko      | <org>    | ag     | vg      |
vp       | genome  | vtax     | vgenome | compound | glycan | reaction|
rclass   | rmodule | enzyme   | network | ntmap    | variant| disease |
drug     | dgroup
```

# Returns

- `data::Vector{Tuple{String, String}}`: A vector of tuples containing the entry
  identifiers and associated names for the specified database. If the data is
  not available, an empty vector is returned.

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
        data = []
        url *= "/$query_type"
        try
            HTTP.open(:GET, url) do stream
                while !eof(stream)
                    chunk = readavailable(stream) |> String
                    for line in eachline(IOBuffer(chunk))
                        push!(data, split(line, '\t') .|> String)
                    end
                end
            end
            result = KeggTupleList(
                url,
                ["ID"; repeat([missing], length(data[1]) - 1)],
                data
            )
        catch e
            throw(KEGGAPI.RequestError("Failed to retrieve data from KEGG API: $(e)"))
        end
    end

    # Return the parsed data or an empty array if the data is not available.
    return result
end

"""
    kegg_list(dbentries::Vector{String}; timeout::Float64 = 0.4)

Get a list of entry identifiers and associated names

# Arguments
- `dbentries::Vector{String}`: The list of entries to list.

# Returns
- `data::KeggTupleList`: A data structure containing the `url`, the `data` retrieved,
  and the `columns` names for the data.

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
    colnames = isempty(data) ? Union{String, Missing}[] : Union{String, Missing}["ID"; fill(missing, length(first(data)) - 1)]
    return KeggTupleList(urls, colnames, data)
end
