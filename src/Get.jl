# ---------------------------------------------------------------------------- Constants
const KEGGAPI_GET_OPTIONS = Union{Symbol, Nothing}[
    :aaseq,
    :ntseq,
    :mol,
    :kcf,
    :image,
    :image2x,
    :conf,
    :kgml,
    :json,
    nothing,
]

# Options whose response body is binary (image files)
const KEGGAPI_GET_BINARY_OPTIONS = (:image, :image2x)

validate_get_option(option) = option in KEGGAPI_GET_OPTIONS || throw(ArgumentError("Invalid option. Valid options are: $(KEGGAPI_GET_OPTIONS)"))

# ---------------------------------------------------------------------------- Helpers
function build_kegg_url(chunk::AbstractVector{String}, option::Union{Symbol, Nothing})
    chunk_query = join(chunk, "+")
    option_str = isnothing(option) ? "" : "/$option"
    return "https://rest.kegg.jp/get/$chunk_query$option_str"
end

# ---------------------------------------------------------------------------- Parsers
function parse_as_bioseq(response_text::String)
    return [">" * strip(d) for d in split(response_text, r"(\n>|^>)")[2:end]]
end

function parse_as_mol(response_text::String)
    return [d for d in split(response_text, r"\$\$\$\$")[begin:(end - 1)]] .|> String
end

function parse_as_text(response_text::String)
    response_text2 = replace(response_text, r"\n///([^/]*)$" => "")
    return split(response_text2, "\n///\n") .|> strip .|> String
end

function parse_as_image(response_text::Vector)
    return [UInt8.(response_text)]
end

RESPONSE_PROCESSORS = Dict(
    :aaseq => parse_as_bioseq,
    :ntseq => parse_as_bioseq,
    :mol => parse_as_mol,
    :default => parse_as_text,
    :image => parse_as_image,
    :image2x => parse_as_image
)

# HACK: this is a workaround as get(option::Symbol, lookup::Dict{Symbol, Function},
# default::Function) is not supported. This should change once it's supported.
function get_response_processor(option::Symbol)
    if haskey(RESPONSE_PROCESSORS, option)
        return RESPONSE_PROCESSORS[option]
    else
        return RESPONSE_PROCESSORS[:default]
    end
end

function get_response_processor(option::Nothing)
    return RESPONSE_PROCESSORS[:default]
end

# ---------------------------------------------------------------------------- Main function
"""
    kegg_get(dbentries::Vector{String}, option::Union{Symbol, Nothing} = nothing; request_delay::Real = 0.4, timeout = nothing) -> NamedTuple
    kegg_get(dbentry::String, option::Union{Symbol, Nothing} = nothing; request_delay::Real = 0.4, timeout = nothing) -> NamedTuple

Retrieve given database entries.

Allowed `dbentries` (database entries):

```txt
pathway   | brite    | module   | ko       | <org>    | ag         | vg      |
vp        | genome   | vtax     | vgenome  | compound | glycan     | reaction|
rclass    | rmodule  | enzyme   | network  | ntmap    | variant    | disease |
drug      | dgroup   | disease_ja| drug_ja | dgroup_ja| compound_ja
```

Allowed `option` for retrieval of selected fields:

    :aaseq | :ntseq | :mol | :kcf | :image | :image2x | :conf | :kgml | :json | nothing

# Arguments
- `dbentries::Vector{String}`: A vector of KEGG database entries to retrieve.
- `option::Union{Symbol, Nothing}`: An optional symbol specifying the format of the
  retrieved data. If `nothing`, the default format is used.
- `request_delay::Real`: Seconds to wait between batched requests. Defaults to
  0.4. No delay occurs when the input fits in one request.
- `timeout::Real`: Deprecated alias for `request_delay`. If both keywords are
  supplied, their values must be equal.

# Throws
- `ArgumentError`: If a delay is negative or non-finite, or if `request_delay`
  and `timeout` conflict.

# Returns
- For vector input, a named tuple `(url = urls, data = data)`. `urls` is a
  `Vector{String}` containing one URL per request batch. `data` is a vector with
  one processed result per retrieved entry.
- For scalar input, a named tuple `(url = url, data = data)`. `url` is the single
  request URL. `data` is a `String` for text and sequence formats and a
  `Vector{UInt8}` for `:image` and `:image2x`.

# Examples
```jldoctest
julia> result = kegg_get(["hsa:10458", "hsa:10459"], :aaseq);

julia> (result.url isa Vector{String}, length(result.data), all(item -> item isa String, result.data))
(true, 2, true)

julia> result = kegg_get("hsa:10458");

julia> (result.url isa String, result.data isa String)
(true, true)
```

# Extended help

This operation retrieves given database entries in a flat file format or in other
formats with `option`. Flat file formats are available for all KEGG databases
except brite. The input is limited up to 10 entries; if more are provided the
query is split into chunks of 10 entries. The function waits `request_delay`
seconds between requests, but does not wait after the final request. The default
of 0.4 seconds keeps batched calls below KEGG's limit of three requests per
second.

Options allow retrieval of selected fields, including sequence data from genes
entries, chemical structure data or GIF image files from compound, glycan and
drug entries, PNG image files or KGML files from pathway entries. The `:image2x`
option retrieves the doubled-size PNG image of a reference pathway map.

The input is limited to **one compound/glycan/drug entry with the `:image` option**,
and to **one pathway entry with the `:image`, `:image2x` or `:kgml` option**.

# Reference

- https://www.kegg.jp/kegg/rest/keggapi.html#get

"""
function kegg_get(
        dbentries::Vector{String}, option::Union{Symbol, Nothing} = nothing;
        request_delay::Union{Nothing, Real} = nothing,
        timeout::Union{Nothing, Real} = nothing,
    )
    return _kegg_get(dbentries, option, request, sleep; request_delay, timeout)
end

function _kegg_get(
        dbentries::Vector{String}, option::Union{Symbol, Nothing}, requester::F,
        sleep_function::S; request_delay::Union{Nothing, Real} = nothing,
        timeout::Union{Nothing, Real} = nothing,
    ) where {F, S}
    validate_get_option(option)
    request_count = cld(length(dbentries), KEGG_BATCH_SIZE)
    delay = resolve_request_delay(request_delay, timeout, :kegg_get, request_count)
    length(dbentries) > 1 && option == :image && @warn "Using the :image option with kegg_get is limited to one compound/glycan/drug entry"

    urls = String[]
    data = []
    processor = get_response_processor(option)

    foreach_request_batch(dbentries, delay, sleep_function) do chunk
        url = build_kegg_url(chunk, option)
        push!(urls, url)
        response_text = option in KEGGAPI_GET_BINARY_OPTIONS ? requester(url, Vector{UInt8}) : requester(url)
        for datum in processor(response_text)
            push!(data, datum)
        end
    end

    return (url = urls, data = data)
end

function kegg_get(dbentry::String, args...; kwargs...)
    r = kegg_get([dbentry], args...; kwargs...)
    return (url = only(r.url), data = only(r.data))
end

"""
    @kegg_str -> NamedTuple

Macro to retrieve a KEGG database entry flat file from a string. This is intended
for interactive use in the REPL.

See [`kegg_get`](@ref) for more details on allowed database entries.

# Returns
- `NamedTuple`: The same `(url = url, data = data)` result as scalar
  [`kegg_get`](@ref).

# Example
```jldoctest
julia> entry = kegg"hsa:10458";

julia> (entry.url isa String, entry.data isa String)
(true, true)
```
"""
macro kegg_str(dbentry)
    return :(kegg_get($(esc(dbentry))))
end
