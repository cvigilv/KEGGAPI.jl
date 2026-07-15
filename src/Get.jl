# ---------------------------------------------------------------------------- Constants
const KEGGAPI_GET_OPTIONS = Union{Symbol, Nothing}[
    :aaseq,
    :ntseq,
    :mol,
    :kcf,
    :image,
    :conf,
    :kgml,
    :json,
    nothing,
]

validate_get_option(option) = option in KEGGAPI_GET_OPTIONS || throw(ArgumentError("Invalid option. Valid options are: $(KEGGAPI_GET_OPTIONS)"))

# ---------------------------------------------------------------------------- Helpers
function build_kegg_url(chunk::Vector{String}, option::Union{Symbol, Nothing})
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
    :image => parse_as_image
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
    kegg_get(dbentries::Vector{String}, option::Union{Symbol, Nothing} = nothing; timeout::Float64 = 0.4)
    kegg_get(dbentry::String, args...; kwargs...)

Retrieve given database entries.

Allowed `dbentries` (database entries):

```txt
pathway   | brite   | module   | ko     | <org>    | vg         | vp      |
ag        | genome  | compound | glycan | reaction | rclass     | enzyme  |
network   | variant | disease  | drug   | dgroup   | disease_ja | drug_ja |
dgroup_ja | compound_ja
```

Allowed `option` for retrieval of selected fields:

    :aaseq | :ntseq | :mol | :kcf | :image | :conf | :kgml | :json | nothing

# Arguments
- `dbentries::Vector{String}`: A vector of KEGG database entries to retrieve.
- `option::Union{Symbol, Nothing}`: An optional symbol specifying the format of the
  retrieved data. If `nothing`, the default format is used.
- `timeout::Float64`: A float specifying the time to wait between API requests when retrieving
  more than 10 entries. Default is 0.4 seconds.

# Returns
A tuple containing:
- `url::Vector{String}`: A vector of URLs used for the API requests.
- `data::Vector{Any}`: A vector of retrieved data corresponding to the provided database
  entries, processed according to the specified `option`.

# Example
```julia-repl
dbentries = ["hsa:10458", "hsa:10459", "hsa:10460"]
option = :aaseq
urls, data = kegg_get(dbentries, option)
```

# Extended help

This operation retrieves given database entries in a flat file format or in other
formats with `option`. Flat file formats are available for all KEGG databases
except brite. The input is limited up to 10 entries; if more are provided the
query will be split into chunks of 10 entries and multiple requests will be made
with a `timeout` between each request (KEGG API indicates that the maximum API
calls per seconds is 3, so a default timeout of 0.4 seconds is set to ensure that).

Options allow retrieval of selected fields, including sequence data from genes
entries, chemical structure data or GIF image files from compound, glycan and
drug entries, PNG image files or KGML files from pathway entries.

The input is limited to **one compound/glycan/drug entry with the `:image` option**,
and to **one pathway entry with the `:image` or `:kgml` option**.

# Reference

- https://www.kegg.jp/kegg/rest/keggapi.html#get

"""
function kegg_get(dbentries::Vector{String}, option::Union{Symbol, Nothing} = nothing; timeout::Float64 = 0.4)
    validate_get_option(option)
    timeout < 0.334 && @warn "KEGG API accepts 3 requests per second. Current timeout may lead to API rate limit errors."
    length(dbentries) > 1 && option == :image && @warn "Using the :image option with kegg_get is limited to one compound/glycan/drug entry"

    urls = String[]
    data = []
    processor = get_response_processor(option)

    for chunk in chunk_vector(dbentries, 10)
        url = build_kegg_url(chunk, option)
        push!(urls, url)
        response_text = option == :image ? request_other(url) : request(url)
        for datum in processor(response_text)
            push!(data, datum)
        end
        sleep(timeout)
    end

    return (url = urls, data = data)
end

function kegg_get(dbentry::String, args...; kwargs...)
    r = kegg_get([dbentry], args...; kwargs...)
    if length(args) > 0 && args[1] == :image
        d = only(r.data)
    else
        d = only(r.data)
    end
    return (url = only(r.url), data = d)
end

"""
    @kegg_str

Macro to retrieve a KEGG database entry flat file from a string. This is intended
for interactive use in the REPL.

See [`kegg_get`](@ref) for more details on allowed database entries.

# Example
```julia
using KEGGAPI
entry = kegg"hsa:10458"
```
"""
macro kegg_str(dbentry)
    return :(kegg_get($(esc(dbentry))))
end
