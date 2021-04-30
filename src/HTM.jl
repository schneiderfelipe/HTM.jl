module HTM

# We say,            Hyperscript.jl says,
# `tag` or `Tag`      => `Node`
# `type` or `tagtype` => `tag`
# `props` (property)  => `attrs` (attribute)
using Hyperscript: Node, DEFAULT_HTMLSVG_CONTEXT

export create_element
export processtagname, process
export @htm_str

const UNIVERSALENDTAG = "<//>"

include("utils.jl")

"""
    create_element(type, props[, children...])

Create a Hyperscript.jl element.

This is an alternative syntax and (currently) serves as a rather trivial
absctraction layer inspired by
[`React.createElement`](https://pt-br.reactjs.org/docs/react-api.html#createelement).

```jldoctest
julia> create_element("div", Dict("class" => "fruit"), "🍍")
<div class="fruit">🍍</div>
```
"""
create_element(type, props, children...) = Node(DEFAULT_HTMLSVG_CONTEXT, type, children, props)

@inline processtagname(x) = string(process(x))

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

```jldoctest
julia> HTM.Tag("div", Dict("class" => "fruit"), (), ("🍍",))
HTM.Tag{String, Dict{String, String}, Tuple{}, Tuple{String}}("div", Dict("class" => "fruit"), (), ("🍍",))
```
"""
struct Tag{T<:Union{AbstractString,AbstractVector,Tuple},A<:AbstractDict,P<:Union{AbstractVector,Tuple},C<:Union{AbstractVector,Tuple}}
    type::T
    props::A
    promises::P
    children::C
    Tag(type, props, promises=(), children=()) = new{typeof(type),typeof(props),typeof(promises),typeof(children)}(type, props, promises, children)
end
Base.:(==)(🍍::Tag, 🍌::Tag) = 🍍.type == 🍌.type && 🍍.props == 🍌.props && all(🍍.promises .== 🍌.promises) && all(🍍.children .== 🍌.children)

macro htm_str(s)
    htm = parse(s)
    esc(toexpr(htm))
end

toexpr(🍎) = 🍎
@inline function toexpr(🍍::Tag)
    type = toexpr(🍍.type)
    type isa AbstractString || (type = :(processtagname($(type))))

    if !isempty(🍍.props)
        props = toexpr(🍍.props)
        if !isempty(🍍.promises)
            # TODO: this branch has no tests!
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

@doc raw"""
    parse(s::AbstractString)
    parse(io::IO)

Parse HTML.

```jldoctest
julia> HTM.parse("pineapple: <div class=\\"fruit\\">🍍</div>...")
3-element Vector{Any}:
 "pineapple: "
 HTM.Tag{String, Dict{Any, Any}, Vector{String}, Vector{Any}}("div", Dict{Any, Any}("class" => "fruit"), String[], Any["🍍"])
 "..."
```
"""
@inline function parse(io::IO)
    elems = parseelems(io)
    isempty(elems) && return nothing
    length(elems) == 1 && return first(elems)
    return elems
end
@inline parse(s::AbstractString) = parse(IOBuffer(s))

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
 HTM.Tag{String, Dict{Any, Any}, Vector{String}, Vector{Any}}("div", Dict{Any, Any}("class" => "fruit"), String[], Any["🍍"])
 "..."
```
"""
@inline parseelems(io::IO) = parseelems(io -> true, io)
@inline parseelems(predicate, io::IO) = parseelems!(predicate, io, [])
@inline function parseelems!(predicate, io::IO, elems::Union{AbstractVector,Tuple})
    while !eof(io) && predicate(io)
        skipchars(isspace, io)
        pushelem!(elems, parseelem(io))
    end
    return elems
end
pushelem!(elems::AbstractVector, elem) = push!(elems, elem)
pushelem!(elems::AbstractVector, elem::AbstractString) = isempty(elem) || push!(elems, elem)

