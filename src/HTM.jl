module HTM

using Hyperscript

export create_element
export processtag, processattrs, processchildren
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
julia> create_element("div", Dict("class" => "fruit"), "🍍")
<div class="fruit">🍍</div>
```
"""
@inline create_element(tag, attrs, children...) = Hyperscript.Node(Hyperscript.DEFAULT_HTMLSVG_CONTEXT, tag, children, attrs)

@inline processtag(🍎) = 🍎
@inline processtag(x::Expr) = :(processtag($(x)))
@inline processtag(v::Union{AbstractVector,Tuple}) = string(processtag.(v)...)

@inline processchildren(🍎) = 🍎
@inline processchildren(x::Expr) = :(processchildren($(x)))

@inline processattrs(🍎) = 🍎
@inline processattrs(x::Expr, p::Expr) = (x = :(merge!($(x), $(p)...)); :(processattrs($(x))))  # Promises update.
@inline processattrs(b::Bool) = b ? nothing : error("should have been disabled")
@inline processattrs(v::Union{AbstractVector,Tuple}) = string(processattrs.(v)...)
@inline processattrs(p::Pair) = (k = processattrs(first(p)); k => processattrs(last(p), Val(Symbol(k))))
@inline processattrs(d::AbstractDict) = Dict(processattrs.(filter(isenabled∘last, collect(d))))

@inline processattrs(🍎, ::Val) = processattrs(🍎)
@inline processattrs(d::AbstractDict, ::Val{:style}) = join(("$(first(p)):$(last(p))" for p in processattrs(d)), ';')

# Hide attrs if `false` or `nothing`, Hyperscript.jl uses `nothing` to
# mean something else (empty attr).
@inline isenabled(🍎) = true
@inline isenabled(b::Bool) = b
@inline isenabled(::Nothing) = false

"""
    Node(tag, attrs[, promises=(), children=()])

Compile time internal representation of an HTML node.

```jldoctest
julia> HTM.Node("div", Dict("class" => "fruit"), (), ("🍍",))
HTM.Node{String, Dict{String, String}, Tuple{}, Tuple{String}}("div", Dict("class" => "fruit"), (), ("🍍",))
```
"""
struct Node{T<:Union{AbstractString,AbstractVector,Tuple},A<:AbstractDict,P<:Union{AbstractVector,Tuple},C<:Union{AbstractVector,Tuple}}
    tag::T  # TODO: can tag be empty? See <https://pt-br.reactjs.org/docs/fragments.html#short-syntax> for a usage.
    attrs::A
    promises::P
    children::C
    Node(tag, attrs, promises=(), children=()) = new{typeof(tag),typeof(attrs),typeof(promises),typeof(children)}(tag, attrs, promises, children)
end
Base.:(==)(🍍::Node, 🍌::Node) = 🍍.tag == 🍌.tag && 🍍.attrs == 🍌.attrs && all(🍍.promises .== 🍌.promises) && all(🍍.children .== 🍌.children)

macro htm_str(s)
    htm = parse(s)
    esc(toexpr(htm))
end

@inline toexpr(🍎) = 🍎
@inline function toexpr(🍍::Node)
    tag = !isempty(🍍.tag) ? processtag(toexpr(🍍.tag)) : ""
    attrs = !(isempty(🍍.attrs) && isempty(🍍.promises)) ? processattrs(toexpr(🍍.attrs), toexpr(🍍.promises)) : ()
    children = !isempty(🍍.children) ? processchildren(toexpr(🍍.children)) : ()
    :(create_element($(tag), $(attrs), $(children)))
end
@inline toexpr(s::AbstractString) = (length(s) > 1 && startswith(s, '$')) ? Meta.parse(s[nextind(s, begin):end]) : s
@inline toexpr(v::Union{AbstractVector,Tuple}) = :(($(toexpr.(v)...),))
@inline toexpr(p::Pair) = :($(toexpr(first(p))) => $(toexpr(last(p))))
@inline toexpr(d::AbstractDict) = :(Dict($(toexpr(collect(d)))))

@doc raw"""
    parse(s::AbstractString)
    parse(io::IO)

Parse HTML.

```jldoctest
julia> HTM.parse("pineapple: <div class=\\"fruit\\">🍍</div>...")
3-element Vector{Any}:
 "pineapple: "
 HTM.Node{String, Dict{Any, Any}, Vector{String}, Vector{Any}}("div", Dict{Any, Any}("class" => "fruit"), String[], Any["🍍"])
 "..."
```
"""
@inline function parse(io::IO)
    elems = parseelems(io)
    isempty(elems) && return nothing
    length(elems) == 1 && return first(elems)
    return elems
end
@inline parse(s::AbstractString) = parse(IOBuffer(s))  # Warning: parse returns Any

# --- HTML specification ---

@doc raw"""
    parseelems(io::IO)

Parse HTML elements.

This function is the entry point for an implementation of a subset of the
[HTML standard](https://html.spec.whatwg.org/multipage/parsing.html#tokenization).

```jldoctest
julia> HTM.parseelems(IOBuffer("pineapple: <div class=\\"fruit\\">🍍</div>..."))
3-element Vector{Any}:
 "pineapple: "
 HTM.Node{String, Dict{Any, Any}, Vector{String}, Vector{Any}}("div", Dict{Any, Any}("class" => "fruit"), String[], Any["🍍"])
 "..."
