using NamedTuples

struct TestSourceWithoutLength
end

function Base.eltype(iter::TestSourceWithoutLength)
    return @NT(a::Int, b::Float64)
end

Base.iteratorsize(::Type{T}) where {T <: TestSourceWithoutLength} = Base.SizeUnknown()

function Base.start(iter::TestSourceWithoutLength)
    return 1
end

function Base.next(iter::TestSourceWithoutLength, state)
    if state==1
        return @NT(a=1, b=1.), 2
    elseif state==2
        return @NT(a=2, b=2.), 3
    end
end

function Base.done(iter::TestSourceWithoutLength, state)
    return state>2
end