"""
A node in the tree.
"""
struct Node{T<:Union{AbstractString,Symbol}}
    name::T
    attributes::Vector{Pair{T,String}}
    children::Vector
end
Node(name, attributes, children) = Node{typeof(name)}(name, attributes, children)
Node(name, attributes) = Node(name, attributes, [])
Node(name) = Node(name, [])

Base.:(==)(a::Node, b::Node) = a.name == b.name && a.attributes == b.attributes && a.children == b.children

iscomment(node::Node) = Symbol(node.name) == :comment
isroot(node::Node) = Symbol(node.name) == :root

Base.show(io::IO, ::MIME"text/html", node::Node) = html(io, node)  # Rich output
Base.show(io::IO, mime::MIME"text/plain", node::Node) = html(io, node, mime)

function html(io::IO, node::Node, mime=MIME("text/html"))
    if isroot(node)  # TODO: can we know the root at compilation time?
        for child in node.children
            if mime isa MIME"text/html"  # TODO: function barrier?
                html(io, child)  # Rich output
            else
                html(io, child, mime)
            end
        end
    else
        htmlnode(io, node, mime)
    end
end

# Actual nonroot node
function htmlnode(io::IO, node::Node, mime=MIME("text/html"))
    if isempty(node.children)
        # TODO: some might not like it for some tags (e.g., div)
        htmltag(io, node)
        print(io, " />")
    else
        htmltag(io, node)
        print(io, ">")

        for child in node.children
            if mime isa MIME"text/html"  # TODO: function barrier?
                html(io, child)  # Rich output
            else
                html(io, child, mime)
            end
        end

        print(io, "</$(node.name)>")
    end
end

# Helper for printing tags and attributes
function htmltag(io::IO, node::Node)
    print(io, "<$(node.name)")
    if !isempty(node.attributes)
        for pair in node.attributes
            print(io, ' ', first(pair), "=\"", last(pair), '"')
        end
    end
end