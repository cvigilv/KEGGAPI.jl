## Types returned by the KEGG API

"""
    RequestError(message::String)

An error reported while requesting data from the KEGG REST API.
"""
struct RequestError <: Exception
    message::String
end

"""
    KeggTupleList(url, colnames, data)

A tabular KEGG result and the URL or URLs used to retrieve it.

`colnames` identifies the fields in each row; `missing` marks fields without a
stable label. `data` is a vector of rows, and every row stores one string for
each entry in `colnames`. The result supports iteration, indexing, and the usual
length queries by delegating to `data`.
"""
mutable struct KeggTupleList
    url::Union{String, Vector{String}}
    colnames::Vector{Union{String, Missing}}
    data::Vector{Any}
end

"""
    KeggGenesList(url, colnames, data)

A genomic-feature result returned by `kegg_list(query, "genes")`.

`colnames` names the fields in each row. `data` is a vector of rows, and every
row stores one string for each entry in `colnames`. The result supports
iteration, indexing, and the usual length queries by delegating to `data`.
"""
mutable struct KeggGenesList
    url::String
    colnames::Vector{String}
    data::Vector{Any}
end

const KeggList = Union{KeggTupleList, KeggGenesList}

# issue #24: every tabular result exposes rows through the same native interface.
Base.length(result::KeggList) = length(result.data)
Base.isempty(result::KeggList) = isempty(result.data)
Base.firstindex(result::KeggList) = firstindex(result.data)
Base.lastindex(result::KeggList) = lastindex(result.data)
Base.getindex(result::KeggList, index::Int) = result.data[index]
Base.iterate(result::KeggList) = iterate(result.data)
Base.iterate(result::KeggList, state::Int) = iterate(result.data, state)
