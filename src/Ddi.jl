"""
    kegg_ddi(dbentry::String)
    kegg_ddi(dbentries::Vector{String})

Find adverse drug-drug interactions (DDI).

The available databases are:

    drug | ndc | yj

# Arguments
- `dbentry::String` / `dbentries::Vector{String}`: KEGG DRUG (`dr:`/`D` numbers),
  NDC or YJ code entries to query for interactions.

# Returns
- `data::KeggTupleList`: A data structure containing the `url`, the `data`
  retrieved, and the `colnames`. The columns are `["Entry 1", "Entry 2",
  "Interaction Type", "Mechanism"]`, where the interaction type is `CI`
  (contraindication) or `P` (precaution).

# Throws
- `ArgumentError`: If `dbentries` is empty

# Examples
```julia
using KEGGAPI

KEGGAPI.kegg_ddi("D00564")
KEGGAPI.kegg_ddi(["D00564", "D00100"])
```

# Extended help

This operation searches against the KEGG DDI database, which contains known
adverse drug-drug interactions. When multiple entries are given, all pairwise
interactions among them are also reported. Vector inputs must contain between one
and ten entries. Empty vectors and vectors with more than ten entries throw an
`ArgumentError` before a request is sent. Queries above the KEGG limit cannot be
split into independent requests because doing so would omit interactions between
entries in different requests.

# Reference

- https://www.kegg.jp/kegg/rest/keggapi.html#ddi
"""
function kegg_ddi(dbentries::Vector{String})
    return _kegg_ddi(dbentries, request)
end

function _kegg_ddi(dbentries::Vector{String}, requester::F) where {F}
    isempty(dbentries) && throw(ArgumentError("kegg_ddi requires at least one entry"))
    url = "https://rest.kegg.jp/ddi/$(join(dbentries, "+"))"
    response_text = requester(url)
    return ddi_parser(response_text, [url])
end

function kegg_ddi(dbentry::String)
    url = "https://rest.kegg.jp/ddi/$dbentry"
    response_text = request(url)
    return ddi_parser(response_text, url)
end
