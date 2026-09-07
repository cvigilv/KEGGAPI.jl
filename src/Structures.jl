## Types returned by the KEGG API

# This type represents a KEGG API request error.
struct RequestError <: Exception
    message::String
end

"""
    KeggTable(url, columns::NamedTuple)

Tabular data returned by a KEGG REST operation.

`url` is the request URL, or a vector of request URLs when KEGGAPI split a
request into batches. `columns` is a named tuple of equally sized vectors. Its
keys are stable `Symbol` column names.

`KeggTable` implements the Tables.jl column-access interface, so table consumers
can use it directly. For example, `DataFrame(result)` constructs a data frame
without KEGGAPI depending on DataFrames.jl.

The old `.data` and `.colnames` properties remain available during the 1.x
release series. They are deprecated in favor of `.columns` and
`Tables.columnnames(result)`.
"""
struct KeggTable{U, C <: NamedTuple}
    url::U
    columns::C

    function KeggTable(url::U, columns::C) where {U, C <: NamedTuple}
        all(column -> column isa AbstractVector, values(columns)) ||
            throw(ArgumentError("every KeggTable column must be an AbstractVector"))

        column_lengths = map(length, values(columns))
        if !isempty(column_lengths) && !all(==(first(column_lengths)), column_lengths)
            throw(ArgumentError("all KeggTable columns must have the same length"))
        end

        return new{U, C}(url, columns)
    end
end

# issue #26: all tabular results expose the same column-oriented Tables.jl contract.
Tables.istable(::Type{<:KeggTable}) = true
Tables.columnaccess(::Type{<:KeggTable}) = true
Tables.columns(table::KeggTable) = getfield(table, :columns)
Tables.columnnames(table::KeggTable) = keys(getfield(table, :columns))
Tables.getcolumn(table::KeggTable, index::Int) = getfield(table, :columns)[index]
Tables.getcolumn(table::KeggTable, name::Symbol) = getproperty(getfield(table, :columns), name)
Tables.schema(table::KeggTable) = Tables.Schema(
    keys(getfield(table, :columns)),
    map(eltype, values(getfield(table, :columns)))
)

function Base.getproperty(table::KeggTable, name::Symbol)
    if name === :data
        Base.depwarn("`.data` is deprecated; use `.columns` or `Tables.columns(result)` instead", :data)
        return collect(values(getfield(table, :columns)))
    elseif name === :colnames
        Base.depwarn("`.colnames` is deprecated; use `Tables.columnnames(result)` instead", :colnames)
        return collect(String.(keys(getfield(table, :columns))))
    end
    return getfield(table, name)
end

Base.propertynames(::KeggTable, ::Bool = false) = (:url, :columns, :data, :colnames)

# Keep the old type names as aliases while callers migrate to KeggTable.
const KeggTupleList = KeggTable
const KeggGenesList = KeggTable
