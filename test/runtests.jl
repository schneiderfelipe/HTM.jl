using HyperscriptLiteral
using HyperscriptLiteral: parsevalue, parseprops, parsetag
using HyperscriptLiteral: create_element
using Hyperscript: render
using Test

@testset "HyperscriptLiteral.jl" begin
    @testset "create_element" begin
        @test create_element("div") |> render == "<div></div>"
        @test create_element("div", "Hi!") |> render == "<div>Hi&#33;</div>"
        @test create_element("div", Dict("class" => "active")) |> render == "<div class=\"active\"></div>"
        @test create_element("div", Dict("class" => "active"), "Hi!") |> render == "<div class=\"active\">Hi&#33;</div>"
        @test create_element("div", Dict("class" => "active"), "Hi ", "there!") |> render == "<div class=\"active\">Hi there&#33;</div>"
    end

    @testset "HTML spec." begin
        @test parsetag(IOBuffer("<a></a>")) == create_element("a")
        @test parsetag(IOBuffer("<a />")) == create_element("a")
        @test parsetag(IOBuffer("<a/>")) == create_element("a")
        @test parsetag(IOBuffer("<a>b</a>")) |> render == create_element("a", "b") |> render
        @test parsetag(IOBuffer("<a b=c d />")) == create_element("a", Dict("b" => "c", "d" => true))
        @test parsetag(IOBuffer("<a b=c d/>")) == create_element("a", Dict("b" => "c", "d" => true))
        @test parsetag(IOBuffer("<a b=c d>e</a>")) |> render == create_element("a", Dict("b" => "c", "d" => true), "e") |> render
    end

    @testset "htl" begin
        # From https://observablehq.com/@observablehq/htl
        @test htm"<i>I'm an element!</i>" |> render == "<i>I&#39;m an element&#33;</i>"
        @test htm"I'm simply text." == "I'm simply text."
        @test isnothing(htm"")

        # TODO: This differs from HTL. Document this.
        @test htm"I'm a <i>document fragment</i>." == ["I'm a ", htm"<i>document fragment</i>", "."]
        # @test htm"""<span>$(htm"I'm a <i>document fragment</i>.</span>")""" |> render == "<span>I&#39;m a <i>document fragment</i>.</span>"

        @test htm"""Look, Ma, $("<i>automatic escaping</i>")!""" |> render == "Look, Ma, &gt;i&lt;automatic escaping&gt;&#92;i&lt;#33;"
        # @test htm"""<font color=$("red")>This text has color.</font>""" |> render == "<font color=\"red\">This text has color.</font>"
        # @test_throws htm"""<script>$("</script>")</script>"""
    end
end