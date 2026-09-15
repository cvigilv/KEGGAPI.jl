# Case 4: Target molecule information at KEGG

Starting from a target molecule name, this walkthrough finds the encoding gene
and then explores its orthology group, pathways and associated drugs.

```@setup case4
using KEGGAPI
using DataFrames
```

## 1. Find the gene for a target molecule

[`kegg_find`](@ref) with the `genes` database searches gene names and
descriptions. A popular target such as `CD19` matches many organisms, so we show
only the first few hits:

```@example case4
genes = KEGGAPI.kegg_find("genes", "CD19")
@assert genes isa KEGGAPI.KeggTupleList
first(DataFrame(genes.data, genes.colnames), 5)
```

## 2. Gene entry and orthology group

Retrieve the full entry for the human gene with [`kegg_get`](@ref):

```@example case4
gene = KEGGAPI.kegg_get("hsa:930")
@assert gene.url isa String && gene.data isa String
println(join(first(split(gene.data, "\n"), 8), "\n"))
```

Its orthology (KO) group via [`kegg_link`](@ref):

```@example case4
ko = KEGGAPI.kegg_link("ko", "hsa:930")
@assert ko isa KEGGAPI.KeggTupleList
DataFrame(ko.data, ko.colnames)
```

## 3. Pathways involving the molecule

```@example case4
paths = KEGGAPI.kegg_link("pathway", "hsa:930")
@assert paths isa KEGGAPI.KeggTupleList
DataFrame(paths.data, paths.colnames)
```

## 4. Drugs associated with the molecule

```@example case4
drugs = KEGGAPI.kegg_link("drug", "hsa:930")
@assert drugs isa KEGGAPI.KeggTupleList
DataFrame(drugs.data, drugs.colnames)
```

Retrieve information on the associated drugs by passing their identifiers (the
second column of `drugs.data`) to `kegg_get`:

```@example case4
drug_info = KEGGAPI.kegg_get(drugs.data[2])
@assert drug_info.url isa Vector{String} && all(item -> item isa String, drug_info.data)
println(join(first(split(drug_info.data[1], "\n"), 6), "\n"))
```

## 5. Download a pathway map

```@example case4
img = KEGGAPI.kegg_get("hsa04151", :image)
@assert img.data isa Vector{UInt8} && !isempty(img.data)
path = tempname()
bytes_written = open(path, "w") do io
    write(io, img.data)
end
rm(path)
bytes_written == length(img.data)
```
