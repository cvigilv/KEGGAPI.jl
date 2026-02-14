"""
KEGGAPI.info(database) -> String

Get information about a specific database from the KEGG API.

Example:

```example
KEGGAPI.info("kegg")
```
"""
function kegg_info(database::String)
    # function to retrieve information about a specific database from the KEGG API.
    # Define the URL for the API request.
    url = "https://rest.kegg.jp/info/$database"
    # Make a request to the URL and convert the response to a string.
    response_text = request(url)
    # Return the lines as a string.
    return response_text
end
