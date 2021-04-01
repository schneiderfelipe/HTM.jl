"""
HTML parsing on steroids!

> It's basically a tree traversal!
"""
module JSX

export @htm_str

"""
A node in the tree.
"""
struct Node
    name::String
    attributes::Vector{Pair{String,String}}
    children::Vector{Union{Node,String}}  # too restrictive in the long run
end
Node(name, attributes) = Node(name, attributes, [])
Node(name) = Node(name, [])

Base.:(==)(a::Node, b::Node) = a.name == b.name && a.attributes == b.attributes && a.children == b.children

"""
Parse a tree by modifying the root node.
"""
function parse!(root, data, i=firstindex(data), n=lastindex(data))
	if i > n
		return root, i
	end

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

		# TODO: avoid Any in all cases possible!
		attributes = Pair{Any,String}[]  # TODO: get the right type from root and avoid Union and Any
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
						r = s = nextind(rest, s)
						push!(attributes, key => value)
					end
					# TODO: support lack of '"'
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
		if !isempty(text) && findfirst(!isspace, text) !== nothing
			# Neither empty nor only whitespace
			push!(root.children, text)
		end
	end

	return parse!(root, data, i, n)
end

"""
Parse a tree.
"""
function parse(data)
	root = parse!(Node(""), data)[1]  # the root node has an empty name
	if length(root.children) == 1
		return root.children[1]
	end
	return root
end

"""
Time to create a macro!

We want to do the following.

# Examples
```jldoctest
julia> htm"<h1>Hello world!</h1>"
```
"""
# The real trick (that I learned by reading the code of Markdown) is to ignore
# string interpolations completely, but consider them part of the input and
# conserve them until the very end. Then, the macro returns not a finished
# tree, but an expression that constructs one. The tree should allow arbitrary
# objects in this case.
macro htm_str(s)
    htmexpr(s)
end

function htmexpr(s)
    htm = parse(s)
    esc(toexpr(htm))
end

# https://stackoverflow.com/a/39499403/4039050
# Should we use escape_string(str) instead of str?
toexpr(str::AbstractString) = Meta.parse("\"$(str)\"")  # Good, but let's be more clever!
toexpr(children::AbstractVector) = Expr(:vect, toexpr.(children)...)

toexpr(pair::Pair) = Expr(:call, :(=>), toexpr(first(pair)), toexpr(last(pair)))
toexpr(node::Node) = Expr(:call, Node, toexpr(node.name), toexpr(node.attributes), toexpr(node.children))

toexpr(x) = x  # fallback

end
