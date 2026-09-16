"""
    kegg_info(database::String) -> String

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
- `String`: Database release information and statistics from KEGG.

# Example

```jldoctest
julia> info = kegg_info("kegg");

julia> occursin("KEGG", info)
true
```

# Extended help

`kegg_info` returns database release information and statistics. For databases
other than `kegg`, `genes`, and `ligand`, the response also lists databases that
can be passed to [`kegg_link`](@ref).

# Reference

- https://www.kegg.jp/kegg/rest/keggapi.html#info
"""
function kegg_info(database::String)
    url = "https://rest.kegg.jp/info/$database"
    response_text = request(url)
    return response_text
end
