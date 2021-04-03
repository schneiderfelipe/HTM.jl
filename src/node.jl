"""
A node in the tree.
"""
struct Node{T<:Union{AbstractString,Symbol}}
    name::T
    attributes::Vector{Pair{T,String}}
    children::Vector  # TODO: transform children into data and parameterize by it. Can we wrap all types and be stable?
end
Node(name, attributes, children) = Node{typeof(name)}(name, attributes, children)
Node(name, attributes) = Node(name, attributes, [])
Node(name) = Node(name, [])

children(node::Node) = node.children

iscomment(node::Node) = Symbol(node.name) == :comment
isroot(node::Node) = Symbol(node.name) == :dummy
iscomponent(node::Node) = Symbol(node.name) == :component
iscommon(node::Node) = Symbol(node.name) in commontags

hassinglenode(node::Node) = length(children(node)) == 1 && first(children(node)) isa Node

Base.:(==)(a::Node, b::Node) = a.name == b.name && a.attributes == b.attributes && children(a) == children(b)
Base.isempty(node::Node) = isempty(children(node))

Base.show(io::IO, ::MIME"text/html", node::Node) = html(io, node)  # Rich output
Base.show(io::IO, mime::MIME"text/plain", node::Node) = html(io, node, mime)

# TODO: escape stuff
function html(io::IO, node::Node, mime=MIME("text/html"))
    if isroot(node) || iscomponent(node)  # TODO: can we know the root at compilation time?
        for child in children(node)
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
    if isempty(children(node))
        # TODO: some might not like it for some tags (e.g., div)
        htmltag(io, node)
        print(io, " />")
    else
        if iscomment(node) # TODO: can we know a comment at compilation time?
            print(io, "<!--")
        else
            htmltag(io, node)
            print(io, ">")
        end

        for child in children(node)
            if mime isa MIME"text/html"  # TODO: function barrier?
                html(io, child)  # Rich output
            else
                html(io, child, mime)
            end
        end

        if iscomment(node) # TODO: can we know a comment at compilation time?
            print(io, "-->")
        else
            print(io, "</$(node.name)>")
        end
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