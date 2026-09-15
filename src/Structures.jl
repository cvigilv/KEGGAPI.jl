## File to hold the types of the KEGG API

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
