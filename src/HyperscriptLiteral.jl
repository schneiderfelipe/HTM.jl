module HyperscriptLiteral

# We say,            Hyperscript.jl says,
# `tag` or `Tag`      => `Node`
# `type` or `tagtype` => `tag`
# `props` (property)  => `attrs` (attribute)
using Hyperscript: Node, DEFAULT_HTMLSVG_CONTEXT

export create_element
export process
export @htm_str

include("utils.jl")

"""
    create_element(type::AbstractString[, children...])
    create_element(type::AbstractString, props::Union{AbstractDict,Tuple}[, children...])

Create a Hyperscript.jl element.

This is an alternative syntax and (currently) serves as a rather trivial
absctraction layer inspired by
[`React.createElement`](https://pt-br.reactjs.org/docs/react-api.html#createelement).
"""
create_element(type::AbstractString, children...) = create_element(type, (), children...)
create_element(type::AbstractString, props::Union{AbstractDict,Tuple}, children...) = Node(DEFAULT_HTMLSVG_CONTEXT, type, children, props)

process(🍎) = 🍎
process(v::Union{AbstractVector,Tuple}) = string(process.(v)...)
process(d::AbstractDict) = Dict{String,Any}(process(k) => process(v) for (k, v) ∈ d if isenabled(v))
process(b::Bool) = b ? nothing : error("should have been disabled")

# We hide props if `false` or `nothing`, Hyperscript.jl uses `nothing` to
# mean something else (empty prop).
isenabled(🍎) = true
isenabled(b::Bool) = b
isenabled(::Nothing) = false

"""
    Tag(type, props[, promises=(), children=()])

Compile time internal representation of an HTML tag.
"""
struct Tag{T<:Union{AbstractString,Tuple},A<:AbstractDict,P<:Union{AbstractVector,Tuple},C<:Union{AbstractVector,Tuple}}
    type::T
    props::A
    promises::P
    children::C
    Tag(type, props, promises=(), children=()) = new{typeof(type),typeof(props),typeof(promises),typeof(children)}(type, props, promises, children)
end
Base.:(==)(🍍::Tag, 🍌::Tag) = 🍍.type == 🍌.type && 🍍.props == 🍌.props && 🍍.children == 🍌.children

macro htm_str(s)
    htm = parse(s)
    esc(toexpr(htm))
end

toexpr(🍎) = 🍎
@inline function toexpr(🍍::Tag)
    type = toexpr(🍍.type)
    type isa AbstractString || (type = :(process($(type))))

    if !isempty(🍍.props)
        props = toexpr(🍍.props)
        if !isempty(🍍.promises)
            promises = toexpr(🍍.promises)
            props = :(merge($(props), $(promises)...))
        end
        props = :(process($(props)))
    elseif !isempty(🍍.promises)
        promises = toexpr(🍍.promises)
        props = :(merge($(promises)...))
        props = :(process($(props)))
    else
        props = ()
    end

    if !isempty(🍍.children)
        children = toexpr(🍍.children)
        # (children = :(process($(children))))
    else
        children = ()
    end

    return :(create_element($(type), $(props), $(children)))
end
@inline toexpr(s::AbstractString) = startswith(s, '$') ? Meta.parse(s[nextind(s, begin):end]) : s
@inline toexpr(v::Union{AbstractVector,Tuple}) = :(($(toexpr.(v)...),))
@inline toexpr(d::AbstractDict) = :(Dict($(toexpr(collect(d)))))
@inline toexpr(p::Pair) = :($(toexpr(first(p))) => $(toexpr(last(p))))

"""
    parse(io::IO)
    parse(s::AbstractString)

Parse HTML.
"""
@inline function parse(io::IO)
    elems = parseelems(io)
    isempty(elems) && return nothing
    length(elems) == 1 && return only(elems)
    return elems
end
@inline parse(s::AbstractString) = parse(IOBuffer(s))

# --- HTML specification ---

"""
    parseelems(io::IO)

Parse HTML elements.

This function is the entry point for an implementation of a subset of the
[HTML standard](https://html.spec.whatwg.org/multipage/parsing.html#tokenization).
"""
@inline parseelems(io::IO) = parseelems(io -> true, io)
@inline parseelems(predicate, io::IO) = parseelems!(predicate, io, [])
@inline function parseelems!(predicate, io::IO, elems::Union{AbstractVector,Tuple})
    while !eof(io) && predicate(io)
        push!(elems, parseelem(io))
    end
    return elems
