"""
    request(url::String [, T::Type = String]) -> T

Send a GET request to a KEGG API URL. This low-level function is an escape hatch
for valid KEGG endpoints that do not have a dedicated KEGGAPI.jl wrapper.

The default `T` is `String`. Pass `Vector{UInt8}` to return the response body as
raw bytes, for example when requesting an image. Other response types must be
constructible from a `Vector{UInt8}`.

This function uses HTTP.jl's exception behavior. Connection failures, including
DNS and TLS failures, throw `HTTP.Exceptions.ConnectError`. Failures while
sending a request or reading its response throw `HTTP.Exceptions.RequestError`,
timeouts throw `HTTP.Exceptions.TimeoutError`, and unsuccessful HTTP responses
throw `HTTP.Exceptions.StatusError`. The HTTP exceptions retain the underlying
error or response in their fields.

# Examples
```julia
text = request("https://rest.kegg.jp/info/kegg")
image = request("https://rest.kegg.jp/get/hsa00010/image", Vector{UInt8})
```

# Arguments
- `url::String`: A KEGG API URL.
- `T::Type`: The response body type. Defaults to `String`.

# Returns
- `T`: The response body converted to the requested type.

# Throws
- `HTTP.Exceptions.ConnectError`: If HTTP.jl cannot establish a connection.
- `HTTP.Exceptions.RequestError`: If HTTP.jl cannot send the request or read the response.
- `HTTP.Exceptions.TimeoutError`: If the request exceeds HTTP.jl's read timeout.
- `HTTP.Exceptions.StatusError`: If the server returns an unsuccessful status.
"""
request(url::String)::String = request(url, String)

function request(url::String, T::Type)::T
    response = get(url, verbose = false)
    return T(response.body)
end
