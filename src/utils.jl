# --- Utilities ---
# That could be contributed to Julia.

"""
    readuntil(predicate, io::IO)

Read characters until matching a predicate.

Based on [this](https://github.com/JuliaLang/julia/issues/21355#issue-221121166).

```jldoctest
julia> readuntil(isspace, IOBuffer("pineapple: 🍍..."))
"pineapple:"
```
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

Based on [this](https://github.com/JuliaLang/julia/issues/40616#issue-867861851).

```jldoctest
julia> io = IOBuffer("pineapple: 🍍...");

julia> startswith(io, "pine")
true

julia> startswith(io, "apple")
false
```
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

```jldoctest
julia> io = IOBuffer("pineapple: 🍍...");

julia> HTM.skipstartswith(io, "pine")
true

julia> read(io, String)
"apple: 🍍..."

julia> io = IOBuffer("pineapple: 🍍...");

julia> HTM.skipstartswith(io, "apple")
false

julia> read(io, String)
"pineapple: 🍍..."
```
"""
skipstartswith(io::IO, prefix::Union{AbstractString,AbstractChar}) = startswith(io, prefix) ? (skip(io, length(prefix)); true) : false
# skipstartswith(io::IO, chars::Union{Tuple{Vararg{<:AbstractChar}},AbstractVector{<:AbstractChar},Set{<:AbstractChar}}) = startswith(io, chars) ? (skip(io, length(first(chars))); true) : false
