function tabular_parser(response_text::String, url, column_names::Tuple{Vararg{Symbol}})
    columns = ntuple(_ -> String[], length(column_names))

    for line in eachline(IOBuffer(response_text))
        fields = split(line, '\t')
        length(fields) == length(columns) || continue
        for i in eachindex(columns)
            push!(columns[i], fields[i])
        end
    end

    return KeggTable(url, NamedTuple{column_names}(columns))
end

function tuple_parser(response_text::String, url)
    return tabular_parser(response_text, url, (:id, :details))
end

function pathway_parser(response_text::String, url)
    return tabular_parser(response_text, url, (:id, :pathway))
end

function conv_parser(response_text::String, url)
    # KEGG returns the source identifier first and the target identifier second.
    return tabular_parser(response_text, url, (:source_id, :target_id))
end

function ddi_parser(response_text::String, url)
    return tabular_parser(
        response_text,
        url,
        (:entry1, :entry2, :interaction_type, :mechanism)
    )
end

function genomic_feature_parser(response_text::String, url)
    return tabular_parser(
        response_text,
        url,
        (:id, :type, :chromosomal_position, :gene_name)
    )
end
