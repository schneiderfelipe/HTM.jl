"""
    Node{T}

A node in the tree.
"""
struct Node{T}
    children::Vector{Any}
    attrs::Vector{Pair{Symbol,Any}}
    Node{T}(children, attrs=[]) where {T} = new{Symbol(T)}(children, processattrs(attrs, Symbol))
end
Node{T}(; children=[], attrs=[]) where {T} = Node{Symbol(T)}(children, attrs)
Node(T; children=[], attrs=[]) = Node{Symbol(T)}(children, attrs)
Node(T, children, attrs=[]) = Node{Symbol(T)}(children, attrs)

tag(::Node{T}) where {T} = String(T)  # Should be string to work inside macros
children(node::Node) = node.children
attrs(node::Node) = node.attrs
attrs(node::Node, f) = processattrs(attrs(node), f)

Base.:(==)(::Node{T}, ::Node{U}) where {T,U} = false
Base.:(==)(a::Node{T}, b::Node{T}) where {T} = attrs(a) == attrs(b) && children(a) == children(b)

iscommon(::Node{T}) where {T} = T in commontags

"""
Construct an expression that evaluates to the given node.
"""
function toexpr(node::Node, ::NodeContext)
    isempty(children(node)) && return toexpr(node, LeafNodeContext())
    return toexpr(node, BranchNodeContext())
end
function toexpr(node::Node{:dummy}, ::NodeContext)
    if length(children(node)) == 1
        singlechild = first(children(node))
        singlechild isa Node && return toexpr(singlechild, NodeContext())
    end
    return toexpr(node, BranchNodeContext())
end
function toexpr(node::Node{:comment}, ::NodeContext)
    return :(
        HyperscriptLiteral.Node{:comment}(
            $(toexpr(children(node), NodeContext())),
        )
    )
end

"""
Create a generic expression for a branch node.
"""
function toexpr(node::Node, ::BranchNodeContext)
    return :(
        HyperscriptLiteral.Node{
                Symbol($(toexpr(tag(node), TagContext())))
            }(
            $(toexpr(children(node), NodeContext())),
            $(toexpr(attrs(node, String), AttributeContext())),
        )
    )
end

"""
Create a generic expression for a leaf node.
"""
function toexpr(node::Node, ::LeafCommonNodeContext)
    return :(
        HyperscriptLiteral.Node{
                Symbol($(toexpr(tag(node), TagContext())))
            }(
            attrs=$(toexpr(attrs(node, String), AttributeContext())),
        )
    )
end
function toexpr(node::Node, ::LeafNodeContext)
    nodeexpr = toexpr(node, LeafCommonNodeContext())
    iscommon(node) && return nodeexpr

    callexpr = toexpr(node, ComponentNodeContext())
    return trycatchexpr(callexpr, nodeexpr)
end

"""
Create a generic expression for a component node.
"""
function toexpr(node::Node, ::ComponentNodeContext)
    # Components have to be wrapped in dummy Nodes so that we always return Nodes, even after component evaluation
    if isempty(attrs(node))
        return :(HyperscriptLiteral.Node{:dummy}(
                [$(Symbol(toexpr(tag(node), TagContext())))()]
            )
        )
    end
    return :(HyperscriptLiteral.Node{:dummy}(
            [$(Symbol(toexpr(tag(node), TagContext())))(; map(
                attr -> Symbol(first(attr)) => last(attr),
                $(toexpr(attrs(node, String), AttributeContext()))
            )...)]
        )
    )
end