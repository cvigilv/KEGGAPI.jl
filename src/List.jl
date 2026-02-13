"""
KEGGAPI.list(database)

Get a list of entries from a specific database from the KEGG API.

Example:

```example
KEGGAPI.list("pathway")
```
"""
function list(query::String, query_type::String = "")
    # This function retrieves a list of entries from a specific database from the KEGG API.

    # Define the URL for the API request based on the provided 'list' argument.
    url = "https://rest.kegg.jp/list/$query"

    # Check if the requested 'list' is a "pathway" database.
    if query == "organism"
        # Make the API request and get the response as text.
        response_text = request(url)
        # If the 'list' is "organism," call the organism_parser function to parse the response.
        kegg_data = organism_parser(response_text, url)
    elseif query_type == "genes"
        # Make the API request and get the response as text.
        response_text = request(url)
        # If the 'list' is "genes," call the genes_parser function to parse the response.
        kegg_data = genomic_feature_parser(response_text, url)
    else
        # Make the API request and get the response as text.
        response_text = request(url)
        # Return an empty array.
        kegg_data = tuple_parser(response_text, url)
    end

    # Return the parsed data or an empty array if the data is not available.
    return kegg_data
end
