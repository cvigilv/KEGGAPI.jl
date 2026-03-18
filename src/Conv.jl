"""
    kegg_conv(target_db::String, source_db::String)
    kegg_conv(target_db::String, dbentries::String)

Convert KEGG identifiers to/from outside identifiers.

# Arguments
- `target_db::String`: Target database
- `source_db::String`: Source database

# Examples
```julia
using KEGGAPI

KEGGAPI.conv("eco", "ncbi-geneid")
KEGGAPI.conv("ncbi-geneid", "eco")
KEGGAPI.conv("ncbi-proteinid", "hsa:10458+ece:Z5100")
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
