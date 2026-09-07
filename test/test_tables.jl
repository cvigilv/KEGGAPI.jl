using DataFrames: DataFrame, names
using KEGGAPI
using Tables
using Test

@testset "KeggTable" begin
    @testset "table interface" begin
        result = KEGGAPI.tuple_parser("a\talpha\nb\tbeta\n", "https://example.test/find")

        @test result isa KeggTable
        @test result.url == "https://example.test/find"
        @test Tables.istable(typeof(result))
        @test Tables.columnaccess(typeof(result))
        @test Tables.columnnames(result) == (:id, :details)
        @test Tables.getcolumn(result, 1) == ["a", "b"]
        @test Tables.getcolumn(result, :details) == ["alpha", "beta"]
        @test Tables.schema(result) == Tables.Schema((:id, :details), (String, String))
        @test Tables.columntable(result) == (id = ["a", "b"], details = ["alpha", "beta"])
        @test Tables.rowtable(result) == [(id = "a", details = "alpha"), (id = "b", details = "beta")]

        frame = DataFrame(result)
        @test names(frame) == ["id", "details"]
        @test frame.id == ["a", "b"]
        @test frame.details == ["alpha", "beta"]
    end

    @testset "response shapes" begin
        pathway = KEGGAPI.pathway_parser("path:hsa00010\tGlycolysis\n", "pathway-url")
        @test Tables.columntable(pathway) == (
            id = ["path:hsa00010"],
            pathway = ["Glycolysis"],
        )

        conversion = KEGGAPI.conv_parser(
            "ncbi-geneid:945006\teco:b0002\nncbi-geneid:945803\teco:b0003\n",
            ["batch-1", "batch-2"]
        )
        @test conversion.url == ["batch-1", "batch-2"]
        @test Tables.columnnames(conversion) == (:source_id, :target_id)
        @test conversion.columns.source_id == ["ncbi-geneid:945006", "ncbi-geneid:945803"]
        @test conversion.columns.target_id == ["eco:b0002", "eco:b0003"]
        @test Tables.rowtable(conversion)[1] == (
            source_id = "ncbi-geneid:945006",
            target_id = "eco:b0002",
        )

        ddi = KEGGAPI.ddi_parser("D00564\tD00100\tCI\tmetabolism\n", "ddi-url")
        @test Tables.columnnames(ddi) == (:entry1, :entry2, :interaction_type, :mechanism)
        @test Tables.rowtable(ddi) == [
            (
                entry1 = "D00564",
                entry2 = "D00100",
                interaction_type = "CI",
                mechanism = "metabolism",
            ),
        ]

        genes = KEGGAPI.genomic_feature_parser(
            "hsa:1\tCDS\t1:10..20\tGENE1\n",
            "genes-url"
        )
        @test Tables.columnnames(genes) == (:id, :type, :chromosomal_position, :gene_name)
        @test Tables.columntable(genes) == (
            id = ["hsa:1"],
            type = ["CDS"],
            chromosomal_position = ["1:10..20"],
            gene_name = ["GENE1"],
        )
    end

    @testset "empty results have known schemas" begin
        empty_tables = (
            KEGGAPI.tuple_parser("", "tuple-url"),
            KEGGAPI.pathway_parser("", "pathway-url"),
            KEGGAPI.conv_parser("", "conv-url"),
            KEGGAPI.ddi_parser("", "ddi-url"),
            KEGGAPI.genomic_feature_parser("", "genes-url"),
            kegg_conv("eco", String[]),
            kegg_link("pathway", String[]),
            kegg_list(String[]),
            kegg_ddi(String[]),
        )

        for result in empty_tables
            @test result isa KeggTable
            @test all(isempty, values(Tables.columntable(result)))
            @test isempty(Tables.rowtable(result))
            @test all(==(String), Tables.schema(result).types)
        end

        @test Tables.columnnames(empty_tables[6]) == (:source_id, :target_id)
        @test Tables.columnnames(empty_tables[7]) == (:source_id, :target_id)
        @test Tables.columnnames(empty_tables[8]) == (:id, :details)
        @test Tables.columnnames(empty_tables[9]) == (:entry1, :entry2, :interaction_type, :mechanism)
    end

    @testset "compatibility properties" begin
        result = KEGGAPI.tuple_parser("a\talpha\n", "url")
        @test_deprecated result.data == [["a"], ["alpha"]]
        @test_deprecated result.colnames == ["id", "details"]
        @test result isa KEGGAPI.KeggTupleList
        @test result isa KEGGAPI.KeggGenesList
    end

    @testset "constructor validation" begin
        @test_throws ArgumentError KeggTable("url", (id = ["a"], details = ["x", "y"]))
        @test_throws ArgumentError KeggTable("url", (id = "a",))
    end
end
