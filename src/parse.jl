"""
Parse a tree.
"""
function parse(data::AbstractString, rootname::AbstractString="root")::Node
	# name must be a string to properly generate the tree later with symbols
	root = parse!(Node(rootname), data)[1]

	# Always return a Node
	length(root.children) == 1 && root.children[1] isa Node && return root.children[1]
	return root
end

"""
Parse a tree by modifying the root node.
"""
function parse!(root::Node, data::AbstractString, i::Int=firstindex(data), n::Int=lastindex(data))
	i > n && return root, i

	if iscomment(root)
		endtag = "-->"
	else
		endtag = "</$(root.name)>"
	end
	if startswith(data[i:n], endtag)
		return root, nextind(data, i, length(endtag))
	elseif data[i] == '<'
		i = nextind(data, i)

		# TODO: support guessing the type of attributes!
		attributes = Pair{String,String}[]

		haschildren = true
		if startswith(data[i:n], "!--")
			# A wild comment has appeared!
			# name must be a string to properly generate the tree later with symbols
			name = "comment"
			i = nextind(data, i, 3)
		else
			j = prevind(data, findnext('>', data, i))
			name = data[i:j]
			i = nextind(data, j, 2)

			if name[end] == '/'
				# TODO: some standard tags have no '/' but have no children by default. Test that?
				name = rstrip(name[1:prevind(name, end)])
				haschildren = false
			end

			k = findfirst(isspace, name)
			if !isnothing(k)
				# prevind/nextind are needed to support Unicode
				name, rest = name[1:prevind(name, k)], name[nextind(name, k):end]

				r, s, m = 1, 1, lastindex(rest)
				while s < m
					@assert r <= s
					if rest[s] == '='
						key = rest[r:prevind(rest, s)]
						r = s = nextind(rest, s)
						if rest[r] == '"'
							r = nextind(rest, r)
							s = findnext('"', rest, r)

							value = rest[r:prevind(rest, s)]
							push!(attributes, key => value)
							r = s = nextind(rest, s)
						else
							# No quotation mark
							s = findnext(isspace, rest, r)
							if isnothing(s)
								# Last attribute
								value = rest[r:m]
								push!(attributes, key => value)
								break
							end

							value = rest[r:prevind(rest, s)]
							push!(attributes, key => value)
							r = s = nextind(rest, s)
						end
					elseif isspace(rest[r])
						if r < m
							r = s = nextind(rest, r)
						else
							break
						end
					end
					if s < m
						s = nextind(rest, s)
					else
						break
					end
				end
			end
		end

		child = Node(name, attributes)
		if haschildren
			child, i = parse!(child, data, i, n)
		end
		push!(root.children, child)
	else
		if iscomment(root)
			j = findnext("-->", data, i)
			if !isnothing(j)
				j = prevind(data, first(j))
			else
				j = n
			end
		else
			j = findnext('<', data, i)
			if !isnothing(j)
				j = prevind(data, j)
			else
				j = n
			end
		end

		text = data[i:j]
		i = nextind(data, i, length(text))

		text = replace(text, r"\s+" => ' ')

		# Ignore empty children
		!isempty(text) && !isnothing(findfirst(!isspace, text)) && push!(root.children, text)
	end

	return parse!(root, data, i, n)
end

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

toexpr(vec::AbstractVector) = Expr(:vect, toexpr.(vec)...)
toexpr(str::AbstractString) = Meta.parse("\"$(str)\"")  # Allow string interpolation
toexpr(pair::Pair) = Expr(:call, :(=>), Expr(:call, Symbol, toexpr(first(pair))), toexpr(last(pair)))
toexpr(x) = x  # Keep objects in general

# Append if vector, push otherwise
push_or_append!(arr::AbstractVector, ret::AbstractVector) = append!(arr, ret)
push_or_append!(arr::AbstractVector, ret) = push!(arr, ret)

# TODO: make this more clever! htm"<country name=\"Brazil\", continent=\"South America\">" should call this function!
# See how to call the correct function here: <https://discourse.julialang.org/t/convert-string-to-function-name/1547/6?u=schneiderfelipe>
# Also relevant: <https://stackoverflow.com/questions/34016768/julia-invoke-a-function-by-a-given-string/34023458#34023458>
# We want to support what JSX does, see here: <https://reactjs.org/docs/hello-world.html> (all "main concepts"!)
toexprwithcode(node::Node) = Expr(:call, Node, Expr(:call, Symbol, toexpr(node.name)), toexpr(node.attributes), toexprwithcode(node.children))
function toexprwithcode(vec::AbstractVector)
	arr = []  # TODO: choose correct type
	for v in vec
		ret = toexprwithcode(v)
		push_or_append!(arr, ret)
	end
	return Expr(:vect, arr...)
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
		length(exprs) == 1 && return exprs[1]
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

# Ensure strings are as long as possible
function pushexprorstr!(exprs::AbstractVector, str::AbstractString)
	# Ignore empty children
	if !isempty(str) && !isnothing(findfirst(!isspace, str))
		if !isempty(exprs) && last(exprs) isa AbstractString
			# Make strings contiguous
			exprs[end] *= str
		else
			# Hack to support "\$"
			push!(exprs, replace(str, "\\\$" => "\$"))
		end
	end
end
pushexprorstr!(exprs::AbstractVector, expr) = !isnothing(expr) && push!(exprs, expr)