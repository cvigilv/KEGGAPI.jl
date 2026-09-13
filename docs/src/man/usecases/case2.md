# Case 2: EC reaction information in KEGG

Starting from an Enzyme Commission (EC) number, this walkthrough finds the
associated KEGG reactions, their compounds, and the orthology group.

```@setup case2
using KEGGAPI
using DataFrames

as_dataframe(result) = DataFrame(
    reduce(vcat, permutedims.(result.data)),
    Symbol.(result.colnames),
)
```

## 1. Reactions associated with an EC number

[`kegg_link`](@ref) takes the target database (`reaction`) and the EC number as
`ec:X.X.X.X`, and returns every reaction linked to that enzyme:

```@example case2
rxns = KEGGAPI.kegg_link("reaction", "ec:3.2.1.14")
as_dataframe(rxns)
```

## 2. Reaction information

The second field in each `rxns` row holds a reaction identifier (`rn:R…`). Pass
them to [`kegg_get`](@ref) to retrieve the full entries; `.data` is a vector with
one flat-file `String` per reaction:

```@example case2
info = KEGGAPI.kegg_get([row[2] for row in rxns])
println(join(first(split(info.data[1], "\n"), 6), "\n"))
```

## 3. Compounds involved in a reaction

```@example case2
cpds = KEGGAPI.kegg_link("compound", "rn:R01206")
as_dataframe(cpds)
```

Retrieve the compound entries the same way as the reactions:

```@example case2
cpd_info = KEGGAPI.kegg_get([row[2] for row in cpds])
println(join(first(split(cpd_info.data[1], "\n"), 6), "\n"))
```

## 4. Reaction image

The `:image` option returns the PNG bytes for a reaction, which you can save to
disk:

```julia
img = KEGGAPI.kegg_get("rn:R01206", :image)
open("R01206.png", "w") do io
    write(io, img.data)
end
```

## 5. Orthology group for a reaction

```@example case2
ko = KEGGAPI.kegg_link("ko", "rn:R01206")
as_dataframe(ko)
```
