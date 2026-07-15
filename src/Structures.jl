## File to hold the types of the KEGG API

# This type is used to represent a KEGG API request error.
struct RequestError <: Exception
    message::String
end

mutable struct KeggTupleList
    url::Union{String, Vector{String}}
    colnames::Vector{Union{String, Missing}}
    data::Vector{Any}
end

mutable struct KeggOrganismList
    url::String
    colnames::Vector{String}
    data::Vector{Any}
end

mutable struct KeggGenesList
    url::String
    colnames::Vector{String}
    data::Vector{Any}
end
