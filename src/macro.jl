"""
Time to create a macro!

We want to do the following.

# Examples
```jldoctest
julia> htm"<h1>Hello world!</h1>"
<h1>Hello world&#33;</h1>
```
"""
macro htm_str(s)
    htmexpr(s)
end
htmexpr(s::AbstractString) = esc(toexpr(parse(s), NodeContext()))

# Keep any objects in the tree
toexpr(x, ::AnyContext) = x

# Propagate expressions to `:key => value` attributes. The `:key` part is
# treated in TagContext, and the `value` is treated in AttributeContext.
toexpr(pair::Pair, ::AttributeContext) = :($(toexpr(first(pair), TagContext())) => $(toexpr(last(pair), AttributeContext())))

# String interpolate in general in strings.
toexpr(str::AbstractString, ::AnyContext) = Meta.parse("\"$(str)\"")  # Allow string interpolation
toexpr(str::AbstractString, ::AttributeContext) = trycatchexpr(Meta.parse(str), str)  # Probably already contains quotation marks
toexpr(str::AbstractString, ::NodeContext) = toexpr!([], str, NodeContext())
function toexpr!(exprs::AbstractVector, str::AbstractString, ::NodeContext, i::Int=firstindex(str), n::Int=lastindex(str))  # Return a vector of expressions (some are strings)
    j = findnext('$', str, i)
    if !isnothing(j)
        k = nextind(str, j)
    end
    while !isnothing(j) && (j == n || (j < n && isspace(str[k])) || (j > i && str[prevind(str, j)] == '\\'))
        # We ignore the '$' if 1. there's no char next or it is whitespace or 2. if the previous char is a '\'
        j = findnext('$', str, k)
        if !isnothing(j)
            k = nextind(str, j)
        end
    end

    if isnothing(j)
        # Last string
        candidate = str[i:n]
    else
        # String before next code
        candidate = str[i:prevind(str, j)]
    end

    pushexprorstr!(exprs, candidate)

    if isnothing(j)
        length(exprs) == 1 && return first(exprs)
        return exprs
    end

    expr, i = try
        Meta.parse(str, k, greedy=false)
    catch err
        if err isa Meta.ParseError
            # We ignore code that fails to parse, similar to how @md_str behaves
            "\$", k
        else
            rethrow()
        end
    end

    pushexprorstr!(exprs, expr)
    return toexpr!(exprs, str, NodeContext(), i, n)
end

# Propagate expression generation to vectors, but keep code-generated objects
# next to its context.
toexpr(vec::AbstractVector, context::AnyContext) = vec2expr(x -> toexpr(x, context), vec)
function toexpr(vec::AbstractVector, ::NodeContext)
    arr = Union{Expr,String,Symbol}[]  # Do we need more types?
    for v in vec
        pushorappend!(arr, toexpr(v, NodeContext()))
    end
    return vec2expr(arr)
end
