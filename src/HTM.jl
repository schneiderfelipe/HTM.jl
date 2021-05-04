module HTM

using Hyperscript

export @htm_str

const UNIVERSALENDTAG = "<//>"

include("utils.jl")

"""
    create_element(tag, attrs[, children...])

Create a Hyperscript.jl element.

This is an alternative syntax and (currently) serves as a rather trivial
absctraction layer inspired by
[`React.createElement`](https://pt-br.reactjs.org/docs/react-api.html#createelement).

```jldoctest
julia> HTM.create_element("div", Dict("class" => "fruit"), "🍍")
<div class="fruit">🍍</div>
```
"""
@inline create_element(tag, attrs, children...) = Hyperscript.Node(Hyperscript.DEFAULT_HTMLSVG_CONTEXT, tag, children, attrs)

"""
    render(x::MyType)

Generic function that defines how a Julia object is rendered.

This should normally return a `HTM.Node` object.

This is an alternative to `show(io::IO, m::MIME"text/html", x)` inspired by
WebIO and should only be redefined when Julia's display system is not
powerful enough for your needs.

```jldoctest
julia> struct MyPlot
           s::Scope
       end

julia> HTM.render(p::MyPlot) = HTM.render(p.s)
```
"""
@inline render(🍎) = 🍎
@inline render(x::Expr) = :($(render)($(x)))  # TODO: retire definitions for Expr and call them in toexpr?
@inline render(b::Bool) = nothing

@inline processtag(🍎) = 🍎
@inline processtag(x::Expr) = :($(processtag)($(x)))
@inline processtag(v::AbstractVector) = string(processtag.(v)...)
@inline processtag(v::AbstractVector{T}) where {T<:AbstractString} = *(processtag.(v)...)

@inline processattrs(🍎) = 🍎
# TODO: this merge is a pain. What I want:
# - say goodbye to promises and use a single variable for attributes
# - this variable should be able to hold pairs, dicts, etc. and create a dict
# in order
# - this will ensure we can support precedence (currently spread attributes
# always take precedence, no matter where they are given.
# - same philosophy as with tags and children: store objects as they are,
# handle later.
@inline processattrs(x::Expr, p::Expr) = (x = :(merge!($(x), $(p)...)); :($(processattrs)($(x))))  # promises update.
@inline processattrs(b::Bool) = b ? nothing : error("should have been disabled")
@inline processattrs(v::AbstractVector{T}) where {T<:AbstractString} = *(processattrs.(v)...)
@inline processattrs(p::Pair) = (k = first(p); string(k) => processattrs(last(p), Val(Symbol(k))))  # no interps in keys: use spread attributes
@inline processattrs(d::AbstractDict) = Dict(processattrs.(filter(isenabled∘last, collect(d))))

@inline processattrs(🍎, ::Val) = processattrs(🍎)
@inline processattrs(d::AbstractDict, ::Val{:style}) = *((string(first(p), ':', last(p), ';') for p in processattrs(d))...)  # TODO: should we process first/last and not dict? TODO: add space between key/value
@inline processattrs(v::AbstractVector, ::Val{:class}) = *((string(processattrs(c), ' ') for c in Set(v))...)  # TODO: remove space at the end

# Hide attributes if `false` or `nothing`, Hyperscript.jl uses `nothing` to
# mean something else (empty attribute).
@inline isenabled(🍎) = true
@inline isenabled(::Nothing) = false
@inline isenabled(b::Bool) = b

"""
    Node(tag, attrs, promises=String[], children=Union{String, HTM.Node}[])

Compile time internal representation of an HTML node.

```jldoctest
julia> HTM.Node(["div"], Dict("class" => ["fruit"]), [], ["🍍"])
HTM.Node(["div"], Dict("class" => ["fruit"]), String[], Union{String, HTM.Node}["🍍"])
```
"""
struct Node
    tag::Vector{String}
    attrs::Dict{String,Vector{String}}
    promises::Vector{String}
    children::Vector{Union{String, HTM.Node}}
    Node(tag, attrs, promises=String[], children=Union{String, HTM.Node}[]) = new(tag, attrs, promises, children)
end
Base.:(==)(🍍::Node, 🍌::Node) = 🍍.tag == 🍌.tag && 🍍.attrs == 🍌.attrs && 🍍.promises == 🍌.promises && 🍍.children == 🍌.children

macro htm_str(s)
    htm = parse(s)
    esc(toexprmacro(htm))
end

@inline function toexprmacro(v::AbstractVector)
    length(v) > 1 && return toexpr(v)
    isempty(v) && return nothing
    return toexpr(first(v))
end

