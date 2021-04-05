using JSX
using Test

using Markdown

@testset "JSX.jl" begin
    # Who doesn't love hand-made, artisanal tests?

    include("test_node.jl")
    include("test_literal.jl")
    include("test_noquote.jl")
    include("test_unicode.jl")
    include("test_strinterp.jl")
    include("test_objinterp.jl")
    include("test_attributes.jl")
    include("test_components.jl")
    include("test_showplain.jl")
    include("test_showhtml.jl")
end
