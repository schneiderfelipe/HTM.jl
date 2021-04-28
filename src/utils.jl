# --- Utilities ---
# That could be contributed to Julia.

"""
    readuntil(predicate, io::IO)

Read characters until matching a predicate.

Based on <https://github.com/JuliaLang/julia/issues/21355#issue-221121166>.
"""
@inline function Base.readuntil(predicate, io::IO)
    buf = IOBuffer()
    while !eof(io)
        c = read(io, Char)
        if predicate(c)
            skip(io, -ncodeunits(c))
            break
        end
        write(buf, c)
    end
    return String(take!(buf))
end

"""
    startswith(io::IO, prefix::Union{AbstractString,Base.Chars})

Check if an `IO` object starts with a prefix.

Based on <https://github.com/JuliaLang/julia/issues/40616#issue-867861851>.
"""
@inline function Base.startswith(io::IO, prefix::Union{AbstractString,Base.Chars})
    pos = position(io)
    s = _getminprefix(io, prefix)
    seek(io, pos)
    return startswith(s, prefix)
end
@inline _getminprefix(io::IO, prefix::Union{AbstractString,AbstractChar}) = String(read(io, length(prefix)))
@inline _getminprefix(io::IO, chars::Union{Tuple{Vararg{<:AbstractChar}},AbstractVector{<:AbstractChar},Set{<:AbstractChar}}) = _getminprefix(io, first(chars))

"""
    skipstartswith(io::IO, prefix::Union{AbstractString,Base.Chars})

Check if an `IO` object starts with a prefix and skip it.
"""
@inline skipstartswith(io::IO, prefix::Union{AbstractString,AbstractChar}) = startswith(io, prefix) ? (skip(io, length(prefix)); true) : false
# @inline skipstartswith(io::IO, chars::Union{Tuple{Vararg{<:AbstractChar}},AbstractVector{<:AbstractChar},Set{<:AbstractChar}}) = startswith(io, chars) ? (skip(io, length(first(chars))); true) : false
