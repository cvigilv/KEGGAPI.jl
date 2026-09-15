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
@assert rxns isa KEGGAPI.KeggTupleList
DataFrame(rxns.data, rxns.colnames)
```

## 2. Reaction information

The second column of `rxns.data` holds the reaction identifiers (`rn:R…`). Pass
them to [`kegg_get`](@ref) to retrieve the full entries; `.data` is a vector with
one flat-file `String` per reaction:

```@example case2
info = KEGGAPI.kegg_get(rxns.data[2])
@assert info.url isa Vector{String} && all(item -> item isa String, info.data)
println(join(first(split(info.data[1], "\n"), 6), "\n"))
```

## 3. Compounds involved in a reaction

```@example case2
cpds = KEGGAPI.kegg_link("compound", "rn:R01206")
@assert cpds isa KEGGAPI.KeggTupleList
DataFrame(cpds.data, cpds.colnames)
```

Retrieve the compound entries the same way as the reactions:

```@example case2
cpd_info = KEGGAPI.kegg_get(cpds.data[2])
@assert cpd_info.url isa Vector{String} && all(item -> item isa String, cpd_info.data)
println(join(first(split(cpd_info.data[1], "\n"), 6), "\n"))
```

## 4. Reaction image

The `:image` option returns the PNG bytes for a reaction, which you can save to
disk:

```@example case2
img = KEGGAPI.kegg_get("rn:R01206", :image)
@assert img.data isa Vector{UInt8} && !isempty(img.data)
path = tempname()
bytes_written = open(path, "w") do io
    write(io, img.data)
end
rm(path)
bytes_written == length(img.data)
```

## 5. Orthology group for a reaction

```@example case2
ko = KEGGAPI.kegg_link("ko", "rn:R01206")
@assert ko isa KEGGAPI.KeggTupleList
DataFrame(ko.data, ko.colnames)
```