end

"""
    parseelem(io::IO)

Parse a single HTML element.
"""
@inline function parseelem(io::IO)
    startswith(io, '<') && return parsetag(io)
    skipstartswith(io, "\\\$") && return '$'
    return parseinterp(🍒 -> 🍒 ∈ ('<', '$', '\\'), io)
end

"""
    parsetag(io::IO)

Parse a `Tag` object.
"""
@inline function parsetag(io::IO)
    skipchars(isequal('<'), io)
    type = skipstartswith(io, "\\\$") ? ('$', parsetagtype(io)) : parsetagtype(io)
    props, promises = parseprops(io)
    if read(io, Char) === '/'
        skipchars(isequal('>'), io)
        return Tag(type, props, promises)
    end
    endtag = "</$(type)>"
    children = parseelems(io -> !startswith(io, endtag), io)
    skipstartswith(io, endtag) || error("tag not properly closed")
    return Tag(type, props, promises, children)
end

"""
    parsetagtype(io::IO)

Parse an HTML tag type.
"""
@inline parsetagtype(io::IO) = readuntil(🍒 -> isspace(🍒) || 🍒 ∈ ('>', '/'), io)

"""
    parseprops(io::IO)

Parse HTML properties of a tag.
"""
@inline parseprops(io::IO) = parseprops!(io, Dict(), String[])
@inline function parseprops!(io::IO, props::AbstractDict, promises::Union{AbstractVector,Tuple})
    while !eof(io)
        skipchars(isspace, io)
        startswith(io, ('>', '/')) && break
        startswith(io, '$') ? push!(promises, parseinterp(io)) : (props = parseprop!(io, props))
    end
    return props, promises
end
@inline function parseprop!(io::IO, props::AbstractDict)
    key = skipstartswith(io, "\\\$") ? ('$', parsekey(io)) : parsekey(io)
    eof(io) && (props[key] = true; return)
    let 🍒 = read(io, Char)
        props[key] = 🍒 === '=' ? parsevalue(io) : true
        🍒 ∈ ('>', '/') && skip(io, -1)
    end
    return props
end

"""
    parsekey(io::IO)

Parse an HTML property key.
"""
@inline parsekey(io::IO) = readuntil(🍒 -> isspace(🍒) || 🍒 ∈ ('=', '>', '/'), io)

"""
    parsevalue(io::IO)

Parse an HTML property value.
"""
@inline parsevalue(io::IO) = (skipchars(isspace, io); startswith(io, ('"', '\'')) ? parsequotedvalue(io) : parseunquotedvalue(io))
@inline function parsequotedvalue(io::IO)
    🥝 = read(io, Char)
    🧩 = []
    while !(eof(io) || startswith(io, 🥝))
        push!(🧩, skipstartswith(io, "\\\$") ? '$' : parseinterp(🍒 -> 🍒 ∈ (🥝, '$', '\\'), io))
    end
    skipchars(isequal(🥝), io)
    length(🧩) == 1 && return only(🧩)
    return 🧩
end
@inline function parseunquotedvalue(io::IO)
    let f(🍒) = isspace(🍒) || 🍒 ∈ ('>', '/', '$', '\\')
        return skipstartswith(io, "\\\$") ? ('$', readuntil(f, io)) : parseinterp(f, io)
    end
end

raw"""
    parseinterp(io::IO)
    parseinterp(fallback, io::IO)

Parse an interpolation as string, including `$`.

The input must start with `$` if no fallback function is given.
The fallback function is passed to `readuntil` if the input does not start
with `$`.
"""
@inline function parseinterp(io::IO)
    buf = IOBuffer()
    write(buf, read(io, Char))
    (eof(io) || isspace(peek(io, Char))) && return '$'  # frustrated interp
    if startswith(io, '(')
        n = 1
        write(buf, read(io, Char))
        while n > 0
            🍒 = read(io, Char)
            if 🍒 === '('
                n += 1
            elseif 🍒 === ')'
                n -= 1
            end
            write(buf, 🍒)
        end
    else
        write(buf, readuntil(🍒 -> isspace(🍒) || 🍒 ∈ ('<', '>', '/', '"', '\'', '=', '$', '\\'), io))
    end
    return String(take!(buf))
end
@inline parseinterp(fallback, io::IO) = startswith(io, '$') ? parseinterp(io) : readuntil(fallback, io)

end
