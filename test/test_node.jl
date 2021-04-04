@testset "Node interface" begin
    div = JSX.Node(:div)
    comment = JSX.Node(:comment)
    component = JSX.Node(:component)
    dummy = JSX.Node(:dummy)  # TODO: only use dummy tags if possible
    text = JSX.Node(:text)

    # Sanity checks
    @test JSX.children(div) == []
    @test JSX.children(comment) == []
    @test JSX.children(component) == []
    @test JSX.children(text) == []
    @test JSX.children(dummy) == []

    @test JSX.iscommon(dummy) === false
    @test JSX.iscommon(comment) === false
    @test JSX.iscommon(component) === false
    @test JSX.iscommon(text) === false
    @test JSX.iscommon(div) === true

    @test length(JSX.commontags) == 110
end