```
"""
@inline parseelems(io::IO) = parseelems(io -> true, io)
@inline parseelems(predicate, io::IO) = parseelems!(predicate, io, Any[])
@inline function parseelems!(predicate, io::IO, elems::Union{AbstractVector,Tuple})
    while !eof(io) && predicate(io)
        pushelem!(elems, parseelem(io))
    end
    return elems
end
@inline pushelem!(elems::AbstractVector, elem) = push!(elems, elem)  # Warning: pushelem! returns Union{Bool, Vector{Any}}
@inline pushelem!(elems::AbstractVector, elem::AbstractString) = isempty(elem) || all(isspace, elem) || push!(elems, elem)  # TODO: detect all spaces during reading for performance

@doc raw"""
    parseelem(io::IO)

Parse a single HTML element.

```jldoctest
julia> HTM.parseelem(IOBuffer("pineapple: <div class=\\"fruit\\">🍍</div>..."))
"pineapple: "
```
"""
@inline function parseelem(io::IO)  # Warning: parseelem returns Union{String, HTM.Node{T, Dict{Any, Any}, Vector{String}, C} where {T<:Union{AbstractString, Tuple, AbstractVector{T} where T}, C<:Union{Tuple, AbstractVector{T} where T}}}
    startswith(io, '<') && return parsenode(io)
    skipstartswith(io, "\\\$") && return "\$"  # frustrated interp
    return parseinterp(∈("<\$\\"), io)
end

@doc raw"""
    parsenode(io::IO)

Parse a `Node` object.

```jldoctest
julia> HTM.parsenode(IOBuffer("<div class=\\"fruit\\">🍍</div>..."))
HTM.Node{String, Dict{Any, Any}, Vector{String}, Vector{Any}}("div", Dict{Any, Any}("class" => "fruit"), String[], Any["🍍"])
```
"""
@inline function parsenode(io::IO)
    skipchars(isequal('<'), io)
    tag = parsetag(io)
    attrs, promises = parseattrs(io)
    if read(io, Char) === '/'
        skipchars(isequal('>'), io)
        return Node(tag, attrs, promises)
    end
    endtag = "</$(processtag(tag))>"
    children = parseelems(io -> !(startswith(io, endtag) || startswith(io, UNIVERSALENDTAG)), io)
    skipstartswith(io, endtag) || skipstartswith(io, UNIVERSALENDTAG) || error("tag not properly closed")
    return Node(tag, attrs, promises, children)
end

@doc raw"""
    parsetag(io::IO)

Parse an HTML tag.

```jldoctest
julia> HTM.parsetag(IOBuffer("div class=\\"fruit\\">🍍..."))
"div"
```
"""
@inline function parsetag(io::IO)
    🧩 = String[]
    while !(eof(io) || (🍒 = peek(io, Char)) |> isspace || 🍒 ∈ ">/")
        push!(🧩, skipstartswith(io, "\\\$") ? "\$" : parseinterp(isspace ⩔ ∈(">/\$\\"), io))
    end
    length(🧩) == 1 && return first(🧩)  # Warning: parsetag returns Union{String, Vector{String}}
    return 🧩
end

@doc raw"""
    parseattrs(io::IO)

Parse HTML attributes of a node.
The returned tuple contains both true attributes and promisses.

```jldoctest
julia> HTM.parseattrs(IOBuffer("class=\\"fruit\\">🍍..."))
(Dict{Any, Any}("class" => "fruit"), String[])

julia> HTM.parseattrs(IOBuffer("class=\\"fruit\\" \$(attrs)>🍍..."))
(Dict{Any, Any}("class" => "fruit"), ["\$(attrs)"])
```
"""
@inline parseattrs(io::IO) = parseattrs!(io, Dict{Any,Any}(), String[])  # Warning: attrs is assigned as Dict{Any, Any}
@inline function parseattrs!(io::IO, attrs::AbstractDict, promises::Union{AbstractVector,Tuple})
    while !eof(io)
        skipchars(isspace, io)
        startswith(io, ('>', '/')) && break
        startswith(io, '$') ? push!(promises, parseinterp(io)) : (attrs = parseattr!(io, attrs))
    end
    return attrs, promises
end
@inline function parseattr!(io::IO, attrs::AbstractDict)
    key = skipstartswith(io, "\\\$") ? ("\$", parsekey(io)) : parsekey(io)
    eof(io) && (attrs[key] = true; return)  # Warning: attrs is assigned as Union{Nothing, Dict{Any, Any}}
    let 🍒 = read(io, Char)
        attrs[key] = 🍒 === '=' ? parsevalue(io) : true
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
    length(🧩) == 1 && return first(🧩)
    return 🧩
end
@inline function parseunquotedvalue(io::IO)
    startswith(io, "http") && return parseinterp(isspace ⩔ isequal('>'), io)
    let f = isspace ⩔ ∈(">/\$\\")
        return skipstartswith(io, "\\\$") ? ("\$", readuntil(f, io)) : parseinterp(f, io)  # TODO: use parseinterp diretly here and in other places
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
