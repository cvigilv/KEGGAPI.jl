"""
KEGGAPI.get(query, option) -> Vector

Get entries from across the KEGG database. The get function takes a vector of strings
and returns a vector containing the urls used and the data returned.

The get function will split the vector into groups of 10 and make a request for each chunk.

# Examples
```@example
using KEGGAPI
kegg_get_genes = 
    KEGGAPI.kegg_get(
        ["hsa:10458", "hsa:10458", "hsa:10458", "hsa:10458"], 
        "ntseq"
        );
first(kegg_get_genes)
kegg_get_compounds = 
KEGGAPI.kegg_get(
    ["C01290","G00092"]
    );
first(kegg_get_compounds)
```
"""
function kegg_get(query::Vector{String}, option::String = "")
    # This function retrieves a list of entries from a specific database from the KEGG API.

    # Set the chunk size for processing multiple elements in each request
    chunk_size = 10

    # Calculate the number of chunks needed to process all elements in the query
    query_elements = length(query)
    query_chunks = ceil(Int, query_elements / chunk_size)

    # Initialize arrays to store URLs and retrieved data
    urls = String[]
    data = String[]

    # Check if the option is "aaseq" or "ntseq"
    if option == "aaseq" || option == "ntseq"
        # If there are more than 10 queries, process in chunks
        if length(query) > 10
            for i in 1:query_chunks
                # Calculate start and end indices for the current chunk
                start_index = (i - 1) * chunk_size + 1
                end_index = min(i * chunk_size, query_elements)

                # Extract the current chunk of queries
                chunk = query[start_index:end_index]

                # Join the queries with "+" for URL construction
                chunk_query = join(chunk, "+")

                # Construct the URL for the API request
                url = "https://rest.kegg.jp/get/$chunk_query/$option"

                # Store the URL for reference
                push!(urls, url)

                # Request data from the URL
                response_text = request(url)

                # Process the response and extract data
                for datum in split(response_text, r"(\n>|^>)")[2:end]
                    datum = replace(datum, r"\n$" => "")
                    push!(data, ">" * datum)
                end

                # Introduce a delay before the next request
                sleep(0.1)
            end
        else
            # Process all queries without chunking
            chunk_query = join(query, "+")
            url = "https://rest.kegg.jp/get/$chunk_query/$option"
            response_text = request(url)
            push!(urls, url)
            for datum in split(response_text, r"(\n>|^>)")[2:end]
                datum = replace(datum, r"\n$" => "")
                push!(data, ">" * datum)
            end
        end
    else
        # Process non-"aaseq" and non-"ntseq" options
        if length(query) > 10
            for i in 1:query_chunks
                # Calculate start and end indices for the current chunk
                start_index = (i - 1) * chunk_size + 1
                end_index = min(i * chunk_size, query_elements)

                # Extract the current chunk of queries
                chunk = query[start_index:end_index]

                # Join the queries with "+" for URL construction
                chunk_query = join(chunk, "+")

                # Construct the URL for the API request
                url = "https://rest.kegg.jp/get/$chunk_query/$option"

                # Store the URL for reference
                push!(urls, url)

                # Request data from the URL
                response_text = request(url)

                # Process the response and extract data
                response_text2 = replace(response_text, r"\n///([^/]*)$" => "")
                for datum in split(response_text2, "\n///\n")
                    push!(data, datum)
                end

                # Introduce a delay before the next request
                sleep(0.1)
            end
        else
            # Process all queries without chunking
            chunk_query = join(query, "+")
            url = "https://rest.kegg.jp/get/$chunk_query/$option"
            response_text = request(url)
            push!(urls, url)
            response_text2 = replace(response_text, r"\n///([^/]*)$" => "")
            for datum in split(response_text2, "\n///\n")
                push!(data, datum)
            end
        end
    end

    # Combine URLs and data into a single array
    kegg_data = [urls, data]

    # Return the parsed data or an empty array if not available
    return kegg_data
end
