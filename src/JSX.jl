"""
HTML parsing on steroids!

> It's basically a tree traversal!
"""
module JSX

export @htm_str

include("tags.jl")
include("node.jl")
include("parse.jl")
include("utils.jl")
include("macro.jl")
include("render.jl")

end
