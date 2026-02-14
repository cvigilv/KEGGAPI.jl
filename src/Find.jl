"""
KEGGAPI.find(database, query) -> KeggTupleList

Find entries in a specific database from the KEGG API.

```@example
using KEGGAPI
KEGGAPI.find("compound","glucose")
```
"""
function kegg_find(database::String, query::String, option::String = "")
    # This function retrieves a list of entries from a specific database from the KEGG API.
    query = replace(query, " " => "+")
    # Check if the requested database is a "pathway" database
    if database in ["pathway", "genes", "module", "orthology", "disease", "brite"]
        if option != ""
            throw(ArgumentError("The option argument is not available for pathway and genes databases"))
        end
        # Construct the URL for the API request
        url = "https://rest.kegg.jp/find/$database/$query"
        # Make the API request and get the response as text
        response_text = request(url)
        # If the database is a compound database, parse the response using the compound_parser function
        kegg_data = tuple_parser(response_text, url)
    elseif database in ["compound", "drug"]
        # Construct the URL for the API request
        url = "https://rest.kegg.jp/find/$database/$query/$option"
        # Make the API request and get the response as text
        response_text = request(url)
        # If the database is a compound database, parse the response using the compound_parser function
        kegg_data = tuple_parser(response_text, url)
    else
        # If the database is not a pathway database, print a message indicating that the requested list is not available
        print("The find route you are looking for is not available")
        # Return an empty array
        kegg_data = []
    end
    # Return the parsed data or an empty array if not available
    return kegg_data
end
