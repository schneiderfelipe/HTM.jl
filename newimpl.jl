### A Pluto.jl notebook ###
# v0.14.2

using Markdown
using InteractiveUtils

# ╔═╡ 26a791a6-c9d4-4db7-ba21-f3396539d982
using Hyperscript

# ╔═╡ a6d804da-89f1-4d50-bdec-a55cb849ae32
using PlutoUI

# ╔═╡ 5118591a-a3a6-11eb-32c3-15ee7ba2d96c
md"""
# HyperscriptLiteral.jl

This package parses HTML into [Hyperscript.jl](https://github.com/yurivish/Hyperscript.jl) objects.

TODO: Everything Hyperscript.jl supports is supported.

See [HypertextLiteral.jl](https://github.com/MechanicalRabbit/HypertextLiteral.jl) for a related package.
"""

# ╔═╡ 7b6a10d3-d2f2-4f27-9b25-a4afab175139
md"""
The heavy lifting is done by the `parse()` function.

TODO: a macro will be defined elsewhere ([not yet supported by Pluto.jl](https://github.com/fonsp/Pluto.jl/issues/196#issuecomment-814778783)).
"""

# ╔═╡ c9cb4604-4f0a-4eef-a0c8-3ef83d1dffab
with_terminal() do
	dump(m("div", class="title", "Hello world"))
end

# ╔═╡ 01325bbd-e783-47df-a52e-9e817dc45fa9
typeof(m("div"))

# ╔═╡ 0162c611-2795-4fc9-84ba-e740b9f59642
md"""
## Implementation

Below is the code that implements `parse()`.
"""

# ╔═╡ 26269613-d19c-4fcc-8d6e-eaacc68b74d6
"""
	parse(s::AbstractString)

Parse a string.
"""
parse(s::AbstractString) = parse(IOBuffer(s))

# ╔═╡ 5ae0b73c-7c81-4c10-b55c-a032ed6a9c2d
with_terminal() do
	let name = "Felipe"
		@show parse(raw"Hello world")
		@show parse(raw"  <h1><strong>Hello</strong> $(name)</h1>")
	end
end

# ╔═╡ 25af2476-bb5b-4631-98b0-f6bf31829d1c
"""
	parseelem(io::IO)

Parse a single HTML element, either a `Hyperscript.Node{Hyperscript.HTMLSVG}` or `String`.
"""
function parseelem(io::IO)
	skipchars(isspace, io)
	if peek(io, Char) == '<'
		return parsetag(io)
	end
	return read(io, String)
end

# ╔═╡ a72a6450-6e43-40fa-99a7-8063adbb6c8d
"""
	parse(io::IO)

Parse an `IO` object.

The returned object is a `Vector`.
"""
function parse(io::IO)
	nodes = []  # TODO: types?
	while !eof(io)
		push!(nodes, parseelem(io))
	end
	if length(nodes) == 1
		return nodes[1]
	end
	return nodes
end

# ╔═╡ a85fd945-057b-4cc2-8111-35b0c3921dbb
"""
	parsetag(io::IO)

Parse a single tag as a `Hyperscript.Node{Hyperscript.HTMLSVG}`.
"""
function parsetag(io::IO)
	@assert read(io, Char) == '<'
	# skip(io, 1)
	
	tag = readuntil(io, '>')
	content = readuntil(io, "</$(tag)>")
	
	m(tag, parse(content))
end

# ╔═╡ Cell order:
# ╟─5118591a-a3a6-11eb-32c3-15ee7ba2d96c
# ╠═26a791a6-c9d4-4db7-ba21-f3396539d982
# ╟─7b6a10d3-d2f2-4f27-9b25-a4afab175139
# ╠═a6d804da-89f1-4d50-bdec-a55cb849ae32
# ╠═5ae0b73c-7c81-4c10-b55c-a032ed6a9c2d
# ╠═c9cb4604-4f0a-4eef-a0c8-3ef83d1dffab
# ╠═01325bbd-e783-47df-a52e-9e817dc45fa9
# ╟─0162c611-2795-4fc9-84ba-e740b9f59642
# ╠═26269613-d19c-4fcc-8d6e-eaacc68b74d6
# ╠═a72a6450-6e43-40fa-99a7-8063adbb6c8d
# ╠═25af2476-bb5b-4631-98b0-f6bf31829d1c
# ╠═a85fd945-057b-4cc2-8111-35b0c3921dbb
