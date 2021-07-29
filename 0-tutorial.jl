### A Pluto.jl notebook ###
# v0.14.3

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ cc32ae34-93e8-11eb-098c-7bd3d880b04b
using PlutoUI

# ╔═╡ 9c2d2f20-9267-11eb-338c-23810fe92dc3
using HTM, Plots

# ╔═╡ 452797f0-93e9-11eb-1766-edba062420f5
x = 0:10

# ╔═╡ c0163244-93e8-11eb-3ede-2524ff9a300b
# TODO: Pluto doesn't know that this cell depends on x!
htm"""
	<h1>Hello 🌍!</h1>
	<p id="plot">
		$(plot(x -> x^2, x))
	</p>
	$(md"The [above graph](#plot) shows ``y = x^2``!")

	<p>
		Infortunately, the sliders prohibit this cell to run twice:
		<ul>
			<li>z: $(@bind z Slider(-10:10, show_value=true))</li>
			<li>w: $(md"$(@bind w Slider(0:10, show_value=true))")</li>
		</ul>
	</p>
"""

# ╔═╡ f9854440-93e9-11eb-1874-ef8bd95f841a
z  # TODO: make it work with @bind!

# ╔═╡ 4535432a-93ef-11eb-00e2-23187e81ef30
w  # TODO: make it work with @bind!

# ╔═╡ d23dccc4-969e-11eb-0fc9-23e9e22defb0
htm"""
	<h1>Hello 🌍!</h1>
	$(plot(x -> x^2, 0:10))
"""

# ╔═╡ Cell order:
# ╠═cc32ae34-93e8-11eb-098c-7bd3d880b04b
# ╠═452797f0-93e9-11eb-1766-edba062420f5
# ╠═c0163244-93e8-11eb-3ede-2524ff9a300b
# ╠═f9854440-93e9-11eb-1874-ef8bd95f841a
# ╠═4535432a-93ef-11eb-00e2-23187e81ef30
# ╠═9c2d2f20-9267-11eb-338c-23810fe92dc3
# ╠═d23dccc4-969e-11eb-0fc9-23e9e22defb0
