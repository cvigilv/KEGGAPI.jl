function tuple_parser(response_text::String, url::String)
    # Split the response into lines
    lines = split(response_text, "\n")
    # initialize the arrays
    id = String[]
    name = String[]
    colnames = ["ID", "Details"]
    # loop through the lines and split them into fields
    for line in lines
        fields = split(line, "\t")
        length(fields) == 2 || continue  # Skip rows with less than 2 columns
        push!(id, fields[1])
        push!(name, fields[2])
    end

    kegg_data = KeggTupleList(url, colnames, [id, name])
    return kegg_data
end


function pathway_parser(response_text::String, url::String)
    # Split the response into lines
    lines = split(response_text, "\n")
    # initialize the arrays
    id = String[]
    name = String[]
    colnames = ["ID", "Pathway"]
    # loop through the lines and split them into fields
    for line in lines
        fields = split(line, "\t")
        length(fields) == 2 || continue  # Skip rows with less than 2 columns
        push!(id, fields[1])
        push!(name, fields[2])
    end

    kegg_data = KeggTupleList(url, colnames, [id, name])
    return kegg_data
end

function organism_parser(response_text::String, url::String)
    # Split the response into lines
    lines = split(response_text, "\n")
    # initialize the arrays
    tnumber = String[]
    organism = String[]
    species = String[]
    phylogeny = String[]
    colnames = ["T. number", "Organism", "Species", "Phylogeny"]
    # loop through the lines and split them into fields
    for line in lines
        fields = split(line, "\t")
        length(fields) == 4 || continue  # Skip rows with less than 4 columns
        push!(tnumber, fields[1])
        push!(organism, fields[2])
        push!(species, fields[3])
        push!(phylogeny, fields[4])
    end
    # return the organism list
    kegg_data_list = KeggOrganismList(url, colnames, [tnumber, organism, species, phylogeny])
    return kegg_data_list
end

function conv_parser(response_text::String, url::String)
    # Split the response into lines
    lines = split(response_text, "\n")
    # initialize the arrays
    target_ids = String[]
    source_ids = String[]
    colnames = ["Target ID", "Source ID"]
    # loop through the lines and split them into fields
    for line in lines
        fields = split(line, "\t")
        length(fields) == 2 || continue  # Skip rows with less than 4 columns
        push!(target_ids, fields[1])
        push!(source_ids, fields[2])
    end
    # return the converted list
    kegg_data_list = KeggTupleList(url, colnames, [target_ids, source_ids])
    return kegg_data_list
end

function genomic_feature_parser(response_text::String, url::String)
    # Split the response into lines
    lines = split(response_text, "\n")
    # initialize the arrays
    id = String[]
    type = String[]
    chromosomal_position = String[]
    gene_name = String[]
    colnames = ["ID", "Type", "Chromosomal Position", "Gene Name"]
    # loop through the lines and split them into fields
    for line in lines
        fields = split(line, "\t")
        length(fields) == 4 || continue  # Skip rows with less than 4 columns
        push!(id, fields[1])
        push!(type, fields[2])
        push!(chromosomal_position, fields[3])
        push!(gene_name, fields[4])
    end
    # return the converted list
    kegg_data_list = KeggGenesList(url, colnames, [id, type, chromosomal_position, gene_name])
    return kegg_data_list
end
