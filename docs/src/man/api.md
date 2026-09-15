# API reference

## KEGG operations

```@docs
KEGGAPI.kegg_info
KEGGAPI.kegg_list
KEGGAPI.kegg_find
KEGGAPI.kegg_get
KEGGAPI.kegg_conv
KEGGAPI.kegg_link
KEGGAPI.kegg_ddi
KEGGAPI.@kegg_str
```

## Low-level requests

`KEGGAPI.request` is not exported. Use the qualified name when calling a valid
KEGG endpoint that does not have a dedicated wrapper.

```@docs
KEGGAPI.request
```
