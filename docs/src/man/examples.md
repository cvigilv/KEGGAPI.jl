# Examples

## `kegg_conv`

These examples mirror the [KEGG Conv](https://www.kegg.jp/kegg/rest/keggapi.html#conv)
operation. Each call returns a [`KeggTable`](@ref) with request URL metadata and
named columns. DataFrames.jl consumes the result directly through Tables.jl.

```@setup examples
using KEGGAPI
using DataFrames
```

```@example examples
output = KEGGAPI.kegg_conv("eco", "ncbi-geneid")
first(DataFrame(output), 5)
```

```@example examples
output = KEGGAPI.kegg_conv("ncbi-geneid", "eco")
first(DataFrame(output), 5)
```

```@example examples
output = KEGGAPI.kegg_conv("ncbi-proteinid", "hsa:10458+ece:Z5100")
DataFrame(output)
```

```@example examples
output = KEGGAPI.kegg_conv("genes", "ncbi-geneid:948364")
DataFrame(output)
```
