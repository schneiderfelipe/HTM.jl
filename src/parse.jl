# --- Parsing ---

@doc raw"""
    parse(s::AbstractString)
    parse(io::IO)

Parse a literal string.

```jldoctest
julia> HTM.parse("pineapple: <div class=\\"fruit\\">🍍</div>...")
3-element Vector{Union{String, HTM.Node}}:
 "pineapple: "
 HTM.Node(["div"], [:class => ["fruit"]], Union{String, HTM.Node}["🍍"])
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
 HTM.Node(["div"], [:class => ["fruit"]], Union{String, HTM.Node}["🍍"])
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
HTM.Node(["div"], [:class => ["fruit"]], Union{String, HTM.Node}["🍍"])
```
"""
@inline function parsenode(io::IO)
    skipchars(isequal('<'), io)
    tag = parsetag(io)
    attrs = parseattrs(io)
    read(io, Char) === '/' && (skipchars(isequal('>'), io); return Node(tag, attrs))
    endtag = *("</", create_tag(tag), '>')
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
1-element Vector{Pair{Symbol, Vector{String}}}:
 :class => ["fruit"]

julia> HTM.parseattrs(IOBuffer("class=\\"fruit\\" \$(attrs)>🍍..."))
2-element Vector{Pair{Symbol, Vector{String}}}:
     :class => ["fruit"]
 Symbol("") => ["\$(attrs)"]
```
"""
@inline parseattrs(io::IO) = parseattrs!(io, Pair{Symbol,Vector{String}}[])
@inline function parseattrs!(io::IO, attrs::AbstractVector)
    while !eof(io)
        skipchars(isspace, io)
        startswith(io, ('>', '/')) && break
        parseattr!(io, attrs)
    end
    return attrs
end
@inline function parseattr!(io::IO, attrs::AbstractVector)
    startswith(io, '$') && return push!(attrs, Symbol() => [parseinterp(io)])  # spread attributes
    startswith(io, "\\\$") && skip(io, 1)  # no interps in keys: just ignore escaping
    🔑 = parsekey(io)
    let 🍒 = read(io, Char)
        push!(attrs, 🔑 => 🍒 === '=' ? parsevalue(io) : [raw"$(true)"])
        🍒 ∈ ">/" && skip(io, -1)
    end
    return attrs
end

@doc raw"""
    parsekey(io::IO)

Parse an attribute key.

```jldoctest
julia> HTM.parsekey(IOBuffer("class=\\"fruit\\">🍍..."))
:class
```
"""
@inline parsekey(io::IO) = Symbol(readuntil(isspace ⩔ ∈("=>/"), io))

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
    # TODO: call Meta.parse here and avoid this while. This will require
    # returning Expr, which will remove some duty from strings. This can lead
    # to better decisions when calling create_element by being able to
    # distinguish between strings and expressions, which is currently
    # impossible.
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
