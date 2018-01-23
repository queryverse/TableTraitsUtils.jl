__precompile__()
module TableTraitsUtils

using TableTraits, NamedTuples, DataValues

export create_tableiterator, create_columns_from_iterabletable

# T is the type of the elements produced
# TS is a tuple type that stores the columns of the table
struct TableIterator{T, TS}
    columns::TS
end

function create_tableiterator(columns, names::Vector{Symbol})
    col_expressions = Array{Expr,1}()
    df_columns_tuple_type = Expr(:curly, :Tuple)
    for i in 1:length(columns)
        etype = eltype(columns[i])
        if etype <: Nullable
            push!(col_expressions, Expr(:(::), names[i], DataValue{etype.parameters[1]}))
        else
            push!(col_expressions, Expr(:(::), names[i], etype))
        end
        push!(df_columns_tuple_type.args, typeof(columns[i]))
    end
    t_expr = NamedTuples.make_tuple(col_expressions)

    t2 = :(TableIterator{Float64,Float64})
    t2.args[2] = t_expr
    t2.args[3] = df_columns_tuple_type

    t = eval(t2)

    e_df = t((columns...))

    return e_df
end

function Base.length(iter::TableIterator{T,TS}) where {T,TS}
    return length(iter.columns[1])
end

function Base.eltype(iter::TableIterator{T,TS}) where {T,TS}
    return T
end

Base.eltype(::Type{TableIterator{T,TS}}) where {T,TS} = T

function Base.start(iter::TableIterator{T,TS}) where {T,TS}
    return 1
end

@generated function Base.next(iter::TableIterator{T,TS}, state) where {T,TS}
    constructor_call = Expr(:call, :($T))
    for (i,t) in enumerate(T.parameters)
        if eltype(iter.parameters[2].parameters[i]) <: Nullable
            push!(constructor_call.args, :(DataValue(columns[$i][i])))
        else
            push!(constructor_call.args, :(columns[$i][i]))
        end
    end

    quote
        i = state
        columns = iter.columns
        a = $constructor_call
        return a, state+1
    end
end

function Base.done(iter::TableIterator{T,TS}, state) where {T,TS}
    return state>length(iter.columns[1])
end

# Sink

@generated function _fill_cols_without_length(columns, enumerable)
    push_exprs = Expr(:block)
    for i in find(collect(columns.types) .!= Void)
        ex = :( push!(columns[$i], i[$i]) )
        push!(push_exprs.args, ex)
    end

    quote
        for i in enumerable
            $push_exprs
        end
    end
end

@generated function _fill_cols_with_length(columns, enumerable)
    push_exprs = Expr(:block)
    for col_idx in find(collect(columns.types) .!= Void)
        ex = :( columns[$col_idx][i] = v[$col_idx] )
        push!(push_exprs.args, ex)
    end

    quote
        for (i,v) in enumerate(enumerable)
            $push_exprs
        end
    end
end

function _default_array_factory(t,rows)
    if isa(t, TypeVar)
        return Array{Any}(rows)
    else
        return Array{t}(rows)
    end
end

function create_columns_from_iterabletable(source, sel_cols = :all; array_factory::Function=_default_array_factory)
    if supports_get_columns_copy(source)
        data = get_columns_copy(source)

        columns = [data[i] for i in 1:length(data)]
        column_names = fieldnames(data)
    else
        iter = getiterator(source)

        T = eltype(iter)
        if !(T<:NamedTuple)
            error("Can only collect a NamedTuple iterator.")
        end

        column_types = TableTraits.column_types(iter)
        column_names = TableTraits.column_names(iter)

        rows = Base.iteratorsize(typeof(iter))==Base.HasLength() ? length(iter) : 0

        columns = []
        for (i, t) in enumerate(column_types)
            if sel_cols == :all || i in sel_cols
                push!(columns, array_factory(t, rows))
            else
                push!(columns, nothing)
            end
        end

        if Base.iteratorsize(typeof(iter))==Base.HasLength()
            _fill_cols_with_length((columns...), iter)
        else
            _fill_cols_without_length((columns...), iter)
        end
    end

    if sel_cols == :all
        return columns, column_names
    else
        return columns[sel_cols], column_names[sel_cols]
    end    
end

end # module
