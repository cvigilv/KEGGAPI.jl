# ---------------------------------------------------------------------------- Constants
# Known KEGG database names accepted by the `find` operation. Organism codes
# (`<org>`) are not enumerable here, so an unrecognized `database` only triggers
# a warning rather than an error (see `kegg_find`).
const KEGG_FIND_DATABASES = Set(
    [
        "kegg", "pathway", "brite", "module", "ko", "genes", "ag", "vg", "vp",
        "genome", "vtax", "vgenome", "compound", "glycan", "reaction", "rclass",
        "rmodule", "enzyme", "network", "ntmap", "variant", "disease", "drug",
        "dgroup",
    ]
)

# Options accepted by `find` and the databases they apply to.
const KEGG_FIND_OPTIONS = ["formula", "exact_mass", "mol_weight", "nop"]
const KEGG_FIND_OPTION_DATABASES = ("compound", "drug")

"""
    kegg_find(database::String, query::String, option::String = "") -> KeggTupleList

Find entries with a matching query keyword or other query data.

Allowed `database` values are:

```text
kegg    | pathway | brite    | module | ko       | genes  | <org>  |
ag      | vg      | vp       | genome | vtax     | vgenome| compound|
glycan  | reaction| rclass   | rmodule| enzyme   | network| ntmap  |
variant | disease | drug     | dgroup
```

Allowed `option` values (only for the `compound` and `drug` databases):

    formula | exact_mass | mol_weight | nop

# Arguments
- `database::String`: The KEGG database to search.
- `query::String`: The query keyword or data. Spaces are converted to `+`.
- `option::String`: For the `compound`/`drug` databases, restrict the search to a
  chemical field. `nop` disables keyword pre-processing.

# Returns
- `KeggTupleList`: The matching identifiers and descriptions, with the request
  URL and column names.

# Examples
```jldoctest
julia> result = kegg_find("compound", "glucose");

julia> result isa KEGGAPI.KeggTupleList && result.colnames == ["ID", "Details"] && !isempty(result.data)
true
```

# Extended help

`kegg_find` searches a KEGG database for entries that match `query`. For
`compound` and `drug`, use `option` to search by `formula`, `exact_mass`, or
`mol_weight`. Specify a range with a hyphen, as in `"300-310"`. The `nop` option
disables keyword preprocessing. The function accepts recognized KEGG databases
and organism codes. It warns about other database names before passing them to
the API.

# Reference

- https://www.kegg.jp/kegg/rest/keggapi.html#find
"""
function kegg_find(database::String, query::String, option::String = "")
    # Normalize the query keyword for the URL.
    query = replace(query, " " => "+")

    if option != ""
        database in KEGG_FIND_OPTION_DATABASES || throw(
            ArgumentError(
                "The `option` argument is only available for the $(join(KEGG_FIND_OPTION_DATABASES, " and ")) databases"
            )
        )
        option in KEGG_FIND_OPTIONS || throw(
            ArgumentError("Invalid option '$option'. Valid options are: $(join(KEGG_FIND_OPTIONS, ", "))")
        )
        url = "https://rest.kegg.jp/find/$database/$query/$option"
    else
        database in KEGG_FIND_DATABASES ||
            @warn "'$database' is not a recognized KEGG database name; passing it through to the API anyway."
        url = "https://rest.kegg.jp/find/$database/$query"
    end

    response_text = request(url)
    return tuple_parser(response_text, url)
end
