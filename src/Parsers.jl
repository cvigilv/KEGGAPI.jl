function tabular_rows(response_text::String)
    data = Any[]
    for line in eachline(IOBuffer(response_text))
        isempty(line) && continue
        push!(data, String.(split(line, '\t')))
    end
    return data
end

function validate_row_width(data::Vector{Any}, column_count::Int)
    for (index, row) in pairs(data)
        length(row) == column_count || throw(
            RequestError(
                "KEGG returned $(length(row)) fields in row $index; expected $column_count"
            )
        )
    end
    return data
end

function inferred_colnames(column_count::Int)
    column_count == 0 && return Union{String, Missing}[]
    column_count == 1 && return Union{String, Missing}["ID"]
    column_count == 2 && return Union{String, Missing}["ID", "Details"]
    return Union{String, Missing}["ID"; fill(missing, column_count - 1)]
end

function tuple_parser(response_text::String, url::String)
    data = tabular_rows(response_text)
    column_count = isempty(data) ? 0 : length(first(data))
    validate_row_width(data, column_count)
    return KeggTupleList(url, inferred_colnames(column_count), data)
end

function tuple_parser(response_text::String, url::String, colnames::Vector{String})
    data = tabular_rows(response_text)
    validate_row_width(data, length(colnames))
    return KeggTupleList(url, colnames, data)
end

function pathway_parser(response_text::String, url::String)
    colnames = ["ID", "Pathway"]
    return tuple_parser(response_text, url, colnames)
end

function conv_parser(response_text::String, url::String)
    # KEGG response rows contain the source identifier before the target identifier.
    colnames = ["Source ID", "Target ID"]
    return tuple_parser(response_text, url, colnames)
end

function ddi_parser(response_text::String, url::Union{String, Vector{String}})
    colnames = ["Entry 1", "Entry 2", "Interaction Type", "Mechanism"]
    data = tabular_rows(response_text)
    validate_row_width(data, length(colnames))
    return KeggTupleList(url, colnames, data)
end

function genomic_feature_parser(response_text::String, url::String)
    colnames = ["ID", "Type", "Chromosomal Position", "Gene Name"]
    data = tabular_rows(response_text)
    validate_row_width(data, length(colnames))
    return KeggGenesList(url, colnames, data)
end
