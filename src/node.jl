"""
A node in the tree.
"""
struct Node
    name::String
    attributes::Vector{Pair{String,String}}
    children::Vector
end
Node(name, attributes) = Node(name, attributes, [])
Node(name) = Node(name, [])

Base.:(==)(a::Node, b::Node) = a.name == b.name && a.attributes == b.attributes && a.children == b.children