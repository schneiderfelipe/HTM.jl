"""
Parse a tree.
"""
function parse(data)
	root = parse!(Node(""), data)[1]
	length(root.children) == 1 && return root.children[1]
	return root
end

"""
Parse a tree by modifying the root node.
"""
function parse!(root, data, i=firstindex(data), n=lastindex(data))
	i > n && return root, i

	endtag = "</$(root.name)>"
	if startswith(data[i:n], endtag)
		return root, nextind(data, i, length(endtag))
	elseif data[i] == '<'
		i = nextind(data, i)
		j = prevind(data, findnext('>', data, i))
		name = data[i:j]
		i = nextind(data, j, 2)

		if name[end] == '/'
			# TODO: some standard tags have no '/' but have no children by default. Test that?
			name = rstrip(name[1:prevind(name, end)])
            haschildren = false
        else
            haschildren = true
		end

		# TODO: support guessing the type of attributes!
		attributes = Pair{String,String}[]
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

		child = Node(name, attributes)
		if haschildren
			child, i = parse!(child, data, i, n)
		end
		push!(root.children, child)
	else
		j = findnext('<', data, i)
		if !isnothing(j)
			j = prevind(data, j)
		else
			j = n
		end
		text = data[i:j]
		i = nextind(data, i, length(text))

		# TODO: should we parse HTML comments?
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
htmexpr(s) = esc(toexprwithcode(parse(s)))

toexpr(vec::AbstractVector) = Expr(:vect, toexpr.(vec)...)
toexpr(str::AbstractString) = Meta.parse("\"$(str)\"")  # Allow string interpolation
toexpr(pair::Pair) = Expr(:call, :(=>), toexpr(first(pair)), toexpr(last(pair)))
toexpr(x) = x  # fallback

toexprwithcode(node::Node) = Expr(:call, Node, toexpr(node.name), toexpr(node.attributes), toexprwithcode(node.children))
function toexprwithcode(vec::AbstractVector)
	arr = []  # TODO: choose correct type
	for v in vec
		ret = toexprwithcode(v)
		if ret isa AbstractVector  # TODO: this could become a function barrier
			for r in ret
				push!(arr, r)
			end
		else
			push!(arr, ret)
		end
	end
	return Expr(:vect, arr...)
end
toexprwithcode(str::AbstractString) = toexprwithcode!([], str)
function toexprwithcode!(exprs::AbstractVector, str::AbstractString, i=firstindex(str), n=lastindex(str))  # Return a vector of expressions (some are strings)
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

	# Ignore empty children
	# Plus a hack to support "\$"
	!isempty(candidate) && !isnothing(findfirst(!isspace, candidate)) && push!(exprs, replace(candidate, "\\\$" => "\$"))

	if isnothing(j)
		length(exprs) == 1 && return exprs[1]
		return exprs
	end

	expr, i = Meta.parse(str, k, greedy=false)
	!isnothing(expr) && push!(exprs, expr)
	return toexprwithcode!(exprs, str, i, n)
end
