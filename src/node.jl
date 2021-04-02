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

# TODO: extend this to plain text and other plain representations
function Base.show(io, mime::MIME"text/html", node::Node)
    if isempty(node.children)
        # TODO: some might not like it for some tags
        if isempty(node.attributes)
            !isempty(node.name) && write(io, "<$(node.name) />")
        else
            write(io, "<$(node.name)")
            writeattributes(io, node)
            write(io, " />")
        end
    else
        if isempty(node.attributes)
            !isempty(node.name) && write(io, "<$(node.name)>")
        else
            write(io, "<$(node.name)")
            writeattributes(io, node)
            write(io, ">")
        end
        for child in node.children
            if child isa AbstractString
                # There are no show(io, ::MIME"text/html", ::String)
                # TODO: what about Float64, etc.?
                write(io, child)
            else
                show(io, mime, child)
            end
        end
        !isempty(node.name) && write(io, "</$(node.name)>")
    end
end

function writeattributes(io, node)
    for pair in node.attributes
        write(io, ' ', first(pair), "=\"", last(pair), '"')
    end
end