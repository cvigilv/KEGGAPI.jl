# Examples

## `kegg_conv`

These examples mirror the [KEGG Conv](https://www.kegg.jp/kegg/rest/keggapi.html#conv)
operation. Each call returns a [`KeggTupleList`](@ref). Its `data` field stores
rows, and `colnames` names each field in those rows.

```@setup examples
using KEGGAPI
using DataFrames

function as_dataframe(result)
    matrix = reduce(vcat, permutedims.(result.data))
    return DataFrame(matrix, Symbol.(result.colnames))
end
```

Database-to-database conversion results can be indexed and iterated directly:

```@example examples
output = KEGGAPI.kegg_conv("eco", "ncbi-geneid");
first(output, 5)
```

Convert the same native rows to a data frame when needed:

```@example examples
output = KEGGAPI.kegg_conv("ncbi-geneid", "eco");
first(as_dataframe(output), 5)
```

A vector selects particular database entries:

```@example examples
output = KEGGAPI.kegg_conv("ncbi-proteinid", ["hsa:10458", "ece:Z5100"]);
as_dataframe(output)
```

The `genes` target accepts outside gene identifiers:

```@example examples
output = KEGGAPI.kegg_conv("genes", "ncbi-geneid:948364");
as_dataframe(output)
```
