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