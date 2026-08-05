function chunk_vector(vec::Vector, chunk_size::Int)
    return [vec[i:min(i + chunk_size - 1, end)] for i in 1:chunk_size:length(vec)]
end
