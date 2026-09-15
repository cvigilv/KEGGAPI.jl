## File to hold the types of the KEGG API

"""
    RequestError(message::String)

An error raised when a KEGG API request cannot be completed or returns a
non-successful HTTP status.

For transport, DNS, and TLS failures raised by [`request`](@ref), inspect
`Base.current_exceptions()` inside a `catch` block to access the original
exception.
"""
struct RequestError <: Exception
    message::String
end

Base.showerror(io::IO, exception::RequestError) = print(io, exception.message)

mutable struct KeggTupleList
    url::Union{String, Vector{String}}
    colnames::Vector{Union{String, Missing}}
    data::Vector{Any}
end

mutable struct KeggGenesList
    url::String
    colnames::Vector{String}
    data::Vector{Any}
end
