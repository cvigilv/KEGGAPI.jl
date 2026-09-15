const DEFAULT_REQUEST_DELAY = 0.4
const KEGG_REQUEST_INTERVAL = 1 / 3
const KEGG_BATCH_SIZE = 10

function resolve_request_delay(
        request_delay::Union{Nothing, Real}, timeout::Union{Nothing, Real},
        function_name::Symbol, request_count::Int,
    )
    for delay in (request_delay, timeout)
        if !isnothing(delay) && (!isfinite(delay) || delay < 0)
            throw(ArgumentError("request_delay must be finite and nonnegative"))
        end
    end

    if !isnothing(request_delay) && !isnothing(timeout) && request_delay != timeout
        throw(ArgumentError("request_delay and the deprecated timeout alias must be equal when both are supplied"))
    end

    if !isnothing(timeout)
        Base.depwarn("The timeout keyword is deprecated; use request_delay instead.", function_name)
    end

    delay = something(request_delay, timeout, DEFAULT_REQUEST_DELAY)
    if request_count > 1 && delay < KEGG_REQUEST_INTERVAL
        @warn "KEGG allows at most three requests per second. A request_delay below $(KEGG_REQUEST_INTERVAL) seconds may cause rate-limit errors."
    end
    return delay
end

function foreach_request_batch(
        f::F, dbentries::AbstractVector{String}, request_delay::Real,
        sleep_function::S,
    ) where {F, S}
    request_count = cld(length(dbentries), KEGG_BATCH_SIZE)
    for (request_index, chunk) in enumerate(Iterators.partition(dbentries, KEGG_BATCH_SIZE))
        f(chunk)
        request_index < request_count && sleep_function(request_delay)
    end
    return nothing
end
