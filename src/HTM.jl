module HTM

using Hyperscript
export @htm_str

const UENDTAG = "<//>"

include("util.jl")
include("parse.jl")

"""
    create_element(tag, attrs[, children...])

Create a DOM element.

This is an alternative syntax and (currently) serves as a rather trivial
abstraction layer inspired by
[`React.createElement`](https://pt-br.reactjs.org/docs/react-api.html#createelement).

```jldoctest
julia> HTM.create_element("div", [:class => "fruit"], "🍍")
<div class="fruit">🍍</div>
```
"""
@inline create_element(tag, attrs, children...) = Hyperscript.Node(Hyperscript.DEFAULT_HTMLSVG_CONTEXT, tag, children, attrs)

"""
    Node(tag[, attrs, children])

Compile time internal representation of a node.

```jldoctest
julia> HTM.Node(["div"], [:class => ["fruit"]], ["🍍"])
HTM.Node(["div"], [:class => ["fruit"]], Union{String, HTM.Node}["🍍"])
```
"""
struct Node
    tag::Vector{String}
    attrs::Vector{Pair{Symbol,Vector{String}}}
    children::Vector{Union{String,HTM.Node}}
    Node(tag, attrs=Pair{Symbol,Vector{String}}[], children=Union{String,HTM.Node}[]) = new(tag, attrs, children)
end
Base.:(==)(🍍::Node, 🍌::Node) = 🍍.tag == 🍌.tag && 🍍.attrs == 🍌.attrs && 🍍.children == 🍌.children

@doc raw"""
    render(x)

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

@inline create_tag(🍎) = 🍎
@inline create_tag(v::AbstractVector) = string(create_tag.(v)...)
@inline create_tag(v::AbstractVector{S}) where {S<:AbstractString} = *(create_tag.(v)...)

@inline create_value(🍎) = 🍎
@inline create_value(b::Bool) = b ? nothing : error("should have been disabled")
@inline create_value(v::AbstractVector{S}) where {S<:AbstractString} = *(v...)

@inline isenabled(🍎) = true
@inline isenabled(b::Bool) = b
@inline isenabled(::Nothing) = false

# TODO: benchmark things related to create_attrs
# TODO: is it worth using attrs = Pair{Symbol,Any}[]? Benchmark!

@inline create_attrs(d::AbstractDict) = create_attrs(collect(d))
@inline create_attrs(v::AbstractVector) = (attrs = Pair{Symbol,Any}[]; foreach(p -> isenabled(last(p)) && pushattr!(attrs, create_attr(p)), v); attrs)  # TODO: choose type as we build the array?
@inline pushattr!(v::AbstractVector, p::AbstractVector) = append!(v, p)
@inline pushattr!(v::AbstractVector, p::Pair) = push!(v, p)  # TODO: benchmark isenabled here and filter below instead of in create_attrs

@inline create_attr(p::Pair) = create_attr(first(p), last(p))
@inline create_attr(🔑::Symbol, v) = create_attr(Val(🔑), v)
@inline create_attr(🔑, v) = create_attr(Symbol(🔑), v)

# attribute fallback
@inline create_attr(::Val{K}, x) where {K} = K => create_value(x)  # no interps in keys: use spread attributes

# spread attributes
@inline create_attr(::Val{Symbol()}, d) = create_attrs(d)

# style attribute
@inline create_attr(::Val{:style}, d::Union{AbstractDict,AbstractVector{Pair{K,V}}}) where {K,V} = :style => *((cssprop(p) for p in d)...)  # TODO: remove last character?
@inline cssprop(p::Pair) = *(first(p), ':', last(p), ';')  # TODO: add space between key/value
@inline cssprop(p::Pair{Symbol,V}) where {V} = cssprop(string(first(p)) => last(p))

# class attribute
@inline create_attr(::Val{:class}, s::AbstractString) = :class => create_value(s)
@inline create_attr(::Val{:class}, m::AbstractSet) = :class => *((*(c, ' ') for c in m)...)  # TODO: adjust spaces around classes?
@inline create_attr(🔑::Val{:class}, v) = create_attr(🔑, Set(v))

"""
    @htm_str

Create a DOM object from a literal string.

Parsing is done via [`HTM.parse`](@ref).
"""
macro htm_str(s)
    htm = parse(s)
    esc(macrotoexpr(htm))
end

# expressions for generic contexts
@inline toexpr(s::AbstractString) = (length(s) > 1 && startswith(s, '$')) ? Meta.parse(s[nextind(s, begin):end]) : s
@inline toexpr(v::AbstractVector) = length(v) === 1 ? :($(toexpr(first(v)))) : vectoexpr(v)
@inline toexpr(p::Pair) = (v = last(p); :($(:(first($(p)))) => $(valtoexpr(last(p)))))  # no interps in keys
@inline toexpr(🍍::Node) = :($(create_element)($(tagtoexpr(🍍.tag)), $(attrstoexpr(🍍.attrs)), $(childrentoexpr(🍍.children))))

# expressions for specific contexts
@inline tagtoexpr(x) = isempty(x) ? "" : :($(create_tag)($(toexpr(x))))
@inline attrstoexpr(x) = isempty(x) ? Pair{Symbol,Any}[] : :($(create_attrs)($(vectoexpr(x))))
@inline childrentoexpr(x) = isempty(x) ? Any[] : :($(render)($(toexpr(x))))

@inline vectoexpr(v::AbstractVector) = :([$(toexpr.(v)...)])  # TODO: should use reduce(vcat, v)? benchmark
@inline valtoexpr(v::AbstractVector) = length(v) > 1 ? toexpr(v) : (isempty(v) ? "" : toexpr(first(v)))
@inline function macrotoexpr(v::AbstractVector)
    length(v) > 1 && return toexpr(v)
    isempty(v) && return nothing
    return toexpr(first(v))
end

end
