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
using DataFrames
using Tables
```

And use the interfaces to query the KEGG API. For example, to list all organisms (genomes) in KEGG:
```@example examples
result = KEGGAPI.kegg_list("genome");
```
This returns a [`KeggTable`](@ref) with the request URL and named columns:

```@example examples
result.url
```

```@example examples
Tables.columnnames(result)
```

```@example examples
first(result.columns.id, 5)
```

`KeggTable` implements the Tables.jl interface. Packages such as DataFrames.jl
can consume it directly:

```@example examples
first(DataFrame(result), 5)
```

The old `result.data` and `result.colnames` properties are deprecated. They will
remain available through the 1.x releases to ease migration.

For more example usage, refer to the [examples](examples.md) page and the [API reference](api.md).
