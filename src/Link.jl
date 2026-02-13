"""
KEGGAPI.conv(<target_db>, <source_db>)

Find related entries by using database cross-references

Example:

```example
KEGGAPI.link("pathway", "hsa")
```
"""
function link(target_db::String, source_db::String)
    # This function retrieves a list of entries from a specific database from the KEGG API.
    # Define the URL for the API request.
    url = "https://rest.kegg.jp/link/$target_db/$source_db"
    response_text = request(url)
    kegg_data =
        conv_parser(
        response_text,
        url
    )
    # return the arrays
    return kegg_data
end
