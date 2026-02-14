# Examples

## KEGGAPI.conv

Examples analogous to [KEGG Conv](https://www.kegg.jp/kegg/rest/keggapi.html#conv)

Querying the API for a simple conversion returns a list with:
1. The API call
2. The column headers of the call ( if the result is tabular )
3. The data

This allows to easily convert to a data frame:

```@setup examples
using KEGGAPI
using DataFrames
```

```@example examples
output = KEGGAPI.conv("eco", "ncbi-geneid"); 
first(DataFrame(
  output.data,
  output.colnames
), 5)
```

```@example examples
output = KEGGAPI.conv("ncbi-geneid", "eco");
first(DataFrame(
  output.data,
  output.colnames
), 5)
```

```@example examples
output = KEGGAPI.conv("ncbi-proteinid", "hsa:10458+ece:Z5100");
DataFrame(
  output.data,
  output.colnames
)
```

```@example examples
output = KEGGAPI.conv("genes", "ncbi-geneid:948364");
DataFrame(
  output.data,
  output.colnames
)
```
