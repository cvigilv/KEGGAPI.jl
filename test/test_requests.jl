using KEGGAPI
using Test

@testset verbose=true "API" begin
    @testset "request" begin
        # Test successful request to known working endpoint
        result = KEGGAPI.request("https://rest.kegg.jp/info/kegg")
        @test isa(result, String)
        @test !isempty(result)
        @test contains(lowercase(result), "kegg")  # Basic content validation (case insensitive)

        # Test another known endpoint
        result2 = KEGGAPI.request("https://rest.kegg.jp/list/pathway/hsa/01100+00230")
        @test isa(result2, String)

        # Test error handling for invalid endpoint
        @test_throws KEGGAPI.RequestError KEGGAPI.request("https://rest.kegg.jp/invalid/endpoint")

        # Test request_other function for binary data
        image_data = KEGGAPI.request_other("https://rest.kegg.jp/get/hsa00010/image")
        @test isa(image_data, Vector)
        @test length(image_data) > 0
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
    end

    @testset "conv" begin
        kegg_conv = KEGGAPI.kegg_conv("eco", "ncbi-geneid")
        @test isa(kegg_conv, KEGGAPI.KeggTupleList)
        @test length(kegg_conv.data) > 0
        sleep(0.4)
    end

    @testset "link" begin
        kegg_link = KEGGAPI.kegg_link("pathway", "hsa")
        @test isa(kegg_link, KEGGAPI.KeggTupleList)
        @test length(kegg_link.data) > 0
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
        r == KEGGAPI.kegg"hsa00010"
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
        @test_warn "Setting timeout to less than 0.4 seconds may lead to API rate limit errors. Consider increasing the timeout to avoid this issue." KEGGAPI.kegg_get("map00010"; timeout=0.1)

        # Invalid option
        @test_throws ArgumentError KEGGAPI.kegg_get("map00010", :foo)
    end
end
