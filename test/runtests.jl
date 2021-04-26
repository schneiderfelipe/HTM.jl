using HyperscriptLiteral
using HyperscriptLiteral: parsevalue, parseprops, parsetag
using HyperscriptLiteral: create_element
using Hyperscript: render
using Test

simplerender(x) = replace(render(x), r"\s+" => ' ')

@testset "HyperscriptLiteral.jl" begin
    @testset "create_element" begin
        @test create_element("div") |> render == "<div></div>"
        @test create_element("div", "Hi!") |> render == "<div>Hi&#33;</div>"
        @test create_element("div", Dict("class" => "active")) |> render == "<div class=\"active\"></div>"
        @test create_element("div", Dict("class" => "active"), "Hi!") |> render == "<div class=\"active\">Hi&#33;</div>"
        @test create_element("div", Dict("class" => "active"), "Hi ", "there!") |> render == "<div class=\"active\">Hi there&#33;</div>"
    end

    @testset "HTML spec." begin
        @test parsetag(IOBuffer("<a/>")) == create_element("a")
        @test parsetag(IOBuffer("<a>b</a>")) == create_element("a", "b")
        @test parsetag(IOBuffer("<a b=c d/>")) == create_element("a", Dict("b" => "c", "d" => nothing))
        @test parsetag(IOBuffer("<a b=c d>e</a>")) == create_element("a", Dict("b" => "c", "d" => nothing), "e")

        @test parsetag(IOBuffer("<a></a>")) == parsetag(IOBuffer("<a/>"))
        @test parsetag(IOBuffer("<a />")) == parsetag(IOBuffer("<a/>"))
        @test parsetag(IOBuffer("<a b=c d />")) == parsetag(IOBuffer("<a b=c d/>"))

        # TODO: make this work, but suggest changes in Hyperscript.jl.
        @test htm"<span style=$(Dict(\"background\" => \"yellow\"))>It's all yellow!</span>" |> render == create_element("span", Dict("style" => Dict("background" => "yellow")), "It's all yellow!") |> render
    end

    @testset "htl" begin
        let fragment = htm"I'm a <em>document fragment</em>."
            @test fragment == ["I'm a ", htm"<em>document fragment</em>", "."]

            interp = htm"<span>$fragment</span>"
            @test interp |> render == "<span>I&#39;m a <em>document fragment</em>.</span>"
            @test htm"<span>$(fragment)</span>" == interp
        end

        @test_skip htm"<script>$(\"</script>\")</script>"  # BUG: should throw

        # TODO: this might be useful in the future, especially with JSExpr.jl.
        @test_skip htm"<button onclick=$(_ -> clicks += 1)>click me</button>" == "<button onclick=$(_ -> clicks += 1)>click me</button>"

        @test htm"<button disabled=$(true)>Can't click me</button>" |> render == "<button disabled>Can&#39;t click me</button>"

        enabledbutton = htm"<button disabled=$(false)>Can click me</button>"
        @test enabledbutton |> render == "<button>Can click me</button>"
        @test htm"<button disabled=$(nothing)>Can click me</button>" == enabledbutton

        @test htm"There's no $(nothing) here." == ["There's no ", nothing, " here."]

        let props = Dict("style" => Dict("background" => "yellow", "font-weight" => "bold"))
            @test_broken htm"<span $(props)>whoa</span>" == htm"<span style=$(props[\"style\"])>whoa</span>"
            @test_broken htm"<span style=$(props[\"style\"])>whoa</span>" == htm"<span style=\"background: yellow; font-weight: bold;\">whoa</span>"
        end

        let emphasize(text) = htm"<em>$(text)</em>"
            fragment = htm"This is $(emphasize(\"really\")) important."
            @test fragment == ["This is ", htm"<em>really</em>", " important."]
            @test htm"<span>$fragment</span>" |> render == "<span>This is <em>really</em> important.</span>"
        end

        let fragment = htm"It's as easy as $([1, 2, 3])."
            @test fragment == ["It's as easy as ", [1, 2, 3], "."]
            @test htm"<span>$fragment</span>" |> render == "<span>It&#39;s as easy as 123.</span>"
        end

        let colorscheme = ["#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf"]
            rows = map(((i, color),) -> htm"<tr>
                <td>$(i)</td>
                <td>$(color)</td>
                <td style=\"background: $(color);\"></td>
            </tr>", enumerate(colorscheme))
            rendered = htm"""<table style="width: 180px;">
                <thead><tr><th>#</th><th>Color</th><th>Swatch</th></tr></thead>
                <tbody>$(rows)</tbody>
            </table>""" |> simplerender

            @test occursin("<thead><tr><th>#</th><th>Color</th><th>Swatch</th></tr></thead>", rendered)
            @test occursin("<tr> <td>9</td> <td>#bcbd22</td> <td style=\"background: #bcbd22;\"></td> </tr>", rendered)
            @test_skip htm"""<table style="width: 180px;">
                <thead><tr><th>#</th><th>Color</th><th>Swatch</th></tr></thead>
                <tbody>$(map(((i, color),) -> htm"<tr>
                    <td>$(i)</td>
                    <td>$(color)</td>
                    <td style=\"background: $(color);\"></td>
                </tr>", enumerate(colorscheme)))</tbody>
            </table>""" |> simplerender == rendered
        end

        # TODO: what changes with SVG?
        @test htm"<svg width=60 height=60>
            $(htm\"<circle cx=30 cy=30 r=30></circle>\")
        </svg>" |> simplerender == "<svg height=\"60\" width=\"60\"> <circle cy=\"30\" r=\"30\" cx=\"30\" /> </svg>"

        let tagtype = "button"
            @test htm"<$(tagtype)>Does this work?</$(tagtype)>" |> render == "<button>Does this work?</button>"
        end
    end
end
