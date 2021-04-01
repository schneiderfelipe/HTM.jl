using JSX
using Test

using JSX: Node

@testset "JSX.jl" begin
    # Who doesn't love hand-made, artisanal tests?

    include("test_literal.jl")
    include("test_noquote.jl")
    include("test_unicode.jl")
    include("test_interpolation.jl")
end
