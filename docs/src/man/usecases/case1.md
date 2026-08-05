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
DataFrame(conv.data, conv.colnames)
```

Several identifiers from the same database can be converted in one call by
passing a vector (for example a column read from a CSV file with `CSV.jl`). The
input is automatically split into chunks of 10 to respect the KEGG rate limit:

```julia
using CSV

df = DataFrame(CSV.File("subset_data.csv"))
entries = string.("uniprot:", df.Entry)
conv = KEGGAPI.kegg_conv("genes", entries)
DataFrame(conv.data, conv.colnames)
```

The reverse direction (KEGG → outside database) works the same way:

```@example case1
conv = KEGGAPI.kegg_conv("ncbi-proteinid", "mtr:25493984")
DataFrame(conv.data, conv.colnames)
```

## 2. Retrieve the gene entry

Use [`kegg_get`](@ref) to fetch the full flat-file entry for a KEGG gene. A
single entry is returned as a `String` in the `.data` field:

```@example case1
gene = KEGGAPI.kegg_get("mtr:25493984")
println(join(first(split(gene.data, "\n"), 8), "\n"))
```

## 3. Download sequences

`kegg_get` can return amino-acid (`:aaseq`) or nucleotide (`:ntseq`) FASTA
sequences. `.data` holds one FASTA record per requested entry, which you can
write to a file (e.g. with `FastaIO.jl`):

```julia
using FastaIO

seqs = KEGGAPI.kegg_get(["mtr:25493984", "shz:shn_30305"], :aaseq)
FastaWriter("aaseq.fasta") do fw
    for record in seqs.data
        write(fw, record)
    end
end
```

## 4. Orthology, reactions and pathways

[`kegg_link`](@ref) finds cross-references between databases. The orthology (KO)
group for the gene:

```@example case1
ko = KEGGAPI.kegg_link("ko", "mtr:25493984")
DataFrame(ko.data, ko.colnames)
```

Reactions associated with that ortholog:

```@example case1
rxns = KEGGAPI.kegg_link("reaction", "K01183")
DataFrame(rxns.data, rxns.colnames)
```

Pathways the gene participates in:

```@example case1
paths = KEGGAPI.kegg_link("pathway", "mtr:25493984")
DataFrame(paths.data, paths.colnames)
```

## 5. All genes in an orthology group

The same `kegg_link` call, targeting `genes`, expands an orthology group into
every member gene across organisms:

```@example case1
ko_genes = KEGGAPI.kegg_link("genes", "K01183")
first(DataFrame(ko_genes.data, ko_genes.colnames), 5)
```

The second column of `ko_genes.data` is a vector of gene identifiers that can be
fed straight back into `kegg_get(...; :aaseq)` or `:ntseq` to build, for example,
a multiple-sequence-alignment input.

## 6. Download a pathway map

The `:image` option returns the PNG bytes of a pathway map, which you can write
to disk and open with your favourite image viewer or `Images.jl`:

```julia
img = KEGGAPI.kegg_get("map00520", :image)
open("map00520.png", "w") do io
    write(io, img.data)
end
```
