module HTM

using Hyperscript

export @htm_str

const UENDTAG = "<//>"

include("utils.jl")

"""
    create_element(tag, attrs[, children...])

Create a Hyperscript.jl element.

This is an alternative syntax and (currently) serves as a rather trivial
abstraction layer inspired by
[`React.createElement`](https://pt-br.reactjs.org/docs/react-api.html#createelement).

```jldoctest
julia> HTM.create_element("div", ["class" => "fruit"], "🍍")
<div class="fruit">🍍</div>
```
"""
@inline create_element(tag, attrs, children...) = Hyperscript.Node(Hyperscript.DEFAULT_HTMLSVG_CONTEXT, tag, children, attrs)

"""
    Node(tag[, attrs, children])

Compile time internal representation of a node.

```jldoctest
julia> HTM.Node(["div"], ["class" => ["fruit"]], ["🍍"])
HTM.Node(["div"], ["class" => ["fruit"]], Union{String, HTM.Node}["🍍"])
```
"""
struct Node
    tag::Vector{String}
    attrs::Vector{Pair{String,Vector{String}}}
    children::Vector{Union{String,HTM.Node}}
    Node(tag, attrs=Pair{String,Vector{String}}[], children=Union{String,HTM.Node}[]) = new(tag, attrs, children)
end
Base.:(==)(🍍::Node, 🍌::Node) = 🍍.tag == 🍌.tag && 🍍.attrs == 🍌.attrs && 🍍.children == 🍌.children

@doc raw"""
    render(x::MyType)

Generic function that defines how a Julia object is rendered.

This should normally return using [`@htm_str`](@ref).

This is an alternative to `Base.show(io::IO, m::MIME"text/html", x)` inspired
by WebIO and should only be redefined when Julia's display system is not
powerful enough for your needs.

```jldoctest
julia> struct Fruit
           name::String
           emoji::Char
       end

julia> HTM.render(🍎::Fruit) = htm"$(🍎.name): <div class=fruit>$(🍎.emoji)</div>"

julia> htm"<p>$(Fruit(\\"pineapple\\", '🍍'))</p>"
<p>pineapple: <div class="fruit">🍍</div></p>
```
"""
@inline render(🍎) = 🍎
@inline render(::Bool) = nothing

@inline rendertag(🍎) = 🍎
@inline rendertag(v::AbstractVector) = string(rendertag.(v)...)
@inline rendertag(v::AbstractVector{T}) where {T<:AbstractString} = *(rendertag.(v)...)


# TODO: REVIEW renderattrs & friends
# TODO: simplify and benchmark things related to renderattrs

@inline rendervalue(🍎) = 🍎
@inline rendervalue(b::Bool) = b ? nothing : error("should have been disabled")  # TODO: can we pass this logic to isenabled? It feels too spread out
@inline rendervalue(v::AbstractVector{T}) where {T<:AbstractString} = *(v...)

@inline isenabled(🍎) = true
@inline isenabled(b::Bool) = b
@inline isenabled(::Nothing) = false
@inline isenabled(p::Pair) = isenabled(last(p))


@inline renderattrs(d::AbstractDict) = renderattrs(collect(d))
@inline renderattrs(v::AbstractVector) = (attrs = Pair{String,Any}[]; foreach(p -> isenabled(p) && pushattr!(attrs, renderattr(p)), v); attrs)  # TODO: better type for attrs?
@inline pushattr!(v::AbstractVector, p::Pair) = push!(v, p)  # TODO: benchmark isenabled here and filter below instead of in renderattrs
@inline pushattr!(v::AbstractVector, p::AbstractVector) = append!(v, p)

@inline renderattr(p::Pair) = renderattr(first(p), last(p))
@inline renderattr(k, v) = renderattr(Val(Symbol(k)), v)  # TODO: use symbols all the way for keys, as we don't interpolate them anyway

# TODO: is it worth using attrs = Pair{Symbol,Any}[]? Benchmark
@inline renderattr(::Val{C}, x) where {C} = string(C) => rendervalue(x)  # no interps in keys: use spread attributes
@inline renderattr(::Val{Symbol()}, d) = renderattrs(d)  # spread attributes

# TODO: support vector of pairs as well
@inline renderattr(::Val{:style}, d::AbstractDict) = "style" => *((string(first(p), ':', last(p), ';') for p in d)...)  # TODO: should we process first/last and not dict? TODO: add space between key/value
@inline renderattr(::Val{:class}, v::AbstractVector) = "class" => *((string(c, ' ') for c in Set(v))...)  # TODO: remove space at the end


# TODO: REVIEW all toexpr...
@inline function toexprmacro(v::AbstractVector)
    length(v) > 1 && return toexpr(v)
    isempty(v) && return nothing
    return toexpr(first(v))
end

@inline function toexpr(🍍::Node)
    tag = isempty(🍍.tag) ? "" : :($(rendertag)($(toexprvec(🍍.tag))))
    attrs = isempty(🍍.attrs) ? Pair{String,Any}[] : :($(renderattrs)($(toexprvec(🍍.attrs))))
    children = isempty(🍍.children) ? Any[] : :($(render)($(toexpr(🍍.children))))
    return :($(create_element)($(tag), $(attrs), $(children)))
