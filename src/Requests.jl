"""
    request(url::String [, T::Type = String]) -> T

Send a GET request to a KEGG API URL. This low-level function is an escape hatch
for valid KEGG endpoints that do not have a dedicated KEGGAPI.jl wrapper.

The default `T` is `String`. Pass `Vector{UInt8}` to return the response body as
raw bytes, for example when requesting an image. Other response types must be
constructible from a `Vector{UInt8}`.

Any non-2xx HTTP response or failure while sending the request throws a
[`RequestError`](@ref). For transport, DNS, and TLS failures, the original
exception remains available through `Base.current_exceptions()`.

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
- [`RequestError`](@ref): If the request fails or the server returns a non-2xx status.
"""
request(url::String)::String = request(url, String)

function request(url::String, T::Type)::T
    response = try
        get(url, status_exception = false, verbose = false)
    catch exception
        exception isa InterruptException && rethrow()
        throw(RequestError("Request to $url failed: $(sprint(showerror, exception))"))
    end

    if 200 <= response.status < 300
        return T(response.body)
    end

    throw(
        RequestError(
            "Request to $url failed with status code $(response.status). " *
                "Verify that the URL is a valid KEGG API endpoint."
        )
    )
end
