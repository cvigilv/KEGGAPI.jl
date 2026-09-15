using KEGGAPI
using Test

import HTTP

@testset verbose = true "API" begin
    @testset "request" begin
        @test :request in names(KEGGAPI)
        @test :RequestError in names(KEGGAPI)

        binary_body = UInt8[0x89, 0x50, 0x4e, 0x47, 0x00, 0xff]
        handler = function (http_request::HTTP.Request)
            if http_request.target == "/text"
                return HTTP.Response(200, "fixture response")
            elseif http_request.target == "/binary"
                return HTTP.Response(200, binary_body)
            elseif http_request.target == "/empty"
                return HTTP.Response(204)
            end

            return HTTP.Response(503, "fixture unavailable")
        end

        server = HTTP.serve!(handler; listenany = true, verbose = -1)
        base_url = "http://127.0.0.1:$(HTTP.port(server))"
        try
            @test KEGGAPI.request("$base_url/text") == "fixture response"
            @test KEGGAPI.request("$base_url/binary", Vector{UInt8}) == binary_body
            @test KEGGAPI.request("$base_url/empty") == ""

            for response_type in (String, Vector{UInt8})
                status_error = try
                    KEGGAPI.request("$base_url/unavailable", response_type)
                catch exception
                    exception
                end
                @test status_error isa KEGGAPI.RequestError
                @test occursin("status code 503", status_error.message)
            end
        finally
            close(server)
        end

        transport_error = try
            KEGGAPI.request("$base_url/text")
        catch exception
            exception_stack = Base.current_exceptions()
            @test exception_stack[end].exception === exception
            @test any(
                entry -> entry.exception isa HTTP.Exceptions.ConnectError,
                exception_stack[begin:(end - 1)]
            )
            exception
        end
        @test transport_error isa KEGGAPI.RequestError
        @test occursin("Request to $base_url/text failed", transport_error.message)

        # Keep one live request to check compatibility with the KEGG service.
        result = KEGGAPI.request("https://rest.kegg.jp/info/kegg")
        @test result isa String
        @test !isempty(result)
        @test contains(lowercase(result), "kegg")
        sleep(0.4)
    end

    @testset "info" begin
        r = KEGGAPI.kegg_info("kegg")

        # Test that the response is a non-empty string containing "kegg"
        @test isa(r, String)
        @test length(r) > 0
        @test contains(lowercase(r), "kegg")

        # Test that requesting info for an invalid database throws an error
        @test_throws KEGGAPI.RequestError KEGGAPI.kegg_info("fail")

        # Test that requesting info with a non-symbol argument throws a MethodError
        @test_throws MethodError KEGGAPI.kegg_info(:fail)
        sleep(0.4)
    end

    @testset "list" begin
        kegg_pathways = KEGGAPI.kegg_list("pathway")
        @test isa(kegg_pathways, KEGGAPI.KeggTupleList)
        @test length(kegg_pathways.data) > 0
        @test_throws KEGGAPI.RequestError KEGGAPI.kegg_list("fail")
        sleep(0.4)
    end

    @testset "find" begin
        kegg_find_pathway = KEGGAPI.kegg_find("pathway", "glycolysis")
        @test isa(kegg_find_pathway, KEGGAPI.KeggTupleList)
        @test length(kegg_find_pathway.data) > 0
        sleep(0.4)

        kegg_find_compound = KEGGAPI.kegg_find("compound", "glucose")
        @test isa(kegg_find_compound, KEGGAPI.KeggTupleList)
        @test length(kegg_find_compound.data) > 0
        sleep(0.4)

        kegg_find_genes = KEGGAPI.kegg_find("genes", "glycolysis")
        @test isa(kegg_find_genes, KEGGAPI.KeggTupleList)
        @test length(kegg_find_genes.data) > 0
        sleep(0.4)

        # Databases beyond the old whitelist now work (e.g. ko/enzyme)
        kegg_find_ko = KEGGAPI.kegg_find("ko", "kinase")
        @test isa(kegg_find_ko, KEGGAPI.KeggTupleList)
        @test length(kegg_find_ko.data[1]) > 0
        sleep(0.4)

        # `option` is only valid for compound/drug, and must be a known option
        @test_throws ArgumentError KEGGAPI.kegg_find("pathway", "glucose", "formula")
        @test_throws ArgumentError KEGGAPI.kegg_find("compound", "glucose", "bogus")

        # An unrecognized database warns (but is still passed through to the API)
        @test_warn "not a recognized KEGG database" (
            try
                KEGGAPI.kegg_find("notadb", "x")
            catch end
        )
        sleep(0.4)
    end

    @testset "conv" begin
        r = KEGGAPI.kegg_conv("eco", "ncbi-geneid")
        @test isa(r, KEGGAPI.KeggTupleList)
        @test length(r.data) > 0
        @test_throws KEGGAPI.RequestError KEGGAPI.kegg_conv("fail", "ncbi-geneid")
        sleep(0.4)
        @test_throws KEGGAPI.RequestError KEGGAPI.kegg_conv("eco", "fail")
        sleep(0.4)

        r = KEGGAPI.kegg_conv("ncbi-proteinid", ["hsa:10458", "ece:Z5100"])
        @test isa(r, KEGGAPI.KeggTupleList)
        @test length(r.data) > 0
        @test_throws KEGGAPI.RequestError KEGGAPI.kegg_conv("fail", ["hsa:10458", "ece:Z5100"])
        @test_throws KEGGAPI.RequestError KEGGAPI.kegg_conv("ncbi-proteinid", ["foo", "bar", "baz"])
        sleep(0.4)
    end

    @testset "link" begin
        r = KEGGAPI.kegg_link("pathway", "hsa")
        @test isa(r, KEGGAPI.KeggTupleList)
        @test length(r.data) > 0
        sleep(0.4)

        @test_throws KEGGAPI.RequestError KEGGAPI.kegg_link("fail", "hsa"); sleep(0.4)

        r = KEGGAPI.kegg_link("pathway", ["hsa:10458", "ece:Z51000"])
        @test isa(r, KEGGAPI.KeggTupleList)
        @test length(r.data) > 0
        sleep(0.4)

        @test_throws KEGGAPI.RequestError KEGGAPI.kegg_link("fail", ["hsa:10458", "ece:Z5100"]); sleep(0.4)
        @test_throws KEGGAPI.RequestError KEGGAPI.kegg_link("pathway", ["foo", "bar", "baz"]); sleep(0.4)

        # RDF output option returns the raw response text instead of a KeggTupleList
        r = KEGGAPI.kegg_link("atc", "D00564", "turtle")
        @test isa(r, String)
        @test occursin("@prefix", r)
        sleep(0.4)
    end

    @testset "ddi" begin
        @testset "vector request limits" begin
            dbentries = ["D$(lpad(string(i), 5, '0'))" for i in 1:10]
            requested_urls = String[]
            mock_request = function (url::String)
                push!(requested_urls, url)
                return "dr:D00001\tdr:D00010\tP\tmock interaction\n"
            end

            r = KEGGAPI._kegg_ddi(dbentries, mock_request)
            expected_url = "https://rest.kegg.jp/ddi/$(join(dbentries, "+"))"
            @test requested_urls == [expected_url]
            @test r.url == [expected_url]
            @test r.data[1] == ["dr:D00001"]
            @test r.data[2] == ["dr:D00010"]

            @test_throws ArgumentError KEGGAPI.kegg_ddi(String[])

            request_count = Ref(0)
            counting_request = function (url::String)
                request_count[] += 1
                return ""
            end
            @test_throws ArgumentError KEGGAPI._kegg_ddi(String[], counting_request)
            @test request_count[] == 0
        end

        r = KEGGAPI.kegg_ddi("D00564")
        @test isa(r, KEGGAPI.KeggTupleList)
        @test length(r.data) == 4
        @test length(r.data[1]) > 0
        sleep(0.4)

        r = KEGGAPI.kegg_ddi(["D00564", "D00100"])
        @test isa(r, KEGGAPI.KeggTupleList)
        @test length(r.data[1]) > 0
        sleep(0.4)

        @test_throws KEGGAPI.RequestError KEGGAPI.kegg_ddi("fail")
        sleep(0.4)
    end

    @testset "get" begin
        # Basic request
        r = KEGGAPI.kegg_get(["hsa00010", "hsa00020"])
        @test isa(r, NamedTuple)
        @test length(r) == 2
        @test keys(r) == (:url, :data)
        @test length(r.url) == 1
        @test length(r.data) == 2
        sleep(0.4)

        # More than 10 entries
        dbentries = ["map01100", "map01110", "map01120", "map01200", "map01210", "map01212", "map01230", "map01232", "map01250", "map01240", "map01220", "map01310", "map01320"]
        r = KEGGAPI.kegg_get(dbentries)
        @test isa(r, NamedTuple)
        @test length(r) == 2
        @test keys(r) == (:url, :data)
        @test length(r.url) == ceil(Int, length(dbentries) / 10)
        @test length(r.data) == length(dbentries)
        @test all(isa.(r.data, String))
        sleep(0.4)

        # Single request
        r = KEGGAPI.kegg_get("hsa00010")
        @test isa(r, NamedTuple)
        @test length(r) == 2
        @test keys(r) == (:url, :data)
        @test isa(r.url, String)
        @test isa(r.data, String)
        sleep(0.4)

        # Single request via macro
        @test r == KEGGAPI.kegg"hsa00010"
        sleep(0.4)

        # Biological sequence request
        r = KEGGAPI.kegg_get("hsa:10458", :aaseq)
        @test isa(r, NamedTuple)
        @test length(r) == 2
        @test keys(r) == (:url, :data)
        @test isa(r.url, String)
        @test isa(r.data, String)
        @test startswith(r.data, ">")
        sleep(0.4)

        # Image request
        r = KEGGAPI.kegg_get("map00010", :image)
        @test isa(r, NamedTuple)
        @test length(r) == 2
        @test keys(r) == (:url, :data)
        @test isa(r.url, String)
        @test isa(r.data, Vector)
        sleep(0.4)
        @test_warn "Using the :image option with kegg_get is limited to one compound/glycan/drug entry" KEGGAPI.kegg_get(["map00010", "map01110"], :image)
        @test_warn "KEGG API accepts 3 requests per second. Current timeout may lead to API rate limit errors." KEGGAPI.kegg_get("map00010"; timeout = 0.1)

        # Doubled-size reference-pathway image request
        r = KEGGAPI.kegg_get("map00010", :image2x)
        @test isa(r, NamedTuple)
        @test keys(r) == (:url, :data)
        @test isa(r.url, String)
        @test isa(r.data, Vector)
        sleep(0.4)

        # Invalid option
        @test_throws ArgumentError KEGGAPI.kegg_get("map00010", :foo)
    end
end
