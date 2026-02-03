"""
KEGGAPI.conv(<target_db>, <source_db>)

Convert KEGG identifiers to/from outside identifiers.

Example:

```@example
using KEGGAPI
KEGGAPI.conv("eco", "ncbi-geneid")
KEGGAPI.conv("ncbi-geneid", "eco")
KEGGAPI.conv("ncbi-proteinid", "hsa:10458+ece:Z5100")
KEGGAPI.conv("genes", "ncbi-geneid:948364")
```
"""
function conv(target_db::String, source_db::String)
    # This function retrieves a list of entries from a specific database from the KEGG API.
    # Define the URL for the API request.
    url = "https://rest.kegg.jp/conv/$target_db/$source_db"
    response_text = request(url)
    kegg_data =
        conv_parser(
        response_text,
        url
    )
    # return the arrays
    return kegg_data
end
