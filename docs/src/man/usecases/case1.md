# Case 1: From a UniProt ID to KEGG information

This walkthrough starts from a protein identifier in an outside database
(UniProt / Swiss-Prot) and pulls together the corresponding KEGG gene, its
sequences, orthology group, reactions and pathways.

```@setup case1
using KEGGAPI
using DataFrames
```

## 1. Convert an outside identifier to a KEGG identifier

[`kegg_conv`](@ref) maps identifiers between KEGG and outside databases. Some
common gene / protein identifier prefixes are:

| Database        | Identifier prefix  |
|:----------------|:-------------------|
| UniProt         | `uniprot:`         |
| NCBI Gene       | `ncbi-geneid:`     |
| NCBI Protein    | `ncbi-proteinid:`  |
| KEGG genes      | `genes`            |

Only identifiers with a hit in KEGG are returned:

```@example case1
conv = KEGGAPI.kegg_conv("genes", "uniprot:A0A072UR65")
@assert conv isa KEGGAPI.KeggTupleList
DataFrame(conv.data, conv.colnames)
```

Several identifiers from the same database can be converted in one call by
passing a vector. KEGGAPI splits inputs longer than 10 entries into request
batches:

```@example case1
entries = ["uniprot:A0A072UR65", "uniprot:P12345"]
conv = KEGGAPI.kegg_conv("genes", entries)
@assert conv isa KEGGAPI.KeggTupleList
conv.url
```

The reverse direction (KEGG → outside database) works the same way:

```@example case1
conv = KEGGAPI.kegg_conv("ncbi-proteinid", "mtr:25493984")
@assert conv isa KEGGAPI.KeggTupleList
DataFrame(conv.data, conv.colnames)
```

## 2. Retrieve the gene entry

Use [`kegg_get`](@ref) to fetch the full flat-file entry for a KEGG gene. A
single entry is returned as a `String` in the `.data` field:

```@example case1
gene = KEGGAPI.kegg_get("mtr:25493984")
@assert gene.url isa String && gene.data isa String
println(join(first(split(gene.data, "\n"), 8), "\n"))
```

## 3. Download sequences

`kegg_get` can return amino-acid (`:aaseq`) or nucleotide (`:ntseq`) FASTA
sequences. For vector input, `.data` holds one FASTA record per requested entry:

```@example case1
seqs = KEGGAPI.kegg_get(["mtr:25493984", "shz:shn_30305"], :aaseq)
@assert length(seqs.data) == 2 && all(startswith(">"), seqs.data)
first(split(first(seqs.data), '\n'))
```

Write the records with `write("aaseq.fasta", join(seqs.data, '\n'))` or pass
them to a FASTA package.

## 4. Orthology, reactions and pathways

[`kegg_link`](@ref) finds cross-references between databases. The orthology (KO)
group for the gene:

```@example case1
ko = KEGGAPI.kegg_link("ko", "mtr:25493984")
@assert ko isa KEGGAPI.KeggTupleList
DataFrame(ko.data, ko.colnames)
```

Reactions associated with that ortholog:

```@example case1
rxns = KEGGAPI.kegg_link("reaction", "K01183")
@assert rxns isa KEGGAPI.KeggTupleList
DataFrame(rxns.data, rxns.colnames)
```

Pathways the gene participates in:

```@example case1
paths = KEGGAPI.kegg_link("pathway", "mtr:25493984")
@assert paths isa KEGGAPI.KeggTupleList
DataFrame(paths.data, paths.colnames)
```

## 5. All genes in an orthology group

The same `kegg_link` call, targeting `genes`, expands an orthology group into
every member gene across organisms:

```@example case1
ko_genes = KEGGAPI.kegg_link("genes", "K01183")
@assert ko_genes isa KEGGAPI.KeggTupleList
first(DataFrame(ko_genes.data, ko_genes.colnames), 5)
```

The second column of `ko_genes.data` is a vector of gene identifiers that can be
fed straight back into `kegg_get(...; :aaseq)` or `:ntseq` to build, for example,
a multiple-sequence-alignment input.

## 6. Download a pathway map

The `:image` option returns the PNG bytes of a pathway map, which you can write
to disk and open with your favourite image viewer or `Images.jl`:

```@example case1
img = KEGGAPI.kegg_get("map00520", :image)
@assert img.data isa Vector{UInt8} && !isempty(img.data)
path = tempname()
bytes_written = open(path, "w") do io
    write(io, img.data)
end
rm(path)
bytes_written == length(img.data)
```
