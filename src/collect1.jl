@generated function _fill_cols_without_length(columns, enumerable)
    push_exprs = Expr(:block)
    for i in findall(collect(columns.types) .!= Nothing)
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
    for col_idx in findall(collect(columns.types) .!= Nothing)
        ex = :( columns[$col_idx][i] = v[$col_idx] )
        push!(push_exprs.args, ex)
    end

    quote
        for (i,v) in enumerate(enumerable)
            $push_exprs
        end
    end
end

function create_columns_from_iterabletable(source; sel_cols=:all, na_representation=:datavalue)
    iter = getiterator(source)

    T = eltype(iter)
    if !(T<:NamedTuple)
        error("Can only collect a NamedTuple iterator.")
    end

    array_factory = if na_representation==:datavalue
        (t,rows) -> Array{t}(undef, rows)
    elseif na_representation==:missing
        (t,rows) -> begin
            if t <: DataValue
                return Array{Union{eltype(t),Missing}}(undef, rows)
            else
                return Array{t}(undef, rows)
            end
        end
    end

    column_types = collect(T.parameters[2].parameters)
    column_names = collect(T.parameters[1])

    rows = Base.IteratorSize(typeof(iter))==Base.HasLength() ? length(iter) : 0

    columns = []
    for (i, t) in enumerate(column_types)
        if sel_cols == :all || i in sel_cols
            push!(columns, array_factory(t, rows))
        else
            push!(columns, nothing)
        end
    end

    if Base.IteratorSize(typeof(iter))==Base.HasLength()
        _fill_cols_with_length((columns...,), iter)
    else
        _fill_cols_without_length((columns...,), iter)
    end

    if sel_cols == :all
        return columns, column_names
    else
        return columns[sel_cols], column_names[sel_cols]
    end
end
