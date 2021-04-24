module HyperscriptLiteral

# We call `tag` what Hyperscript.jl calls `Node`.
# We call `type` or `tagtype` what Hyperscript.jl calls `tag`.
# We call `props` what Hyperscript.jl calls `attrs`.
using Hyperscript: AbstractNode, Node, DEFAULT_HTMLSVG_CONTEXT, context, tag, children, attrs

export @htm_str

macro htm_str(html)
    htm = parse(html; interp=true)
    esc(toexpr(htm))
end

toexpr(x) = x
toexpr(x::AbstractNode) = (args = map(toexpr, (context(x), tag(x), children(x), attrs(x))); :($(Node)($(args...))))
toexpr(s::AbstractString) = startswith(s, '$') ? Meta.parse(s[nextind(s, begin):end]) : s
toexpr(xs::AbstractVector) = (xs = map(toexpr, xs); :([$(xs...)]))
toexpr(d::AbstractDict) = (d = :(Dict($(toexpr(collect(d))))); :($(postprocess)($(d))))
toexpr(p::Pair) = :($(toexpr(first(p))) => $(toexpr(last(p))))

postprocess(x) = x
postprocess(xs::AbstractVector) = string(map(postprocess, xs)...)
postprocess(d::AbstractDict) = Dict(postprocess(p) for p in d if isenabled(p))
postprocess(p::Pair) = postprocess(first(p)) => postprocess(last(p))
postprocess(x::Bool) = x ? nothing : error("should have been disabled")

# We hide props if `false` or `nothing`, Hyperscript.jl uses `nothing` to
# mean something else (empty prop).
# TODO: suggest change in Hyperscript.jl. 💡
isenabled(x) = true
isenabled(p::Pair) = isenabled(last(p))
isenabled(x::Bool) = x
isenabled(::Nothing) = false

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

# --- HTML specification ---

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
        push!(elems, parseelem(io; interp=interp))
    end
end

"""
    parseelem(io::IO)

Parse a single HTML element.
"""
function parseelem(io::IO; interp::Bool=false)
    # TODO: revisit this implementation after.
    c = peek(io, Char)
    c === '<' && return parsetag(io; interp=interp)
    interp && return c === '$' ? parseinterp(io; interp=interp) : readwhile(c -> c ∉ ('$', '<'), io)
    return readwhile(!isequal('<'), io)
end

"""
    parsetag(io::IO)

Parse an HTML tag.
"""
function parsetag(io::IO; interp::Bool=false)
    type = parsetagtype(io; interp=interp)
    props = parseprops(io; interp=interp)
    read(io, Char) === '/' && return create_element(type, props)

    endtag = "</$(type)>"
    children = parseelems(io; interp=interp) do io
        !beginswith(io, endtag)
    end
    skip(io, length(endtag))
    return create_element(type, props, children...)
end

"""
    parsetagtype(io::IO)

Parse an HTML tag name.
"""
function parsetagtype(io::IO; interp::Bool=false)
    skipchars(isequal('<'), io)
    return readwhile(io) do c
        !isspace(c) && c ∉ ('/', '>')
    end
end

"""
    parseprops(io::IO)

Parse HTML props/attributes of a tag.
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
        eof(io) && (props[key] = nothing; break)

        c = read(io, Char)
        props[key] = c === '=' ? parsevalue(io; interp=interp) : nothing
        c ∈ ('/', '>') && (skip(io, -1); break)
    end
end

"""
    parsekey(io::IO)

Parse an HTML prop/attribute key.
"""
function parsekey(io::IO; interp::Bool=false)
    return readwhile(io) do c
        !isspace(c) && c ∉ ('/', '>', '=')
    end
end

"""
    parsevalue(io::IO)

Parse an HTML prop/attribute value.
"""
function parsevalue(io::IO; interp::Bool=false)
    skipchars(isspace, io)
    return peek(io, Char) ∈ ('"', '\'') ? parsequotedvalue(io; interp=interp) : parseunquotedvalue(io; interp=interp)
end
function parsequotedvalue(io::IO; interp::Bool=false)
    q = read(io, Char)
    !interp && return readuntil(io, q)

    pieces = Any[]
    while !eof(io) && peek(io, Char) != q
        push!(pieces, peek(io, Char) === '$' ? parseinterp(io; interp=interp) : readwhile(c -> c ∉ ('$', q), io))
    end
    skipchars(isequal(q), io)
    return pieces
end
parseunquotedvalue(io::IO; interp::Bool=false) = (interp && peek(io, Char) === '$') ? parseinterp(io; interp=interp) : readwhile(c ->  !isspace(c) && c != '>', io)

raw"""
    parseinterp(io::IO)

Parse an interpolation as string, including `$`.
"""
function parseinterp(io::IO; interp::Bool=false)
    buffer = IOBuffer()
    write(buffer, read(io, Char))
    (eof(io) || isspace(peek(io, Char))) && return '$'  # frustrated interp returns `Char`

    if peek(io, Char) === '('
        count = 1
        write(buffer, read(io, Char))

        while count > 0
            c = read(io, Char)
            if c === '('
                count += 1
            elseif c === ')'
                count -= 1
            end
            write(buffer, c)
        end
    else
        write(buffer, readwhile(c -> !isspace(c) && c != '<', io))
    end
    return String(take!(buffer))
end

# --- Utilities ---

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