# ---------------------------------------------------------------------------- Constants
# Known KEGG database names accepted by the `find` operation. Organism codes
# (`<org>`) are not enumerable here, so an unrecognized `database` only triggers
# a warning rather than an error (see `kegg_find`).
const KEGG_FIND_DATABASES = Set([
    "kegg", "pathway", "brite", "module", "ko", "genes", "ag", "vg", "vp",
    "genome", "vtax", "vgenome", "compound", "glycan", "reaction", "rclass",
    "rmodule", "enzyme", "network", "ntmap", "variant", "disease", "drug",
    "dgroup",
])

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
- `data::KeggTupleList`: A data structure containing the `url`, the `data`
  retrieved, and the `colnames`.

# Examples
```julia
using KEGGAPI

KEGGAPI.kegg_find("compound", "glucose")
KEGGAPI.kegg_find("compound", "C7H10O5", "formula")
KEGGAPI.kegg_find("ko", "kinase")
```

# Extended help

This operation searches KEGG databases for entries matching the given query. The
`option` argument is only meaningful for chemical databases (`compound`, `drug`)
and is used to search by molecular `formula`, `exact_mass` or `mol_weight`
(ranges may be given with a minus sign, e.g. `"300-310"`); `nop` disables the
keyword pre-processing. Any recognized KEGG database (or an organism code) is
accepted; unrecognized database names emit a warning but are still passed through
to the API.

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
