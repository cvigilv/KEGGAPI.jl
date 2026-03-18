"""
    kegg_conv(target_db::String, source_db::String)

Convert KEGG identifiers to/from outside identifiers.

# Arguments
- `target_db::String`: Target database
- `source_db::String`: Source database

# Examples
```julia
using KEGGAPI

KEGGAPI.conv("eco", "ncbi-geneid")
KEGGAPI.conv("ncbi-geneid", "eco")
KEGGAPI.conv("genes", "ncbi-geneid:948364")
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
    kegg_conv(target_db::String, dbentries::Vector{String}; [timeout::Float64 = 0.4])

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
- `timeout::Float64`: Time to wait between requests (default: 0.4 seconds)

# Examples
```julia
using KEGGAPI

KEGGAPI.conv("ncbi-proteinid", ["hsa:10458", "ece:Z5100"])
```
"""
function kegg_conv(target_db::String, dbentries::Vector{String}; timeout::Float64 = 0.4)
    urls = String[]
    data = []
    for chunk in chunk_vector(dbentries, 10)
        url = "https://rest.kegg.jp/conv/$(target_db)/$(join(chunk, "+"))"
        push!(urls, url)
        response_text = request(url)
        for datum in eachline(IOBuffer(response_text))
            id, d = split(datum, '\t') .|> String
            push!(data, [id, d])
        end
        sleep(timeout)
    end
    return KeggTupleList(urls, ["source", target_db], data)
end
