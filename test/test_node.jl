@testset "Node interface" begin
    div = JSX.Node(:div)
    comment = JSX.Node(:comment)
    component = JSX.Node(:component)
    root = JSX.Node(:dummy)
    text = JSX.Node(:text)

    # Sanity checks
    @test JSX.children(div) == []
    @test JSX.children(comment) == []
    @test JSX.children(component) == []
    @test JSX.children(text) == []
    @test JSX.children(root) == []

    @test JSX.iscomment(root) === false
    @test JSX.iscomment(comment) === true
    @test JSX.iscomment(component) === false
    @test JSX.iscomment(text) === false
    @test JSX.iscomment(div) === false

    @test JSX.iscommon(root) === false
    @test JSX.iscommon(comment) === false
    @test JSX.iscommon(component) === false
    @test JSX.iscommon(text) === false
    @test JSX.iscommon(div) === true

    @test length(JSX.commontags) == 110

    @test JSX.iscomponent(root) === false
    @test JSX.iscomponent(comment) === false
    @test JSX.iscomponent(component) === true
    @test JSX.iscomponent(text) === false
    @test JSX.iscomponent(div) === false

    @test JSX.isroot(root) === true
    @test JSX.isroot(comment) === false
    @test JSX.isroot(component) === false
    @test JSX.isroot(text) === false
    @test JSX.isroot(div) === false

    @test JSX.istext(root) === false
    @test JSX.istext(comment) === false
    @test JSX.istext(component) === false
    @test JSX.istext(text) === true
    @test JSX.istext(div) === false
end