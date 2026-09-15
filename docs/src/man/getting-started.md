# Getting started with KEGGAPI.jl

## Installation

KEGGAPI.jl can be installed using the Julia package manager.
From the Julia REPL, type `]` to enter the Pkg REPL mode and run

```
pkg> add KEGGAPI
```

## Usage

Load KEGGAPI.jl with `using`:

```@setup examples
using KEGGAPI
```

Then call a wrapper for the KEGG operation you need. For example, list all
organisms in KEGG:

```@example examples
result = KEGGAPI.kegg_list("genome")
@assert result isa KEGGAPI.KeggTupleList
nothing # hide
```

This returns a `KeggTupleList` containing the request URL, column names, and data.
Access them through the corresponding fields:
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
