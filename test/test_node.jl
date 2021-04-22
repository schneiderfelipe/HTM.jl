@testset "Node interface" begin
    comment = HyperscriptLiteral.Node(:comment)
    div = HyperscriptLiteral.Node{:div}([comment], [:class => "container"])
    dummy = HyperscriptLiteral.Node{:dummy}([comment, div])

    @test HyperscriptLiteral.tag(comment) == "comment"
    @test HyperscriptLiteral.tag(div) == "div"
    @test HyperscriptLiteral.tag(dummy) == "dummy"

    @test HyperscriptLiteral.children(comment) == []
    @test HyperscriptLiteral.children(div) == [comment]
    @test HyperscriptLiteral.children(dummy) == [comment, div]

    @test HyperscriptLiteral.attrs(comment) == []
    @test HyperscriptLiteral.attrs(div) == [:class => "container"]
    @test HyperscriptLiteral.attrs(div, String) == ["class" => "container"]
    @test HyperscriptLiteral.attrs(dummy) == []

    @test HyperscriptLiteral.iscommon(comment) === false
    @test HyperscriptLiteral.iscommon(div) === true
    @test HyperscriptLiteral.iscommon(dummy) === false

    @test length(HyperscriptLiteral.commontags) == 110
end