@inline function toexpr(🍍::Node)
    # TODO: can tag be empty? See <https://pt-br.reactjs.org/docs/fragments.html#short-syntax> for a usage.
    tag = isempty(🍍.tag) ? "" : processtag(toexprvec(🍍.tag))
    attrs = (isempty(🍍.attrs) && isempty(🍍.promises)) ? Dict{String,Any}() : processattrs(toexpr(🍍.attrs), toexprvec(🍍.promises))
    children = isempty(🍍.children) ? Any[] : render(toexpr(🍍.children))
    return :($(create_element)($(tag), $(attrs), $(children)))
end
@inline toexpr(s::AbstractString) = (length(s) > 1 && startswith(s, '$')) ? Meta.parse(s[nextind(s, begin):end]) : s
@inline toexpr(v::AbstractVector) = length(v) == 1 ? :($(toexpr(first(v)))) : toexprvec(v)
@inline toexpr(p::Pair) = (v = last(p); :($(first(p)) => $(length(v) > 1 ? toexpr(v) : toexpr(first(v)))))  # no interps in keys
@inline toexpr(d::AbstractDict) = :(Dict($(toexpr(collect(d)))))

@inline toexprvec(v::AbstractVector) = :([$(toexpr.(v)...)])

@doc raw"""
    parse(s::AbstractString)
    parse(io::IO)

Parse HTML.

```jldoctest
julia> HTM.parse("pineapple: <div class=\\"fruit\\">🍍</div>...")
3-element Vector{Union{String, HTM.Node}}:
 "pineapple: "
 HTM.Node(["div"], Dict("class" => ["fruit"]), String[], Union{String, HTM.Node}["🍍"])
 "..."
```
"""
@inline parse(io::IO) = parseelems(io)
@inline parse(s::AbstractString) = parse(IOBuffer(s))

# --- HTML specification ---

@doc raw"""
    parseelems(io::IO)

Parse HTML elements.

This function is the entry point for an implementation of a subset of the
[HTML standard](https://html.spec.whatwg.org/multipage/parsing.html#tokenization).

```jldoctest
julia> HTM.parseelems(IOBuffer("pineapple: <div class=\\"fruit\\">🍍</div>..."))
3-element Vector{Union{String, HTM.Node}}:
 "pineapple: "
 HTM.Node(["div"], Dict("class" => ["fruit"]), String[], Union{String, HTM.Node}["🍍"])
 "..."
```
"""
@inline parseelems(io::IO) = parseelems(io -> true, io)
@inline parseelems(predicate, io::IO) = parseelems!(predicate, io, Union{String, HTM.Node}[])
@inline function parseelems!(predicate, io::IO, elems::AbstractVector)
    while !eof(io) && predicate(io)
        skipcomment(io) || pushelem!(elems, parseelem(io))
    end
    return elems
end
@inline pushelem!(elems::AbstractVector, elem) = push!(elems, elem)
@inline pushelem!(elems::AbstractVector, elem::AbstractString) = (isempty(elem) || all(isspace, elem)) ? elems : push!(elems, elem)  # TODO: detect all spaces during reading for performance

@doc raw"""
    parseelem(io::IO)

Parse a single HTML element.

```jldoctest
julia> HTM.parseelem(IOBuffer("pineapple: <div class=\\"fruit\\">🍍</div>..."))
"pineapple: "
```
"""
@inline function parseelem(io::IO)
    startswith(io, '<') && return parsenode(io)
    skipstartswith(io, "\\\$") && return "\$"  # frustrated interp
    return parseinterp(∈("<\$\\"), io)
end

@doc raw"""
    skipcomment(io::IO)

Skip a comment if any.

```jldoctest
julia> io = IOBuffer("<!-- 🍌 -->🍍");

julia> HTM.skipcomment(io)
true

julia> read(io, Char)
'🍍': Unicode U+1F34D (category So: Symbol, other)
```
"""
@inline function skipcomment(io::IO)
    if skipstartswith(io, "<!--")
        while !(eof(io) || skipstartswith(io, "-->"))
            skip(io, 1)
        end
        return true
    end
    return false
end

@doc raw"""
    parsenode(io::IO)

Parse a `Node` object.

```jldoctest
julia> HTM.parsenode(IOBuffer("<div class=\\"fruit\\">🍍</div>..."))
HTM.Node(["div"], Dict("class" => ["fruit"]), String[], Union{String, HTM.Node}["🍍"])
```
"""
@inline function parsenode(io::IO)
    skipchars(isequal('<'), io)
    tag = parsetag(io)
    attrs, promises = parseattrs(io)
    read(io, Char) === '/' && (skipchars(isequal('>'), io); return Node(tag, attrs, promises))
    endtag = string("</", processtag(tag), '>')
    children = parseelems(io -> !(startswith(io, endtag) || startswith(io, UNIVERSALENDTAG)), io)
    skipstartswith(io, endtag) || skipstartswith(io, UNIVERSALENDTAG) || error("tag not properly closed")
    return Node(tag, attrs, promises, children)
