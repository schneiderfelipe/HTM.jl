abstract type AnyContext end

struct TagContext <: AnyContext end
struct AttributeContext <: AnyContext end
struct NodeContext <: AnyContext end

struct BranchNodeContext <: AnyContext end
struct LeafNodeContext <: AnyContext end
struct ComponentNodeContext <: AnyContext end

struct LeafCommonNodeContext <: AnyContext end

"""
Process and normalize attributes.
"""
processattr(attr::Pair, f) = f(first(attr)) => last(attr)
processattrs(attrs::AbstractVector, f) = map(attr -> processattr(attr, f), attrs)

"""
Check if a string is empty of pure whitespace.
"""
isblank(str) = isempty(str) || isnothing(findfirst(!isspace, str))

"""
Recreate a vector as an expression.
Optionally, apply a function to each element beforehand.
"""
vec2expr(vec::AbstractVector) = :([$(vec...)])
vec2expr(f, vec::AbstractVector) = vec2expr(map(f, vec))

"""
Append if vector, push otherwise.
"""
pushorappend!(arr::AbstractVector, ret) = push!(arr, ret)
pushorappend!(arr::AbstractVector, ret::AbstractVector) = append!(arr, ret)

"""
Push strings only if the last object in the vector is not a string, concatenate otherwise.
This ensures strings are as long as possible.

We also ensure the "\$" thing works properly.
"""
pushexprorstr!(exprs::AbstractVector, expr) = !isnothing(expr) && push!(exprs, expr)
function pushexprorstr!(exprs::AbstractVector, str::AbstractString)
    if !isblank(str)
        if !isempty(exprs) && last(exprs) isa AbstractString
            # Make strings contiguous
            exprs[end] *= str
        else
            # Hack to support "\$"
            push!(exprs, replace(str, "\\\$" => "\$"))
        end
    end
end

"""
Wrap an expression in a try...catch block.
"""
function trycatchexpr(tryexpr, undefvarexpr)
    return Expr(:try,
        Expr(:block,
            tryexpr,
        ),
        :err,
        Expr(:block,  # catch
            Expr(:if,
                :(err isa UndefVarError),
                Expr(:block,  # then
                    undefvarexpr,
                ),
                Expr(:block,  # else
                    :(rethrow()),
                ),
            ),
        ),
    )
end