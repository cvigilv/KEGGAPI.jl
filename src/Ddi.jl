"""
    kegg_ddi(dbentry::String)
    kegg_ddi(dbentries::Vector{String}; [timeout::Float64 = 0.4])

Find adverse drug-drug interactions (DDI).

The available databases are:

    drug | ndc | yj

# Arguments
- `dbentry::String` / `dbentries::Vector{String}`: KEGG DRUG (`dr:`/`D` numbers),
  NDC or YJ code entries to query for interactions.
- `timeout::Float64`: Time to wait between requests when more than 10 entries are
  provided (default: 0.4 seconds).

# Returns
- `data::KeggTupleList`: A data structure containing the `url`, the `data`
  retrieved, and the `colnames`. The columns are `["Entry 1", "Entry 2",
  "Interaction Type", "Mechanism"]`, where the interaction type is `CI`
  (contraindication) or `P` (precaution).

# Examples
```julia
using KEGGAPI

KEGGAPI.kegg_ddi("D00564")
KEGGAPI.kegg_ddi(["D00564", "D00100"])
```

# Extended help

This operation searches against the KEGG DDI database, which contains known
adverse drug-drug interactions. When multiple entries are given, all pairwise
interactions among them are also reported. The input is limited up to 10 entries;
if more are provided the query will be split into chunks of 10 entries and
multiple requests will be made with a `timeout` between each request (KEGG API
indicates that the maximum API calls per second is 3, so a default timeout of
0.4 seconds is set to ensure that).

# Reference

- https://www.kegg.jp/kegg/rest/keggapi.html#ddi
"""
function kegg_ddi(dbentries::Vector{String}; timeout::Float64 = 0.4)
    urls = String[]
    response_text = ""
    for chunk in chunk_vector(dbentries, 10)
        url = "https://rest.kegg.jp/ddi/$(join(chunk, "+"))"
        push!(urls, url)
        response_text *= request(url)
        sleep(timeout)
    end
    return ddi_parser(response_text, urls)
end

function kegg_ddi(dbentry::String)
    url = "https://rest.kegg.jp/ddi/$dbentry"
    response_text = request(url)
    return ddi_parser(response_text, url)
end