end
@inline toexpr(s::AbstractString) = (length(s) > 1 && startswith(s, '$')) ? Meta.parse(s[nextind(s, begin):end]) : s
@inline toexpr(v::AbstractVector) = length(v) == 1 ? :($(toexpr(first(v)))) : toexprvec(v)
@inline toexpr(p::Pair) = (v = last(p); :($(first(p)) => $(length(v) > 1 ? toexpr(v) : toexpr(first(v)))))  # no interps in keys

@inline toexprvec(v::AbstractVector) = :([$(toexpr.(v)...)])  # TODO: should use reduce(vcat, v)?

"""
    @htm_str

Create a DOM object from a literal string.

Parsing is done via [`HTM.parse`](@ref).
"""
macro htm_str(s)
    htm = parse(s)
    esc(toexprmacro(htm))
end

@doc raw"""
    parse(s::AbstractString)
    parse(io::IO)

Parse a literal string.

```jldoctest
julia> HTM.parse("pineapple: <div class=\\"fruit\\">🍍</div>...")
3-element Vector{Union{String, HTM.Node}}:
 "pineapple: "
 HTM.Node(["div"], ["class" => ["fruit"]], Union{String, HTM.Node}["🍍"])
 "..."
```
"""
@inline parse(io::IO) = parseelems(io)
@inline parse(s::AbstractString) = parse(IOBuffer(s))

@doc raw"""
    parseelems(io::IO)

Parse elements.

This function is the entry point for an implementation of a subset of the
[HTML standard](https://html.spec.whatwg.org/multipage/parsing.html#tokenization).

```jldoctest
julia> HTM.parseelems(IOBuffer("pineapple: <div class=\\"fruit\\">🍍</div>..."))
3-element Vector{Union{String, HTM.Node}}:
 "pineapple: "
 HTM.Node(["div"], ["class" => ["fruit"]], Union{String, HTM.Node}["🍍"])
 "..."
```
"""
@inline parseelems(io::IO) = parseelems(io -> true, io)
@inline parseelems(predicate, io::IO) = parseelems!(predicate, io, Union{String,HTM.Node}[])
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

Parse a single element.

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

Parse an [`HTM.Node`](@ref) object.

```jldoctest
julia> HTM.parsenode(IOBuffer("<div class=\\"fruit\\">🍍</div>..."))
HTM.Node(["div"], ["class" => ["fruit"]], Union{String, HTM.Node}["🍍"])
```
"""
@inline function parsenode(io::IO)
    skipchars(isequal('<'), io)
    tag = parsetag(io)
    attrs = parseattrs(io)
    read(io, Char) === '/' && (skipchars(isequal('>'), io); return Node(tag, attrs))
    endtag = string("</", rendertag(tag), '>')
    children = parseelems(io -> !(startswith(io, endtag) || startswith(io, UENDTAG)), io)
    skipstartswith(io, endtag) || skipstartswith(io, UENDTAG) || error("tag not properly closed")
    return Node(tag, attrs, children)
end

@doc raw"""
    parsetag(io::IO)

Parse a tag.

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

Parse attributes of a node.

```jldoctest
julia> HTM.parseattrs(IOBuffer("class=\\"fruit\\">🍍..."))
1-element Vector{Pair{String, Vector{String}}}:
 "class" => ["fruit"]

julia> HTM.parseattrs(IOBuffer("class=\\"fruit\\" \$(attrs)>🍍..."))
2-element Vector{Pair{String, Vector{String}}}:
 "class" => ["fruit"]
      "" => ["\$(attrs)"]
```
"""
@inline parseattrs(io::IO) = parseattrs!(io, Pair{String,Vector{String}}[])
@inline function parseattrs!(io::IO, attrs::AbstractVector)
    while !eof(io)
        skipchars(isspace, io)
        startswith(io, ('>', '/')) && break
        parseattr!(io, attrs)
    end
    return attrs
end
@inline function parseattr!(io::IO, attrs::AbstractVector)
    eof(io) && return push!(attrs, key => [raw"$(true)"])  # TODO: do we need this? test! this seems like defective input, just throw an error!
    startswith(io, '$') && return push!(attrs, "" => [parseinterp(io)])  # spread attributes
    startswith(io, "\\\$") && skip(io, 1)  # no interps in keys: just ignore escaping
    key = parsekey(io)
    let 🍒 = read(io, Char)
        push!(attrs, key => 🍒 === '=' ? parsevalue(io) : [raw"$(true)"])
        🍒 ∈ ">/" && skip(io, -1)
    end
    return attrs
end

@doc raw"""
    parsekey(io::IO)

Parse an attribute key.

```jldoctest
julia> HTM.parsekey(IOBuffer("class=\\"fruit\\">🍍..."))
"class"
```
"""
@inline parsekey(io::IO) = readuntil(isspace ⩔ ∈("=>/"), io)

@doc raw"""
    parsevalue(io::IO)

Parse an attribute value.

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
The fallback function is passed to `HTM.readuntil` if the input does not start
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
