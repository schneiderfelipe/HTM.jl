module HyperscriptLiteral

# We say...          Hyperscript.jl says...
# `tag` or `Tag`      => `Node`
# `type` or `tagtype` => `tag`
# `props` (property)  => `attrs` (attribute)
using Hyperscript: Node, DEFAULT_HTMLSVG_CONTEXT

export create_element
export @htm_str

"""
    create_element(type::AbstractString, children...)
    create_element(type::AbstractString, props::AbstractDict, children...)

Create a Hyperscript.jl element.

This is an alternative syntax and (currently) serves as a rather trivial
absctraction layer inspired by
[`React.createElement`](https://pt-br.reactjs.org/docs/react-api.html#createelement).
"""
create_element(type::AbstractString, children...) = create_element(type, Dict{String, Any}(), children...)
create_element(type::AbstractString, props::AbstractDict, children...) = Node(DEFAULT_HTMLSVG_CONTEXT, type, children, props)

"""
    Tag(type, props, children)

Compile time internal representation of an HTML tag.
"""
struct Tag
    type
    props
    promises
    children
end
Base.:(==)(a::Tag, b::Tag) = a.type == b.type && a.props == b.props && a.children == b.children

macro htm_str(s)
    htm = parse(s)
    esc(toexpr(htm))
end

toexpr(x) = x
function toexpr(x::Tag)
    type, props, children = toexpr.((x.type, x.props, x.children))
    !isempty(x.promises) && (props = :(merge($(props), $(toexpr(x.promises))...)))
    return :(create_element($(type), $(process)($(props)), $(children)))
end
toexpr(s::AbstractString) = startswith(s, '$') ? Meta.parse(s[nextind(s, begin):end]) : s
toexpr(xs::AbstractVector) = (xs = map(toexpr, xs); :([$(xs...)]))
toexpr(d::AbstractDict) = :(Dict($(toexpr(collect(d)))))
toexpr(p::Pair) = :($(toexpr(first(p))) => $(toexpr(last(p))))

process(x) = x
process(xs::AbstractVector) = string(map(process, xs)...)
process(d::AbstractDict) = Dict(process(p) for p in d if isenabled(p))
process(p::Pair) = process(first(p)) => process(last(p))
process(x::Bool) = x ? nothing : error("should have been disabled")

# We hide props if `false` or `nothing`, Hyperscript.jl uses `nothing` to
# mean something else (empty prop).
# TODO: suggest change in Hyperscript.jl. 💡
isenabled(x) = true
isenabled(p::Pair) = isenabled(last(p))
isenabled(x::Bool) = x
isenabled(::Nothing) = false

"""
    parse(io::IO)
    parse(s::AbstractString)

Parse HTML.
"""
function parse(io::IO)
    elems = parseelems(io)
    isempty(elems) && return nothing
    length(elems) == 1 && return only(elems)
    return elems
end
parse(s::AbstractString) = parse(IOBuffer(s))

# --- HTML specification ---

"""
    parseelems(io::IO)

Parse HTML elements.

This function is the entry point for an implementation of a subset of the
[HTML standard](https://html.spec.whatwg.org/multipage/parsing.html#tokenization).
"""
parseelems(io::IO) = parseelems(io -> true, io)
function parseelems(predicate, io::IO)
    elems = []
    parseelems!(predicate, io, elems)
    return elems
end
function parseelems!(predicate, io::IO, elems::AbstractVector)
    while !eof(io) && predicate(io)
        push!(elems, parseelem(io))
    end
end

"""
    parseelem(io::IO)

Parse a single HTML element.
"""
function parseelem(io::IO)
    # TODO: revisit this implementation after.
    startswith(io, '<') && return parsetag(io)
    return startswith(io, '$') ? parseinterp(io) : readuntil(c -> c ∈ ('<', '$'), io)
end

