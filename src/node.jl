"""
    Node{T}

A node in the tree.
"""
struct Node{T}
    children::Vector{Any}
    attrs::Vector{Pair{String,Any}}
    Node{T}(children, attrs=[]) where {T} = new{Symbol(T)}(children, attrs)
end
Node{T}(; children=[], attrs=[]) where {T} = Node{Symbol(T)}(children, attrs)
Node(T; children=[], attrs=[]) = Node{Symbol(T)}(children, attrs)
Node(T, children, attrs=[]) = Node{Symbol(T)}(children, attrs)

tag(::Node{T}) where {T} = String(T)  # Should be string to work inside macros
children(node::Node) = node.children
attrs(node::Node) = node.attrs

Base.:(==)(::Node{T}, ::Node{U}) where {T,U} = false
Base.:(==)(a::Node{T}, b::Node{T}) where {T} = attrs(a) == attrs(b) && children(a) == children(b)

iscommon(::Node{T}) where {T} = T in commontags