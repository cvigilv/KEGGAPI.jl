```@meta
CurrentModule = KEGGAPI
```
# KEGGAPI.jl

A Julia interface for the [KEGG API](https://www.kegg.jp/kegg/rest/keggapi.html).
The interface allows the functional annotation of genes, identification of metabolic processes
and pathways, the exploration of reaction/pathway prevalence at different taxonomic levels and
the identification of orthologous proteins for further analysis.

KEGGAPI.jl aims to support all KEGG API endpoints provided by the
["KEGGREST"](https://bioconductor.org/packages/release/bioc/html/KEGGREST.html) package for R
(Tenenbaum and maintainers, 2025) and the
["Bio.KEGG.REST"](https://biopython.org/docs/1.75/api/Bio.KEGG.REST.html) submodule from
Biopython for Python.
