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
DataFrame(hits.data, hits.colnames)
```

## 2. Retrieve the compound entry

The first column of `hits.data` holds the compound identifiers (`cpd:C…`). Fetch
the full entry with [`kegg_get`](@ref):

```@example case3
cpd = KEGGAPI.kegg_get("cpd:C00461")
println(join(first(split(cpd.data, "\n"), 8), "\n"))
```

## 3. Compound image

The `:image` option returns the PNG bytes of the compound structure, which you
can save to disk:

```julia
img = KEGGAPI.kegg_get("cpd:C00461", :image)
open("C00461.png", "w") do io
    write(io, img.data)
end
```

## 4. Reactions linked to the compound

[`kegg_link`](@ref) returns one row for every reaction the compound takes part
in:

```@example case3
rxns = KEGGAPI.kegg_link("reaction", "cpd:C00461")
DataFrame(rxns.data, rxns.colnames)
```

## 5. Reaction information

Feed the reaction identifiers (the second column of `rxns.data`) back into
`kegg_get` to retrieve their entries:

```@example case3
info = KEGGAPI.kegg_get(rxns.data[2])
println(join(first(split(info.data[1], "\n"), 6), "\n"))
```
