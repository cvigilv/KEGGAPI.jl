using KEGGAPI
using Test

@testset verbose=true "Requests" begin
    @testset "KEGGAPI.request" begin
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
    end

    @testset "KEGGAPI.info" begin
        kegg_info = KEGGAPI.info("kegg")
        @test isa(kegg_info, String)
        @test length(kegg_info) > 0
        @test contains(lowercase(kegg_info), "kegg")
        @test_throws KEGGAPI.RequestError KEGGAPI.info("fail")
        sleep(0.1)
    end

    @testset "KEGGAPI.list" begin
        kegg_pathways = KEGGAPI.list("pathway")
        @test isa(kegg_pathways, KEGGAPI.KeggTupleList)
        @test length(kegg_pathways.data) > 0
        @test_throws KEGGAPI.RequestError KEGGAPI.list("fail")
        sleep(0.1)
    end

    @testset "KEGGAPI.find" begin
        kegg_find_pathway = KEGGAPI.find("pathway", "glycolysis")
        @test isa(kegg_find_pathway, KEGGAPI.KeggTupleList)
        @test length(kegg_find_pathway.data) > 0
        sleep(0.1)

        kegg_find_compound = KEGGAPI.find("compound", "glucose")
        @test isa(kegg_find_compound, KEGGAPI.KeggTupleList)
        @test length(kegg_find_compound.data) > 0
        sleep(0.1)

        kegg_find_genes = KEGGAPI.find("genes", "glycolysis")
        @test isa(kegg_find_genes, KEGGAPI.KeggTupleList)
        @test length(kegg_find_genes.data) > 0
        sleep(0.1)
    end

    @testset "KEGGAPI.conv" begin
        kegg_conv = KEGGAPI.conv("eco", "ncbi-geneid")
        @test isa(kegg_conv, KEGGAPI.KeggTupleList)
        @test length(kegg_conv.data) > 0
        sleep(0.1)
    end

    @testset "KEGGAPI.link" begin
        kegg_link = KEGGAPI.link("pathway", "hsa")
        @test isa(kegg_link, KEGGAPI.KeggTupleList)
        @test length(kegg_link.data) > 0
        sleep(0.1)
    end

    @testset "KEGGAPI.get_image" begin
        kegg_image = KEGGAPI.get_image("hsa00010")
        @test isa(kegg_image, Vector)
        @test length(kegg_image) > 0
        @test_throws KEGGAPI.RequestError KEGGAPI.get_image("fail")
        sleep(0.1)
    end

    @testset "KEGGAPI.save_image" begin
        file_name = "test_image.png"
        kegg_image = KEGGAPI.get_image("hsa00010")
        KEGGAPI.save_image(kegg_image, file_name)
        @test isfile(file_name)
        @test filesize(file_name) > 0
        rm(file_name, force = true)
        sleep(0.1)
    end
end
