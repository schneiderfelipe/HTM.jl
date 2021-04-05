abstract type AbstractContext end
struct DefaultContext <: AbstractContext end
struct LeafContext <: AbstractContext end
struct BranchContext <: AbstractContext end
struct CodeContext <: AbstractContext end
struct LeafCodeContext <: AbstractContext end
struct CommonLeafCodeContext <: AbstractContext end
struct CommonContext <: AbstractContext end

struct AttributeContext <: AbstractContext end

Base.:+(::LeafContext, ::CodeContext) = LeafCodeContext()
Base.:+(::CodeContext, ::LeafContext) = LeafCodeContext()
Base.:+(::LeafCodeContext, ::CommonContext) = CommonLeafCodeContext()
Base.:+(::CommonContext, ::LeafCodeContext) = CommonLeafCodeContext()

"""
Time to create a macro!

We want to do the following.

# Examples
```jldoctest
julia> htm"<h1>Hello world!</h1>"
```
"""
macro htm_str(s)
	htmexpr(s)
end
htmexpr(s::AbstractString) = esc(toexpr(parse(s), CodeContext()))

# Keep any objects in the tree.
toexpr(x, ::AbstractContext) = x

# Propagate expression generation to vectors, but keep code-generated objects
# next to its context.
toexpr(vec::AbstractVector, context::AbstractContext) = vec2expr(x -> toexpr(x, context), vec)
function toexpr(vec::AbstractVector, context::CodeContext)
	arr = Union{Expr,String,Symbol}[]  # Do we need more types?
	for v in vec
		pushorappend!(arr, toexpr(v, context))
	end
	return vec2expr(arr)
end

function toexpr(node::Node, context::AbstractContext)
	isempty(children(node)) && return toexpr(node, context + LeafContext())
	return toexprbranch(node, context)
end
function toexpr(node::Node{:dummy}, context::AbstractContext)
	if length(children(node)) == 1
		singlechild = first(children(node))
		singlechild isa Node && return toexpr(singlechild, context)
	end
	return toexprbranch(node, context)
end
toexpr(node::Node{:comment}, context::AbstractContext) = :(JSX.Node{:comment}(
	$(toexpr(children(node), context)),
))

toexprbranch(node::Node, context::CodeContext) = :(JSX.Node{Symbol($(toexpr(tag(node), DefaultContext())))}(
	$(toexpr(children(node), context)),
	$(toexpr(attrs(node, String), AttributeContext())),
))

toexpr(node::Node, ::CommonLeafCodeContext) = :(JSX.Node{Symbol($(toexpr(tag(node), DefaultContext())))}(
	attrs=$(toexpr(attrs(node, String), AttributeContext())),
))

function toexpr(node::Node, context::LeafCodeContext)
	nodeexpr = toexpr(node, context + CommonContext())
	iscommon(node) && return nodeexpr

	# Components have to be wrapped in dummy Nodes so that we always return Nodes, even after component evaluation
	if isempty(attrs(node))
		callexpr = :(JSX.Node{:dummy}([
			$(Symbol(toexpr(tag(node), DefaultContext())))()
		]))
	else
		callexpr = :(JSX.Node{:dummy}([
			$(Symbol(toexpr(tag(node), DefaultContext())))(; map(
				attr -> Symbol(first(attr)) => last(attr),
				$(toexpr(attrs(node, String), AttributeContext()))
			)...)
		]))
	end

	return trycatchexpr(callexpr, nodeexpr)
end

toexpr(str::AbstractString, ::AbstractContext) = Meta.parse("\"$(str)\"")  # Allow string interpolation
function toexpr(str::AbstractString, ::AttributeContext)
	# Probably already contains quotation marks
	return trycatchexpr(Meta.parse(str), str)
end
toexpr(str::AbstractString, context::CodeContext) = toexpr!([], str, context)
function toexpr!(exprs::AbstractVector, str::AbstractString, context::CodeContext, i::Int=firstindex(str), n::Int=lastindex(str))  # Return a vector of expressions (some are strings)
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
	return toexpr!(exprs, str, context, i, n)
end

toexpr(pair::Pair, context::AttributeContext) = :($(toexpr(first(pair), DefaultContext())) => $(toexpr(last(pair), context)))

trycatchexpr(tryexpr, undefvarexpr) = Expr(:try,
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