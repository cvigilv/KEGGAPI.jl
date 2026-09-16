# Getting started with KEGGAPI.jl

## Installation

From the Julia REPL, type `]` to enter the Pkg REPL and install KEGGAPI.jl:

```
pkg> add KEGGAPI
```

## Usage

Load KEGGAPI.jl with `using`:

```@setup examples
using KEGGAPI
```

Each wrapper is named after its KEGG operation. This call lists all organisms in
KEGG:

```@example examples
result = KEGGAPI.kegg_list("genome")
@assert result isa KEGGAPI.KeggTupleList
nothing # hide
```

The result contains the request URL, column names, and data:

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

See [Examples](examples.md) for more calls and [API reference](api.md) for the full interface.
