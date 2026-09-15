using KEGGAPI
using Test

function empty_conv(; kwargs...)
    return KEGGAPI.kegg_conv("genes", String[]; kwargs...)
end

function empty_get(; kwargs...)
    return KEGGAPI.kegg_get(String[]; kwargs...)
end

function empty_link(; kwargs...)
    return KEGGAPI.kegg_link("pathway", String[]; kwargs...)
end

function empty_list(; kwargs...)
    return KEGGAPI.kegg_list(String[]; kwargs...)
end

@testset "batched API request delays" begin
    empty_calls = (empty_conv, empty_get, empty_link, empty_list)

    @testset "timeout compatibility alias" begin
        for call in empty_calls
            @test_deprecated r"use request_delay" call(; timeout = 0.4)
        end
        @test_deprecated r"use request_delay" empty_get(; request_delay = 0.4, timeout = 0.4)

        for call in empty_calls
            @test_throws ArgumentError call(; request_delay = 0.4, timeout = 0.5)
        end
    end

    @testset "invalid delays" begin
        for call in empty_calls, delay in (-0.1, Inf, -Inf, NaN)
            @test_throws ArgumentError call(; request_delay = delay)
            @test_throws ArgumentError call(; timeout = delay)
        end
    end

    @testset "wrapper batching" begin
        batched_calls = (
            (entries, requester, sleeper) -> KEGGAPI._kegg_conv(
                "genes", entries, requester, sleeper; request_delay = 0.4
            ),
            (entries, requester, sleeper) -> KEGGAPI._kegg_get(
                entries, nothing, requester, sleeper; request_delay = 0.4
            ),
            (entries, requester, sleeper) -> KEGGAPI._kegg_link(
                "pathway", entries, "", requester, sleeper; request_delay = 0.4
            ),
            (entries, requester, sleeper) -> KEGGAPI._kegg_list(
                entries, requester, sleeper; request_delay = 0.4
            ),
        )

        for call in batched_calls
            requested_urls = String[]
            sleep_delays = Float64[]
            requester = function (url::String, response_type::Type = String)
                push!(requested_urls, url)
                return response_type === String ? "" : UInt8[]
            end
            sleeper = delay -> push!(sleep_delays, delay)

            call(["entry-$i" for i in 1:10], requester, sleeper)
            @test length(requested_urls) == 1
            @test isempty(sleep_delays)

            empty!(requested_urls)
            call(["entry-$i" for i in 1:21], requester, sleeper)
            @test length(requested_urls) == 3
            @test sleep_delays == [0.4, 0.4]
        end
    end

    partition_view = first(Iterators.partition(["hsa:1", "hsa:2", "hsa:3"], 2))
    @test KEGGAPI.build_kegg_url(partition_view, nothing) == "https://rest.kegg.jp/get/hsa:1+hsa:2"
end
