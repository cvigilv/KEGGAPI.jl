# Getting started with KEGGAPI.jl

## Installation

KEGGAPI.jl can be installed using the Julia package manager.
From the Julia REPL, type `]` to enter the Pkg REPL mode and run

```
pkg> add KEGGAPI
```

## Usage

To use KEGGAPI.jl, simply import the package:

```@setup examples
using KEGGAPI
```

And use the interfaces to query the KEGG API. For example, to list all organisms (genomes) in KEGG:
```@example examples
result = KEGGAPI.kegg_list("genome");
```
This returns a [`KeggTupleList`](@ref) with the request URL, column names, and
result rows. Each row has one value for every entry in `colnames`:
```@example examples
result.url
```

```@example examples
result.colnames
```

```@example examples
first(result)
```

The full row vector remains available through `result.data`. `KeggTupleList`
also supports iteration, indexing, `length`, and `isempty` directly.

For more example usage, refer to the [examples](examples.md) page and the [API reference](api.md).
