# Case 3: Identifying a compound in KEGG

This walkthrough looks up a compound by name, retrieves its entry, and finds the
reactions it participates in.

```@setup case3
using KEGGAPI
using DataFrames
```

## 1. Find a compound by name

[`kegg_find`](@ref) searches a database by keyword. To look for a compound, pass
the `compound` database and the compound name:

```@example case3
hits = KEGGAPI.kegg_find("compound", "chitin")
@assert hits isa KEGGAPI.KeggTupleList
DataFrame(hits.data, hits.colnames)
```

## 2. Retrieve the compound entry

The first column of `hits.data` holds compound identifiers such as `cpd:C00461`.
Fetch the full entry with [`kegg_get`](@ref):

```@example case3
cpd = KEGGAPI.kegg_get("cpd:C00461")
@assert cpd.url isa String && cpd.data isa String
println(join(first(split(cpd.data, "\n"), 8), "\n"))
```

## 3. Compound image

The `:image` option returns the PNG bytes of the compound structure, which you
can save to disk:

```@example case3
img = KEGGAPI.kegg_get("cpd:C00461", :image)
@assert img.data isa Vector{UInt8} && !isempty(img.data)
path = tempname()
bytes_written = open(path, "w") do io
    write(io, img.data)
end
rm(path)
bytes_written == length(img.data)
```

## 4. Reactions linked to the compound

[`kegg_link`](@ref) returns the reactions that include the compound:

```@example case3
rxns = KEGGAPI.kegg_link("reaction", "cpd:C00461")
@assert rxns isa KEGGAPI.KeggTupleList
DataFrame(rxns.data, rxns.colnames)
```

## 5. Reaction information

Pass the reaction identifiers in the second column of `rxns.data` to `kegg_get`
to retrieve their entries:

```@example case3
info = KEGGAPI.kegg_get(rxns.data[2])
@assert info.url isa Vector{String} && all(item -> item isa String, info.data)
println(join(first(split(info.data[1], "\n"), 6), "\n"))
```
