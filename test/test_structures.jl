using KEGGAPI
using Test

@testset "tabular result contract" begin
    @testset "exported result types" begin
        @test KeggTupleList === KEGGAPI.KeggTupleList
        @test KeggGenesList === KEGGAPI.KeggGenesList
        @test RequestError === KEGGAPI.RequestError
    end

    @testset "rows and native collection interface" begin
        result = KEGGAPI.tuple_parser("a\talpha\nb\tbeta\n", "tuple-url")

        @test result.colnames == ["ID", "Details"]
        @test result.data == [["a", "alpha"], ["b", "beta"]]
        @test length(result) == 2
        @test !isempty(result)
        @test firstindex(result) == 1
        @test lastindex(result) == 2
        @test result[1] == ["a", "alpha"]
        @test collect(result) == result.data
    end

    @testset "stable row schemas" begin
        pathway = KEGGAPI.pathway_parser("path:hsa00010\tGlycolysis\n", "pathway-url")
        @test pathway.colnames == ["ID", "Pathway"]
        @test pathway.data == [["path:hsa00010", "Glycolysis"]]

        conversion = KEGGAPI.conv_parser(
            "ncbi-geneid:945006\teco:b0002\n",
            "conversion-url"
        )
        @test conversion.colnames == ["Source ID", "Target ID"]
        @test conversion.data == [["ncbi-geneid:945006", "eco:b0002"]]

        interaction = KEGGAPI.ddi_parser(
            "D00564\tD00100\tCI\tmetabolism\n",
            "ddi-url"
        )
        @test interaction.colnames == [
            "Entry 1",
            "Entry 2",
            "Interaction Type",
            "Mechanism",
        ]
        @test interaction.data == [["D00564", "D00100", "CI", "metabolism"]]

        genes = KEGGAPI.genomic_feature_parser(
            "hsa:1\tCDS\t1:10..20\tGENE1\n",
            "genes-url"
        )
        @test genes isa KeggGenesList
        @test genes.colnames == ["ID", "Type", "Chromosomal Position", "Gene Name"]
        @test genes.data == [["hsa:1", "CDS", "1:10..20", "GENE1"]]
    end

    @testset "variable-width, empty, and malformed responses" begin
        multi_column = KEGGAPI.tuple_parser("T01001\thsa\tHomo sapiens\tEukaryotes\n", "genome-url")
        @test isequal(multi_column.colnames, ["ID", missing, missing, missing])
        @test multi_column.data == [["T01001", "hsa", "Homo sapiens", "Eukaryotes"]]

        empty_result = KEGGAPI.tuple_parser("", "empty-url")
        @test isempty(empty_result.colnames)
        @test isempty(empty_result)

        @test_throws RequestError KEGGAPI.tuple_parser(
            "a\talpha\nincomplete\n",
            "malformed-url"
        )
    end
end
