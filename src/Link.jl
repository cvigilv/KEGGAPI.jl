"""
    kegg_link(target_db::String, source_db::String)

Find related entries by using database cross-references.

The available KEGG databases are:

    pathway | brite   | module   | ko     | <org>    | vg     | vp     |
    ag      | genome  | compound | glycan | reaction | rclass | enzyme |
    network | variant | disease  | drug   | dgroup   | <outside_db>

and the available external databases are:

    pubmed | atc | jtc | ndc | yk

# Arguments
- `target_db::String`: Target database
- `source_db::String`: Source database

# Examples

# Extended help

This operation allows retrieval of cross-references within all KEGG databases, as well as
between KEGG databases and outside databases. It is useful for finding various relationships,
such as relationships between genes and pathways. This form allows retrieval of database to
database cross-references.
"""
function kegg_link(target_db::String, source_db::String)
    url = "https://rest.kegg.jp/link/$target_db/$source_db"
    response_text = request(url)
    kegg_data = conv_parser(response_text, url)
    return kegg_data
end

"""
    kegg_link(target_db::String, dbentries::Vector{String}; [timeout::Float64 = 0.4 ])

Find related entries by using database cross-references.

The available KEGG databases are:

    pathway | brite   | module   | ko     | <org>    | vg     | vp     |
    ag      | genome  | compound | glycan | reaction | rclass | enzyme |
    network | variant | disease  | drug   | dgroup   | <outside_db>

and the available external databases are:

    pubmed | atc | jtc | ndc | yk

# Arguments

- `target_db::String`, target database
- `dbentries::Vector{String}`, KEGG database entries of the available databases
- `timeout::Float64`, time to wait between requests (default: 0.4 seconds)
"""
function kegg_link(target_db::String, dbentries::Vector{String}; timeout::Float64 = 0.4)
    urls = String[]
    data = []
    for chunk in chunk_vector(dbentries, 10)
        url = "https://rest.kegg.jp/link/$(target_db)/$(join(chunk, "+"))"
        push!(urls, url)
        response_text = request(url)
        for datum in eachline(IOBuffer(response_text))
            id, d = split(datum, '\t') .|> String
            push!(data, [id, d])
        end
        sleep(timeout)
    end
    return KeggTupleList(urls, ["source", target_db], data)
end
