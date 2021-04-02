@testset "Node interface" begin
    root = Node(:root)
    comment = Node(:comment)
    div = Node(:div)

    # Sanity checks
    @test iscomment(root) === false
    @test iscomment(comment) === true
    @test iscomment(div) === false
    @test isroot(root) === true
    @test isroot(comment) === false
    @test isroot(div) === false
end