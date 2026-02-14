# Getting started with KEGGAPI.jl

## Installation

KEGGAPI.jl can be installed using the Julia package manager.
From the Julia REPL, type `]` to enter the Pkg REPL mode and run

```
pkg> add https://github.com/cvigilv/KEGGAPI.jl
```

## Usage

To use KEGGAPI.jl, simply import the package:

```@setup examples
using KEGGAPI
```

And use the interfaces to query the KEGG API. For example, to list all organisms in KEGG:
```@example examples
result = KEGGAPI.list("organism");
```
This returns a `KeggOrganismList` object with the API call, column names and data. The data can
accessed by indexing into the respective fields of the object:
```@example examples
result.url
```

```@example examples
result.colnames
```

```@example examples
result.data
```

For more example usage, refer to the [examples](examples.md) page and the [API reference](api.md).
