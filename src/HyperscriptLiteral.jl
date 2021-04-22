"""
HTML parsing on steroids!

> It's basically a tree traversal!
"""
module HyperscriptLiteral

export @htm_str

include("tags.jl")
include("utils.jl")
include("node.jl")
include("parse.jl")
include("macro.jl")
include("render.jl")

end
