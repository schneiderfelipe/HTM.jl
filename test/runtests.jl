using HyperscriptLiteral
using HyperscriptLiteral: parsetag, Tag
using Hyperscript: render
using Test

simplerender(x) = replace(render(x), r"\s+" => ' ')

@testset "HyperscriptLiteral.jl" begin
    @testset "Features" begin
        # TODO: Ensure we get 100% coverage, but make simpler tests. Examples should be in the documentation.

        let fragment = htm"I'm a <em>document fragment</em>."
            @test fragment == ("I'm a ", htm"<em>document fragment</em>", ".")

            interp = htm"<span>$fragment</span>"
            @test interp |> render == "<span>I&#39;m a <em>document fragment</em>.</span>"
            @test htm"<span>$(fragment)</span>" == interp

            @test htm"<span>$fragment$fragment</span>" == htm"<span>$(fragment)$(fragment)</span>"
        end

        @test htm"<span>$(:symbol)</span>" |> render == "<span>symbol</span>"

        @test_skip htm"<script>$(\"</script>\")</script>"  # BUG: should throw

        # TODO: this might be useful in the future, especially with JSExpr.jl.
        @test_broken htm"<button onclick=$(_ -> clicks += 1)>click me</button>" == "<button onclick=$(_ -> clicks += 1)>click me</button>"

        @test htm"<button disabled=$(true)>Can't click me</button>" |> render == "<button disabled>Can&#39;t click me</button>"

        enabledbutton = htm"<button disabled=$(false)>Can click me</button>"
        @test enabledbutton |> render == "<button>Can click me</button>"
        @test htm"<button disabled=$(nothing)>Can click me</button>" == enabledbutton

        @test htm"There's no $(nothing) here." == ("There's no ", nothing, " here.")

        let props = Dict("class" => "active")
            @test htm"<span $props>whoa</span>" == htm"<span class=active>whoa</span>"
            @test htm"<span $(props)>whoa</span>" == htm"<span $props>whoa</span>"
        end

        let props = Dict("style" => Dict("background" => "yellow", "font-weight" => "bold"))
            @test htm"<span $(props)>whoa</span>" == htm"<span style=$(props[\"style\"])>whoa</span>"
            @test_broken htm"<span style=$(props[\"style\"])>whoa</span>" == htm"<span style=\"background: yellow; font-weight: bold;\">whoa</span>"
        end

        let emphasize(text) = htm"<em>$(text)</em>"
            fragment = htm"This is $(emphasize(\"really\")) important."
            @test fragment == ("This is ", htm"<em>really</em>", " important.")
            @test htm"<span>$fragment</span>" |> render == "<span>This is <em>really</em> important.</span>"
        end

        let fragment = htm"It's as easy as $([1, 2, 3])."
            @test fragment == ("It's as easy as ", [1, 2, 3], ".")
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

        # TODO: make this work
        @test_broken htm"<span style=$(Dict(\"background\" => \"yellow\"))>It's all yellow!</span>" |> render == create_element("span", Dict("style" => Dict("background" => "yellow")), "It's all yellow!") |> render
    end

    @testset "Escaped dollar signs`" begin
        @test htm"<span>\$notvar</span>" |> render == raw"<span>&#36;notvar</span>"
        @test htm"<span>\$(notvar)</span>" |> render == raw"<span>&#36;&#40;notvar&#41;</span>"

        @test htm"<\$notvar />" |> render == raw"<&#36;notvar></&#36;notvar>"
        @test htm"<span \$notvar />" |> render == raw"""<span &#36;notvar></span>"""

        @test htm"<\$(notvar) />" |> render == raw"<&#36;&#40;notvar&#41;></&#36;&#40;notvar&#41;>"
        @test htm"<span \$(notvar) />" |> render == raw"""<span &#36;&#40;notvar&#41;></span>"""

        @test htm"<span \$notvar=active />" |> render == raw"""<span &#36;notvar="active"></span>"""
        @test htm"<span class=\$notvar />" |> render == raw"""<span class="$notvar"></span>"""

        @test htm"<span \$(notvar)=active />" |> render == raw"""<span &#36;&#40;notvar&#41;="active"></span>"""
        @test htm"<span class=\$(notvar) />" |> render == raw"""<span class="$(notvar)"></span>"""

        @test htm"<span \$notvar=\"active\" />" |> render == raw"""<span &#36;notvar="active"></span>"""
        @test htm"<span class=\"\$notvar\" />" |> render == raw"""<span class="$notvar"></span>"""

        @test htm"<span \$(notvar)=\"active\" />" |> render == raw"""<span &#36;&#40;notvar&#41;="active"></span>"""
        @test htm"<span class=\"\$(notvar)\" />" |> render == raw"""<span class="$(notvar)"></span>"""
    end

    @testset "create_element" begin
        @test create_element("div") |> render == "<div></div>"
        @test create_element("div", "Hi!") |> render == "<div>Hi&#33;</div>"
        @test create_element("div", Dict("class" => "active")) |> render == "<div class=\"active\"></div>"
        @test create_element("div", Dict("class" => "active"), "Hi!") |> render == "<div class=\"active\">Hi&#33;</div>"
        @test create_element("div", Dict("class" => "active"), "Hi ", "there!") |> render == "<div class=\"active\">Hi there&#33;</div>"

        @test create_element("button", Dict("class" => "active", "disabled" => nothing)) |> render == "<button class=\"active\" disabled></button>"
        @test create_element("button", Dict("class" => "active", "disabled" => nothing), "Click me") |> render == "<button class=\"active\" disabled>Click me</button>"

        @test create_element("circle", Dict("fill" => "red")) |> render == "<circle fill=\"red\" />"
    end

    @testset "Tag (IR)" begin
        @test parsetag(IOBuffer("<div />")) == Tag("div", Dict())
        @test parsetag(IOBuffer("<div>Hi!</div>")) == Tag("div", Dict(), (), ["Hi!"])
        @test parsetag(IOBuffer("<div class=active />")) == Tag("div", Dict("class" => "active"))
        @test parsetag(IOBuffer("<div class=active>Hi!</div>")) == Tag("div", Dict("class" => "active"), (), ["Hi!"])
        @test parsetag(IOBuffer("<div class=active>Hi there!</div>")) == Tag("div", Dict("class" => "active"), (), ["Hi there!"])

        @test parsetag(IOBuffer("<button class=active disabled />")) == Tag("button", Dict("class" => "active", "disabled" => true))
        @test parsetag(IOBuffer("<button class=active disabled>Click me</button>")) == Tag("button", Dict("class" => "active", "disabled" => true), (), ["Click me"])

        @test parsetag(IOBuffer("<circle fill=red />")) == Tag("circle", Dict("fill" => "red"))
    end

    @testset "Stress tests" begin
        quotes = ("", '"', '\'')
        separators = ("", ' ', '\n', '\t', "  ")

        @testset "Basic syntax" begin
            voiddiv = parsetag(IOBuffer("<div />"))
            litclass = parsetag(IOBuffer("<div class=active />"))
            offlitclass = parsetag(IOBuffer("<div class=active disabled />"))

            let c = "Hi there!"
                nonvoiddiv = parsetag(IOBuffer("<div>$(c)</div>"))
                activenonvoiddiv = parsetag(IOBuffer("<div class=active>$(c)</div>"))
                disabledactivenonvoiddiv = parsetag(IOBuffer("<div class=active disabled>$(c)</div>"))

                @testset "Separator `$(s)`" for s in separators
                    @test parsetag(IOBuffer("<div$(s)/>")) == voiddiv

                    @test parsetag(IOBuffer("<div$(s)></div>")) == voiddiv

                    @test parsetag(IOBuffer("<div$(s)>$(c)</div>")) == nonvoiddiv

                    @testset "Quote `$(q)`" for q in quotes
                        @test parsetag(IOBuffer("<div class=$(q)active$(q)$(s)/>")) == litclass
                        @test parsetag(IOBuffer("<div class=$(q)active$(q) disabled$(s)/>")) == offlitclass

                        @test parsetag(IOBuffer("<div class=$(q)active$(q)$(s)></div>")) == litclass
                        @test parsetag(IOBuffer("<div class=$(q)active$(q) disabled$(s)></div>")) == offlitclass

                        @test parsetag(IOBuffer("<div class=$(q)active$(q)$(s)>$(c)</div>")) == activenonvoiddiv
                        @test parsetag(IOBuffer("<div class=$(q)active$(q) disabled$(s)>$(c)</div>")) == disabledactivenonvoiddiv
                    end
                end
            end
        end

        @testset "Dollar signs" begin
            @test parsetag(IOBuffer("<span>\$notvar</span>")) == parsetag(IOBuffer(raw"<span>$notvar</span>"))
            @test parsetag(IOBuffer("<span>\$(notvar)</span>")) == parsetag(IOBuffer(raw"<span>$(notvar)</span>"))

            @testset "Separator `$(s)`" for s in separators
                @test parsetag(IOBuffer("<\$notvar$(s)/>")) == parsetag(IOBuffer(raw"<$notvar></$notvar>"))
                @test parsetag(IOBuffer("<span \$notvar$(s)/>")) == parsetag(IOBuffer(raw"""<span $notvar></span>"""))

                @test parsetag(IOBuffer("<\$(notvar)$(s)/>")) == parsetag(IOBuffer(raw"<$(notvar)></$(notvar)>"))
                @test parsetag(IOBuffer("<span \$(notvar)$(s)/>")) == parsetag(IOBuffer(raw"""<span $(notvar)></span>"""))

                @testset "Quote `$(q)`" for q in quotes
                    @test parsetag(IOBuffer("<span \$notvar=$(q)active$(q)$(s)/>")) == parsetag(IOBuffer(raw"""<span $notvar="active"></span>"""))
                    @test parsetag(IOBuffer("<span class=$(q)\$notvar$(q)$(s)/>")) == parsetag(IOBuffer(raw"""<span class="$notvar"></span>"""))

                    @test parsetag(IOBuffer("<span \$(notvar)=$(q)active$(q)$(s)/>")) == parsetag(IOBuffer(raw"""<span $(notvar)="active"></span>"""))
                    @test parsetag(IOBuffer("<span class=$(q)\$(notvar)$(q)$(s)/>")) == parsetag(IOBuffer(raw"""<span class="$(notvar)"></span>"""))
                end
            end
        end
    end
end
