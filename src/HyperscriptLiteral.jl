module HyperscriptLiteral

using Hyperscript: Node, DEFAULT_HTMLSVG_CONTEXT

export @htm_str

macro htm_str(html)
    esc(parse(html; interp=true))
end

"""
    create_element(type::AbstractString)
    create_element(type::AbstractString, children...)
    create_element(type::AbstractString, props::AbstractDict, children...)

Create a Hyperscript.jl element.

This is an alternative syntax and (currently) serves as a rather trivial
absctraction layer inspired by
[`React.createElement`](https://pt-br.reactjs.org/docs/react-api.html#createelement).
"""
create_element(type::AbstractString) = Node(DEFAULT_HTMLSVG_CONTEXT, type, Any[], Dict{String, Any}())
create_element(type::AbstractString, children...) = Node(DEFAULT_HTMLSVG_CONTEXT, type, children, Dict{String, Any}())
create_element(type::AbstractString, props::AbstractDict, children...) = Node(DEFAULT_HTMLSVG_CONTEXT, type, children, props)

"""
    parse(io::IO)
    parse(html::AbstractString)

Parse HTML.
"""
function parse(io::IO; interp::Bool=false)
    elems = parseelems(io; interp=interp)

    isempty(elems) && return nothing
    length(elems) == 1 && return only(elems)
    return elems
end
parse(html::AbstractString; interp::Bool=false) = parse(IOBuffer(html); interp=interp)

# === HTML specification ===

"""
    parseelems(io::IO)

Parse HTML elements.

This function is the entry point for an implementation of a subset of the
[HTML standard](https://html.spec.whatwg.org/multipage/parsing.html#tokenization).
"""
parseelems(io::IO; interp::Bool=false) = parseelems(io -> true, io; interp=interp)
function parseelems(predicate, io::IO; interp::Bool=false)
    elems = Any[]
    parseelems!(predicate, io, elems; interp=interp)

    return elems
end
function parseelems!(predicate, io::IO, elems::AbstractVector; interp::Bool=false)
    while !eof(io) && predicate(io)
        push!(elems, peek(io, Char) == '<' ? parsetag(io; interp=interp) : parsechars(io; interp=interp))
    end
end

"""
    parsechars(io::IO)

Parse a text element.
"""
function parsechars(io::IO; interp::Bool=false)
    chars = readuntil(io, '<')
    !eof(io) && skip(io, -1)

    return chars
end

"""
    parsetag(io::IO)

Parse an HTML tag.
"""
function parsetag(io::IO; interp::Bool=false)
    skipchars(isequal('<'), io)
    type = parsetagname(io; interp=interp)
    props = parseprops(io; interp=interp)

    read(io, Char) == '/' && return create_element(type, props)

    endtag = "</$(type)>"
    children = parseelems(io; interp=interp) do io
        !beginswith(io, endtag)
    end
    skip(io, length(endtag))

    return create_element(type, props, children...)
end

"""
    parsetagname(io::IO)

Parse an HTML tag name.
"""
function parsetagname(io::IO; interp::Bool=false)
    return readwhile(io) do c
        !isspace(c) && c ∉ ('/', '>')
    end
end

"""
    parseprops(io::IO)

Parse HTML attributes of a tag.
"""
function parseprops(io::IO; interp::Bool=false)
    props = Dict{String, Any}()
    parseprops!(io, props; interp=interp)

    return props
end
function parseprops!(io::IO, props::AbstractDict; interp::Bool=false)
    # TODO: revisit this implementation after.
    while !eof(io)
        skipchars(isspace, io)
        peek(io, Char) ∈ ('/', '>') && break

        key = parsekey(io; interp=interp)
        eof(io) && (props[key] = true; break)

        c = read(io, Char)
        props[key] = c == '=' ? parsevalue(io; interp=interp) : true
        c ∈ ('/', '>') && (skip(io, -1); break)
    end
end

"""
    parsekey(io::IO)

Parse an HTML attribute key.
"""
function parsekey(io::IO; interp::Bool=false)
    return readwhile(io) do c
        !isspace(c) && c ∉ ('/', '>', '=')
    end
end

"""
    parsevalue(io::IO)

Parse an HTML attribute value.
"""
function parsevalue(io::IO; interp::Bool=false)
    # TODO: revisit this implementation after.
    skipchars(isspace, io)
    c = peek(io, Char)

    c ∈ ('"', '\'') && (skip(io, 1); return readuntil(io, c))
    return readwhile(!isspace, io)
end

# === Utilities ===

"""
    readwhile(predicate, io::IO)

Read characters matching a predicate.
"""
function readwhile(predicate, io::IO)
    buffer = IOBuffer()
    while !eof(io) && predicate(peek(io, Char))
        write(buffer, read(io, Char))
    end

    return String(take!(buffer))
end

"""
    beginswith(io::IO, prefix::AbstractString)

Check if an `IO` object starts with prefix.
"""
function beginswith(io::IO, prefix::AbstractString)
    pos = position(io)
    start = String(read(io, length(prefix)))
    seek(io, pos)

    return start == prefix
end

end