@doc raw"""
    parseelem(io::IO)

Parse a single HTML element.

```jldoctest
julia> HTM.parseelem(IOBuffer("pineapple: <div class=\\"fruit\\">🍍</div>..."))
"pineapple: "
```
"""
@inline function parseelem(io::IO)
    startswith(io, '<') && return parsetag(io)
    skipstartswith(io, "\\\$") && return '$'
    return parseinterp(🍒 -> 🍒 ∈ ('<', '$', '\\'), io)
end

@doc raw"""
    parsetag(io::IO)

Parse a `Tag` object.

```jldoctest
julia> HTM.parsetag(IOBuffer("<div class=\\"fruit\\">🍍</div>..."))
HTM.Tag{String, Dict{Any, Any}, Vector{String}, Vector{Any}}("div", Dict{Any, Any}("class" => "fruit"), String[], Any["🍍"])
```
"""
@inline function parsetag(io::IO)
    skipchars(isequal('<'), io)
    type = parsetagtype(io)
    props, promises = parseprops(io)
    if read(io, Char) === '/'
        skipchars(isequal('>'), io)
        return Tag(type, props, promises)
    end
    endtag = "</$(processtagname(type))>"
    children = parseelems(io -> !(startswith(io, endtag) || startswith(io, UNIVERSALENDTAG)), io)
    skipstartswith(io, endtag) || skipstartswith(io, UNIVERSALENDTAG) || error("tag not properly closed")
    return Tag(type, props, promises, children)
end

@doc raw"""
    parsetagtype(io::IO)

Parse an HTML tag type.

```jldoctest
julia> HTM.parsetagtype(IOBuffer("div class=\\"fruit\\">🍍..."))
"div"
```
"""
@inline function parsetagtype(io::IO)
    🧩 = Union{Char,String}[]  # TODO: if we make this String[], we get ~20% parse performance improvement!
    while !(eof(io) || (🍒 = peek(io, Char)) |> isspace || 🍒 ∈ ('>', '/'))
        push!(🧩, skipstartswith(io, "\\\$") ? '$' : parseinterp(🍒 -> isspace(🍒) || 🍒 ∈ ('>', '/', '$', '\\'), io))
    end
    length(🧩) == 1 && return first(🧩)
    return 🧩
end

@doc raw"""
    parseprops(io::IO)

Parse HTML properties of a tag.
The returned tuple contains both true properties and promisses.

```jldoctest
julia> HTM.parseprops(IOBuffer("class=\\"fruit\\">🍍..."))
(Dict{Any, Any}("class" => "fruit"), String[])

julia> HTM.parseprops(IOBuffer("class=\\"fruit\\" \$(props)>🍍..."))
(Dict{Any, Any}("class" => "fruit"), ["\$(props)"])
```
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

@doc raw"""
    parsekey(io::IO)

Parse an HTML property key.

```jldoctest
julia> HTM.parsekey(IOBuffer("class=\\"fruit\\">🍍..."))
"class"
```
"""
@inline parsekey(io::IO) = readuntil(🍒 -> isspace(🍒) || 🍒 ∈ ('=', '>', '/'), io)

@doc raw"""
    parsevalue(io::IO)

Parse an HTML property value.

```jldoctest
julia> HTM.parsevalue(IOBuffer("\\"fruit\\">🍍..."))
"fruit"
```
"""
@inline parsevalue(io::IO) = startswith(io, ('"', '\'')) ? parsequotedvalue(io) : parseunquotedvalue(io)
@inline function parsequotedvalue(io::IO)
    🥝 = read(io, Char)
    🧩 = []
    while !(eof(io) || startswith(io, 🥝))
        push!(🧩, skipstartswith(io, "\\\$") ? '$' : parseinterp(🍒 -> 🍒 ∈ (🥝, '$', '\\'), io))
    end
    skipchars(isequal(🥝), io)
    length(🧩) == 1 && return first(🧩)
    return 🧩
end
@inline function parseunquotedvalue(io::IO)
    let f(🍒) = isspace(🍒) || 🍒 ∈ ('>', '/', '$', '\\')
        return skipstartswith(io, "\\\$") ? ('$', readuntil(f, io)) : parseinterp(f, io)
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
