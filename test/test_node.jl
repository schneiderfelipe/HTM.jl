@testset "Node interface" begin
    comment = JSX.Node(:comment)
    div = JSX.Node{:div}([comment], ["class" => "container"])  # TODO: use symbols
    dummy = JSX.Node{:dummy}([comment, div])

    @test JSX.tag(comment) == "comment"
    @test JSX.tag(div) == "div"
    @test JSX.tag(dummy) == "dummy"

    @test JSX.children(comment) == []
    @test JSX.children(div) == [comment]
    @test JSX.children(dummy) == [comment, div]

    @test JSX.attrs(comment) == []
    @test JSX.attrs(div) == ["class" => "container"]
    @test JSX.attrs(dummy) == []

    @test JSX.iscommon(comment) === false
    @test JSX.iscommon(div) === true
    @test JSX.iscommon(dummy) === false

    @test length(JSX.commontags) == 110
end