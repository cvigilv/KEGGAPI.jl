using KEGGAPI
using Test

@testset "request delay" begin
    @test KEGGAPI.resolve_request_delay(nothing, nothing, :test_function, 2) == 0.4
    @test KEGGAPI.resolve_request_delay(1, nothing, :test_function, 2) == 1
    @test_deprecated r"use request_delay" KEGGAPI.resolve_request_delay(1, 1.0, :test_function, 2)

    for delay in (-0.1, Inf, -Inf, NaN)
        @test_throws ArgumentError KEGGAPI.resolve_request_delay(delay, nothing, :test_function, 2)
        @test_throws ArgumentError KEGGAPI.resolve_request_delay(nothing, delay, :test_function, 2)
    end
    @test_throws ArgumentError KEGGAPI.resolve_request_delay(0.4, 0.5, :test_function, 2)

    @test_logs KEGGAPI.resolve_request_delay(0.0, nothing, :test_function, 1)
    @test_logs (:warn, r"three requests per second") KEGGAPI.resolve_request_delay(0.0, nothing, :test_function, 2)
end

@testset "request batches" begin
    requested_batches = Vector{Vector{String}}()
    sleep_delays = Float64[]
    request_batch = chunk -> push!(requested_batches, collect(chunk))
    record_sleep = delay -> push!(sleep_delays, delay)

    KEGGAPI.foreach_request_batch(request_batch, ["entry-$i" for i in 1:10], 0.4, record_sleep)
    @test length(requested_batches) == 1
    @test isempty(sleep_delays)

    empty!(requested_batches)
    KEGGAPI.foreach_request_batch(request_batch, ["entry-$i" for i in 1:21], 0.4, record_sleep)
    @test length(requested_batches) == 3
    @test length.(requested_batches) == [10, 10, 1]
    @test sleep_delays == [0.4, 0.4]
end
