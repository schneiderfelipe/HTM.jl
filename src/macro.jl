# TODO: clean this up.

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
htmexpr(s::AbstractString) = esc(toexprwithcode(parse(s)))

toexpr(vec::AbstractVector) = :([$(toexpr.(vec)...)])
toexpr(str::AbstractString) = Meta.parse("\"$(str)\"")  # Allow string interpolation
toexpr(pair::Pair) = :($(toexpr(first(pair))) => $(toexpr(last(pair))))
toexpr(x) = x  # Keep objects in general

function toexprwithcode(vec::AbstractVector)
	# We may require more types in the future.
	arr = Union{Expr,String,Symbol}[]
	for v in vec
		pushorappend!(arr, toexprwithcode(v))
	end
	return :([$(arr...)])
end

toexprwithcode(str::AbstractString) = toexprwithcode!([], str)
function toexprwithcode!(exprs::AbstractVector, str::AbstractString, i::Int=firstindex(str), n::Int=lastindex(str))  # Return a vector of expressions (some are strings)
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
			# We ignore code that fails to parse, similar to how @md_str behaves.
			"\$", k
		else
			rethrow()
		end
	end

	pushexprorstr!(exprs, expr)
	return toexprwithcode!(exprs, str, i, n)
end

function toexprwithcode(node::Node)
	isempty(children(node)) && return toexprleaf(node)
	return toexprbranch(node)
end
toexprwithcode(node::Union{Node{:comment},Node{:component}}) = :(JSX.Node{:comment}($(toexprwithcode(children(node)))))
function toexprwithcode(node::Node{:dummy})
	if length(children(node)) == 1
		singlechild = first(children(node))
		singlechild isa Node && return toexprwithcode(singlechild)
	end
	return toexprbranch(node)
end

function toexprbranch(node::Node)
	return :(JSX.Node{Symbol($(toexpr(tag(node))))}(
		$(toexprwithcode(children(node))),
		$(toexpr(attrs(node))),
	))
end

function toexprleaf(node::Node)
	nodeexpr = toexprbranch(node)
	iscommon(node) && return nodeexpr

	if isempty(attrs(node))
		callexpr = :(JSX.Node{:component}([$(Symbol(toexpr(tag(node))))()]))
	else
		callexpr = :(JSX.Node{:component}([$(Symbol(toexpr(tag(node))))(; [Symbol(first(pair)) => last(pair) for pair in $(toexpr(attrs(node)))]...)]))
	end

	fallbackexpr = Expr(:if,
		:(err isa UndefVarError),
		Expr(:block,  # then
			nodeexpr,
		),
		Expr(:block,  # else
			:(rethrow()),
		),
	)

	return Expr(:try,
		Expr(:block, callexpr),
		:err,
		Expr(:block, fallbackexpr),  # catch
	)
end