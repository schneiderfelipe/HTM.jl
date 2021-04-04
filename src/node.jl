"""
A node in the tree.
"""
struct Node{S<:Union{AbstractString,Symbol},T<:AbstractVector,U<:AbstractVector}
    name::S
    attributes::T
    children::U
end
Node(name, attributes, children) = Node{typeof(name),typeof(children)}(name, attributes, children)
Node(name, attributes) = Node(name, attributes, [])
Node(name::AbstractString) = Node(name, Pair{String,String}[])
Node(name::Symbol) = Node(name, Pair{Symbol,String}[])

children(node::Node) = node.children

 # TODO: can we know this at compilation time?
iscomment(node::Node) = Symbol(node.name) == :comment
iscommon(node::Node) = Symbol(node.name) in commontags
iscomponent(node::Node) = Symbol(node.name) == :component
isroot(node::Node) = Symbol(node.name) == :dummy
istext(node::Node) = Symbol(node.name) == :text

hassinglenode(node::Node) = length(children(node)) == 1 && first(children(node)) isa Node

Base.:(==)(a::Node, b::Node) = a.name == b.name && a.attributes == b.attributes && children(a) == children(b)
Base.isempty(node::Node) = isempty(children(node))

Base.show(io::IO, ::MIME"text/html", node::Node) = html(io, node)  # Rich output
Base.show(io::IO, mime::MIME"text/plain", node::Node) = html(io, node, mime)

# TODO: escape stuff
function html(io::IO, node::Node, mime=MIME("text/html"))
    if isroot(node) || iscomponent(node)  # TODO: can we know this at compilation time?
        for child in children(node)
            htmltext(io, child, mime)
        end
    else
        htmlnode(io, node, mime)
    end
end

htmltext(io::IO, value, ::MIME"text/html") = html(io, value)  # Rich output
htmltext(io::IO, value, mime) = html(io, value, mime)

# Actual nonroot node
function htmlnode(io::IO, node::Node, mime=MIME("text/html"))
    if isempty(children(node))
        htmltag(io, node)
        print(io, " />")
    else
        if iscomment(node)  # TODO: can we know this at compilation time?
            print(io, "<!--")
        elseif !istext(node)
            htmltag(io, node)
            print(io, ">")
        end

        for child in children(node)
            htmltext(io, child, mime)
        end

        if iscomment(node)  # TODO: can we know this at compilation time?
            print(io, "-->")
        elseif !istext(node)
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