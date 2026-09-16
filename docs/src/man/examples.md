# Examples

## `kegg_conv`

These examples call the [KEGG Conv](https://www.kegg.jp/kegg/rest/keggapi.html#conv)
operation. `kegg_conv` returns the request URL, column names, and data in a
`KeggTupleList`. Construct a `DataFrame` from `output.data` and
`output.colnames`:

```@setup examples
using KEGGAPI
using DataFrames
```

```@example examples
output = KEGGAPI.kegg_conv("genes", "ncbi-geneid:948364")
@assert output isa KEGGAPI.KeggTupleList
DataFrame(output.data, output.colnames)
```

```@example examples
output = KEGGAPI.kegg_conv("ncbi-geneid", "eco:b0002")
@assert output isa KEGGAPI.KeggTupleList
DataFrame(output.data, output.colnames)
```

```@example examples
output = KEGGAPI.kegg_conv("ncbi-proteinid", ["hsa:10458", "ece:Z5100"])
@assert output isa KEGGAPI.KeggTupleList
DataFrame(output.data, output.colnames)
```

```@example examples
output = KEGGAPI.kegg_conv("genes", "uniprot:P0A6F9")
@assert output isa KEGGAPI.KeggTupleList
DataFrame(output.data, output.colnames)
```
