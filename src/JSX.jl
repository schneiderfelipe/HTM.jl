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
function parse!(root, data, i=1, n=length(data))
	if i > n || n <= 0  # Is this necessary?
		return root, i
	end

	endtag = "</$(root.name)>"
	if startswith(data[i:n], endtag)
		return root, i + length(endtag)
	elseif data[i] == '<'
		i += 1
		j = findnext('>', data, i) - 1
		name = data[i:j]
		i = j + 2

		if name[end] == '/'
			# TODO: some standard tags have no '/' but have no children by default. Test that?
			name = rstrip(name[1:end-1])
            haschildren = false
        else
            haschildren = true
		end

		attributes = Pair{Any,String}[]  # TODO: get the right type from root and avoid Union and Any
		k = findfirst(' ', name)
		if !isnothing(k)
			name, rest = name[1:k-1], name[k+1:end]

			for pair in split(rest)
				key, value = split(pair, "=")
				push!(attributes, key => strip(value, '"'))
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
			j -=  1
		else
			j = n
		end
		text = data[i:j]
		i += length(text)

		# TODO: should we parse HTML comments?
		text = replace(text, r"\s+" => " ")
		if !isempty(text) && text != " "
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
