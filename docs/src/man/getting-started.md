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
This returns a `KeggTupleList` object with the API call, column names and data. The data can
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

## Error handling

KEGGAPI lets HTTP.jl exceptions propagate. An unsuccessful HTTP response throws
`HTTP.Exceptions.StatusError`. Connection, request, and timeout failures throw
`HTTP.Exceptions.ConnectError`, `HTTP.Exceptions.RequestError`, and
`HTTP.Exceptions.TimeoutError`, respectively. See [`KEGGAPI.request`](@ref) for
the low-level request contract.

For more example usage, refer to the [examples](examples.md) page and the [API reference](api.md).
