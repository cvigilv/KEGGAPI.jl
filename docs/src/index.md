```@meta
CurrentModule = KEGGAPI
```
# KEGGAPI.jl

KEGGAPI.jl is a Julia client for the [KEGG REST API](https://www.kegg.jp/kegg/rest/keggapi.html).
It retrieves KEGG entries, sequences, images, database links, identifier conversions, and
drug-drug interactions.

## KEGG usage terms

KEGG makes its REST service at `rest.kegg.jp` available only for academic use by academic users.
Read KEGG's [REST restriction notice](https://www.kegg.jp/kegg/rest/) and
[legal terms](https://www.kegg.jp/kegg/legal.html), including its licensing requirements for
non-academic use.

KEGGAPI.jl's MIT license covers only the Julia client code. It does not grant any rights to KEGG
data or services.

Its endpoint coverage follows
[KEGGREST](https://bioconductor.org/packages/release/bioc/html/KEGGREST.html) for R
(Tenenbaum and maintainers, 2025) and
[Bio.KEGG.REST](https://biopython.org/docs/1.75/api/Bio.KEGG.REST.html) for Python.
