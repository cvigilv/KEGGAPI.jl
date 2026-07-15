# Case 2: EC reaction information in KEGG

Starting from an Enzyme Commission (EC) number, this walkthrough finds the
associated KEGG reactions, their compounds, and the orthology group.

```@setup case2
using KEGGAPI
using DataFrames
```

## 1. Reactions associated with an EC number

[`kegg_link`](@ref) takes the target database (`reaction`) and the EC number as
`ec:X.X.X.X`, and returns every reaction linked to that enzyme:

```@example case2
rxns = KEGGAPI.kegg_link("reaction", "ec:3.2.1.14")
DataFrame(rxns.data, rxns.colnames)
```

## 2. Reaction information

The second column of `rxns.data` holds the reaction identifiers (`rn:R…`). Pass
them to [`kegg_get`](@ref) to retrieve the full entries; `.data` is a vector with
one flat-file `String` per reaction:

```@example case2
info = KEGGAPI.kegg_get(rxns.data[2])
println(join(first(split(info.data[1], "\n"), 6), "\n"))
```

## 3. Compounds involved in a reaction

```@example case2
cpds = KEGGAPI.kegg_link("compound", "rn:R01206")
DataFrame(cpds.data, cpds.colnames)
```

Retrieve the compound entries the same way as the reactions:

```@example case2
cpd_info = KEGGAPI.kegg_get(cpds.data[2])
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
DataFrame(ko.data, ko.colnames)
```
