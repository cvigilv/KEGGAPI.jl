using HTTP

"""
    kegg_list(database::String)
    kegg_list(pathway::String, org::String)
    kegg_list(brite::String, option::String)

Get a list of entry identifiers and associated names

Allowed `database` values are:
```
pathway | brite   | module   | ko     | <org>    | vg     | vp     |
ag      | genome  | compound | glycan | reaction | rclass | enzyme |
network | variant | disease  | drug   | dgroup   | organism
```

# Arguments
- `database::Symbol`: The KEGG database for which to retrieve the list of entries.

# Returns
- `data::Vector{Tuple{String, String}}`: A vector of tuples containing the entry
  identifiers and associated names for the specified database. If the data is
  not available, an empty vector is returned.

# Extended help

This operation can be used to obtain a list of all entries in each database. The
database names shown in Tables 1 and 2, excluding the composite database names
of genes, ligand and kegg, may be given. The special database name "organism" is
allowed only in this operation, which may be used to obtain a list of KEGG
organisms with the three- or four-letter organism codes.

When the organism code is known, the second form can be used to obtain a list of
organism-specific pathways.

The third form is a similar option for brite hierarchies.

# References

- https://www.kegg.jp/kegg/rest/keggapi.html#list
```
"""
function kegg_list(query::String, query_type::String = "")
    url = "https://rest.kegg.jp/list/$query"

    # Check request type
    if query == "organism"
        response_text = KEGGAPI.request(url)
        result = organism_parser(response_text, url)
    elseif query_type == "genes"
        response_text = KEGGAPI.request(url)
        result = genomic_feature_parser(response_text, url)
    else
        data = []
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
    return KeggTupleList(urls, fill(missing, length(first(data))), data)
end