"""
    parsetag(io::IO)

Parse a `Tag` object.
"""
function parsetag(io::IO)
    type = parsetagtype(io)
    props, promises = parseprops(io)
    if read(io, Char) === '/'
        skipchars(isequal('>'), io)
        return Tag(type, props, promises, [])
    end

    endtag = "</$(type)>"
    children = parseelems(io -> !startswith(io, endtag), io)

    # TODO: might use a skipuntil
    skip(io, length(endtag))
    return Tag(type, props, promises, children)
end

"""
    parsetagtype(io::IO)

Parse an HTML tag type.
"""
parsetagtype(io::IO) = (skipchars(isequal('<'), io); readuntil(c -> isspace(c) || c ∈ ('>', '/'), io))

"""
    parseprops(io::IO)

Parse HTML properties of a tag.
"""
function parseprops(io::IO)
    # TODO: revisit this implementation after.
    props, promises = Dict{String, Any}(), []
    parseprops!(io, props, promises)
    return props, promises
end
function parseprops!(io::IO, props::AbstractDict, promises::AbstractVector)
    # TODO: revisit this implementation after.
    while !eof(io)
        skipchars(isspace, io)
        startswith(io, ('>', '/')) && break
        startswith(io, '$') ? push!(promises, parseinterp(io)) : parseprop!(io, props)
    end
end

"""
    parseprop!(io::IO, props::AbstractDict)

Parse a single HTML property of a tag.
"""
function parseprop!(io::IO, props::AbstractDict)
    # TODO: revisit this implementation after.
    key = parsekey(io)
    eof(io) && (props[key] = nothing; return)

    c = read(io, Char)
    props[key] = c === '=' ? parsevalue(io) : nothing
    c ∈ ('>', '/') && skip(io, -1)
end

"""
    parsekey(io::IO)

Parse an HTML property key.
"""
parsekey(io::IO) = readuntil(c -> isspace(c) || c ∈ ('=', '>', '/'), io)

"""
    parsevalue(io::IO)

Parse an HTML property value.
"""
parsevalue(io::IO) = (skipchars(isspace, io); startswith(io, ('"', '\'')) ? parsequotedvalue(io) : parseunquotedvalue(io))
function parsequotedvalue(io::IO)
    q = read(io, Char)
    pieces = []
    while !eof(io) && !startswith(io, q)
        push!(pieces, startswith(io, '$') ? parseinterp(io) : readuntil(c -> c ∈ (q, '$'), io))
    end
    skipchars(isequal(q), io)
    length(pieces) == 1 && return only(pieces)
    return pieces
end
parseunquotedvalue(io::IO) = startswith(io, '$') ? parseinterp(io) : readuntil(c -> isspace(c) || c ∈ ('>', '/'), io)

raw"""
    parseinterp(io::IO)

Parse an interpolation as string, including `$`.
"""
function parseinterp(io::IO)
    # TODO: revisit this implementation after.
    buf = IOBuffer()
    write(buf, read(io, Char))
    (eof(io) || isspace(peek(io, Char))) && return '$'  # frustrated interp returns `Char`

    if startswith(io, '(')
        count = 1
        write(buf, read(io, Char))

        while count > 0
            c = read(io, Char)
            if c === '('
                count += 1
            elseif c === ')'
                count -= 1
            end
            write(buf, c)
        end
    else
        write(buf, readuntil(c -> isspace(c) || c ∈ ('<', '>', '$'), io))
    end
    return String(take!(buf))
end

# --- Utilities ---
# All those could be part of Julia in the future.

"""
    readuntil(predicate, io::IO)

Read characters until matching a predicate.

Based on <https://github.com/JuliaLang/julia/issues/21355#issue-221121166>.
"""
function Base.readuntil(predicate, io::IO)
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
function Base.startswith(io::IO, prefix::Union{AbstractString,Base.Chars})
    pos = position(io)
    s = _getminprefix(io, prefix)
    seek(io, pos)
    return startswith(s, prefix)
end
_getminprefix(io::IO, prefix::Union{AbstractString,AbstractChar}) = String(read(io, length(prefix)))
_getminprefix(io::IO, chars::Union{Tuple{Vararg{<:AbstractChar}},AbstractVector{<:AbstractChar},Set{<:AbstractChar}}) = _getminprefix(io, first(chars))

end
