using KEGGAPI
using Test

import HTTP

@testset "list parser" begin
    two_column = KEGGAPI.list_parser(
        "path:one\tFirst pathway\npath:two\tSecond pathway",
        "fixture://two-column"
    )
    @test two_column isa KEGGAPI.KeggTupleList
    @test isequal(two_column.colnames, ["ID", missing])
    @test two_column.data == [
        ["path:one", "First pathway"],
        ["path:two", "Second pathway"],
    ]

    multi_column = KEGGAPI.list_parser(
        "org:gene1\tCDS\t1:100..200\tGene one\n\norg:gene2\tRNA\t2:300..400\tGene two\n",
        "fixture://multi-column"
    )
    @test multi_column isa KEGGAPI.KeggGenesList
    @test multi_column.colnames == ["ID", "Type", "Chromosomal Position", "Gene Name"]
    @test multi_column.data == [
        ["org:gene1", "org:gene2"],
        ["CDS", "RNA"],
        ["1:100..200", "2:300..400"],
        ["Gene one", "Gene two"],
    ]

    for response in ("", "\n", "\n   \n\t\n")
        empty_result = KEGGAPI.list_parser(response, "fixture://empty")
        @test isempty(empty_result.colnames)
        @test isempty(empty_result.data)
    end
end

@testset "list request" begin
    requested_urls = String[]
    mock_request = function (url::String)
        push!(requested_urls, url)
        return "path:one\tFirst pathway\n"
    end

    result = KEGGAPI._kegg_list("pathway", "", mock_request)
    @test requested_urls == ["https://rest.kegg.jp/list/pathway"]
    @test result.url == "https://rest.kegg.jp/list/pathway"

    empty!(requested_urls)
    result = KEGGAPI._kegg_list("pathway", "hsa", mock_request)
    @test requested_urls == ["https://rest.kegg.jp/list/pathway/hsa"]
    @test result.url == "https://rest.kegg.jp/list/pathway/hsa"
end

@testset "split network writes" begin
    handler = function (stream::HTTP.Stream)
        HTTP.setstatus(stream, 200)
        HTTP.setheader(stream, "Transfer-Encoding" => "chunked")
        HTTP.startwrite(stream)
        write(stream, "path:one\tFirst")
        flush(stream)
        sleep(0.05)
        write(stream, " pathway\n")
        return nothing
    end

    server = HTTP.serve!(handler; listenany = true, stream = true, verbose = -1)
    fixture_url = "http://127.0.0.1:$(HTTP.port(server))/list"
    try
        fixture_request = function (url::String)
            return KEGGAPI.request(fixture_url)
        end
        result = KEGGAPI._kegg_list("pathway", "", fixture_request)
        @test result.data == [["path:one", "First pathway"]]
    finally
        close(server)
    end
end