end

@doc raw"""
    parsetag(io::IO)

Parse an HTML tag.

```jldoctest
julia> HTM.parsetag(IOBuffer("div class=\\"fruit\\">🍍..."))
1-element Vector{String}:
 "div"
```
"""
@inline function parsetag(io::IO)
    🧩 = String[]
    while !(eof(io) || (🍒 = peek(io, Char)) |> isspace || 🍒 ∈ ">/")
        push!(🧩, skipstartswith(io, "\\\$") ? "\$" : parseinterp(isspace ⩔ ∈(">/\$\\"), io))
    end
    return 🧩
end

@doc raw"""
    parseattrs(io::IO)

Parse HTML attributes of a node.
The returned tuple contains both true attributes and promisses.

```jldoctest
julia> HTM.parseattrs(IOBuffer("class=\\"fruit\\">🍍..."))
(Dict("class" => ["fruit"]), String[])

julia> HTM.parseattrs(IOBuffer("class=\\"fruit\\" \$(attrs)>🍍..."))
(Dict("class" => ["fruit"]), ["\$(attrs)"])
```
"""
@inline parseattrs(io::IO) = parseattrs!(io, Dict{String,Vector{String}}(), String[])
@inline function parseattrs!(io::IO, attrs::AbstractDict, promises::AbstractVector)
    while !eof(io)
        skipchars(isspace, io)
        startswith(io, ('>', '/')) && break
        startswith(io, '$') ? push!(promises, parseinterp(io)) : (attrs = parseattr!(io, attrs))
    end
    return attrs, promises
end
@inline function parseattr!(io::IO, attrs::AbstractDict)
    startswith(io, "\\\$") && skip(io, 1)  # no interps in keys: just ignore escaping
    key = parsekey(io)
    eof(io) && (attrs[key] = [raw"$(true)"]; return attrs)
    let 🍒 = read(io, Char)
        attrs[key] = 🍒 === '=' ? parsevalue(io) : [raw"$(true)"]
        🍒 ∈ ">/" && skip(io, -1)
    end
    return attrs
end

@doc raw"""
    parsekey(io::IO)

Parse an HTML attribute key.

```jldoctest
julia> HTM.parsekey(IOBuffer("class=\\"fruit\\">🍍..."))
"class"
```
"""
@inline parsekey(io::IO) = readuntil(isspace ⩔ ∈("=>/"), io)

@doc raw"""
    parsevalue(io::IO)

Parse an HTML attribute value.

```jldoctest
julia> HTM.parsevalue(IOBuffer("\\"fruit\\">🍍..."))
1-element Vector{String}:
 "fruit"
```
"""
@inline parsevalue(io::IO) = startswith(io, ('"', '\'')) ? parsequotedvalue(io) : parseunquotedvalue(io)
@inline function parsequotedvalue(io::IO)
    🥝 = read(io, Char)
    🧩 = String[]
    while !(eof(io) || startswith(io, 🥝))
        push!(🧩, skipstartswith(io, "\\\$") ? "\$" : parseinterp(∈((🥝, '$', '\\')), io))
    end
    skipchars(isequal(🥝), io)
    return 🧩
end
@inline function parseunquotedvalue(io::IO)
    startswith(io, "http") && return [parseinterp(isspace ⩔ isequal('>'), io)]
    let f = isspace ⩔ ∈(">/\$\\")
        return skipstartswith(io, "\\\$") ? ["\$", readuntil(f, io)] : [parseinterp(f, io)]
    end
end

@doc raw"""
    parseinterp(io::IO)
    parseinterp(fallback, io::IO)

Parse an interpolation as string, including `$`.

The input must start with `$` if no fallback function is given.
The fallback function is passed to `readuntil` if the input does not start
with `$`.

```jldoctest
julia> HTM.parseinterp(IOBuffer(raw"$((1, (2, 3)))..."))
"\$((1, (2, 3)))"
```
"""
@inline function parseinterp(io::IO)
    buf = IOBuffer()
    write(buf, read(io, Char))
    (eof(io) || isspace(peek(io, Char))) && return "\$"  # frustrated interp
    # TODO: should we call Meta.parse here and avoid this while? This would
    # require returning Expr, which might be good for removing some duty from
    # strings.
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
        write(buf, readuntil(isspace ⩔ ∈("<>/\"\'=\$\\"), io))
    end
    return String(take!(buf))
end
@inline parseinterp(fallback, io::IO) = startswith(io, '$') ? parseinterp(io) : readuntil(fallback, io)

end
