"""
    KEGGAPI.kegg_info(database::String)

Get information about a specific database from the KEGG API.

Allowed `database` values are:

```text
kegg     | pathway | brite   | module  | ko      | genes    | <org>   |
ag       | vg      | vp      | genome  | vtax    | vgenome  | ligand  |
compound | glycan  | reaction| rclass  | rmodule | enzyme   | network |
ntmap    | variant | disease | drug    | dgroup
```

# Arguments
- `database::String`: The KEGG database for which to retrieve information.

# Returns
- `data::String`: A string containing the information about the specified database.

# Example

```julia-repl
KEGGAPI.kegg_info("kegg")

# Extended help

This operation displays the database release information with statistics for the
databases shown in the table. Except for :kegg, :genes and :ligand, this operation
also retrieves the list of linked databases that can be used in the link operation.

# Reference

- https://www.kegg.jp/kegg/rest/keggapi.html#info
```
"""
function kegg_info(database::String)
    url = "https://rest.kegg.jp/info/$database"
    response_text = request(url)
    return response_text
end
