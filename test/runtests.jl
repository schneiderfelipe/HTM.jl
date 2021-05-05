using Markdown
using Test

using Hyperscript

using HTM

const r = Hyperscript.render

@testset "HTM.jl" begin
    # Warning: some test cases may not represent supported usage.
    @testset "Features" begin
        @testset "Spread attributes" for attrs in ([:class => "fruit"], Dict(:class => "fruit"),
                                                   ["class" => "fruit"], Dict("class" => "fruit"))
            @test htm"<div $(attrs)></div>" |> r == "<div class=\"fruit\"></div>"
        end

        @testset "Styles" begin
            @testset "Interpolations" for style in ([:background => "orange"], Dict(:background => "orange"),
                                                    ["background" => "orange"], Dict("background" => "orange"))
                @test htm"<span style=$(style)>pineapple</span>" |> r == "<span style=\"background:orange;\">pineapple</span>"
            end
            @test htm"<span style='background:$(\"orange\");'>pineapple</span>" |> r == "<span style=\"background:orange;\">pineapple</span>"
            @test_broken htm"<span style=background:$(\"orange\");>pineapple</span>" |> r == "<span style=\"background:orange;\">pineapple</span>"
        end

        @testset "Classes" begin
            @testset "Interpolations" for class in ("fruit sour ", ["fruit", "sour", "sour"], Set(["fruit", "sour", "sour"]))
                # TODO: remove space at the end
                @test htm"<div class=$(class)></div>" |> r == "<div class=\"fruit sour \"></div>"
            end
            @test htm"<div class='$(\"sour\") fruit'></div>" |> r == "<div class=\" fruit sour \"></div>"
        end

        @testset "Self-closing tags" begin
            @test htm"<div />" |> r == "<div></div>"
            @test htm"<circle />" |> r == "<circle />"
        end

        @testset "Multiple root elements (fragments)" begin
            @test htm"<div /><div />" == [htm"<div />", htm"<div />"]
        end

        @testset "Short circuit rendering" begin
            @test htm"<div>$(true || \"🍍\")</div>" |> r == "<div></div>"
            @test htm"<div>$(false || \"🍍\")</div>" |> r == "<div>🍍</div>"
            @test htm"$(true || \"🍍\")" === true
            @test htm"$(false || \"🍍\")" == "🍍"
        end

        @testset "Boolean attributes" begin
            @test htm"<div draggable />" |> r == "<div draggable></div>"
            @test htm"<div draggable=$(true) />" |> r == "<div draggable></div>"
            @test htm"<div draggable=$(false) />" |> r == "<div></div>"
        end

        @testset "HTML optional quotes" begin
            @test htm"<div class=fruit></div>" |> r == "<div class=\"fruit\"></div>"

            @testset "URLs" begin
                @test htm"<script src=https://www.example.org/code/library.js />" |> r == "<script src=\"https://www.example.org/code/library.js\"></script>"
                @test htm"<script src=https://www.example.org/code/library.js></script>" |> r == "<script src=\"https://www.example.org/code/library.js\"></script>"
            end
        end

        @testset "Components" begin
            struct Fruit
                name::String
                emoji::Char
            end
            @test htm"$(Fruit(\"pineapple\", '🍍'))" == Fruit("pineapple", '🍍')
            Base.show(io::IO, m::MIME"text/html", 🍎::Fruit) = show(io, m, htm"$(🍎.name): <div class=fruit>$(🍎.emoji)</div>")
            Base.show(io::IO, ::MIME"text/plain", 🍎::Fruit) = show(io, MIME("text/html"), 🍎)
            @test_broken htm"<p>$(Fruit(\"pineapple\", '🍍'))</p>" |> r == "<p>pineapple: <div class=\"fruit\">🍍</div></p>"
        end

        @testset "Generic end-tags" begin
            @test htm"<div>🍍<//>" |> r == "<div>🍍</div>"
        end

        @testset "HTML-style comments" begin
            @test htm"<!-- 🍌 -->" === nothing
            @test htm"<!-- 🍌 --><div></div>" |> r == "<div></div>"
            @test htm"<div></div><!-- 🍌 -->" |> r == "<div></div>"
            @test htm"<div><!-- 🍌 --></div>" |> r == "<div></div>"
        end

        @testset "Callbacks" begin
            @test_broken htm"<button onclick=$(() -> pineapples += 1)>🍍</button>" |> r == "<button onclick=\"pineapples += 1\">🍍</button>"
        end

        # TODO: can tag be empty? See <https://pt-br.reactjs.org/docs/fragments.html#short-syntax> for a usage.
    end

    @testset "Common HTML elements" begin
        # The Pareto slice (>80%) of <https://www.advancedwebranking.com/html/>
        @test htm"<html/>" |> r == "<html></html>"
        @test htm"<head/>" |> r == "<head></head>"
        @test htm"<body/>" |> r == "<body></body>"
        @test htm"<title/>" |> r == "<title></title>"
        @test htm"<meta/>" |> r == "<meta />"
        @test htm"<div/>" |> r == "<div></div>"
        @test htm"<a/>" |> r == "<a></a>"
        @test htm"<link/>" |> r == "<link />"
        @test htm"<span/>" |> r == "<span></span>"
        @test htm"<p/>" |> r == "<p></p>"
        @test htm"<li/>" |> r == "<li></li>"
        @test htm"<ul/>" |> r == "<ul></ul>"
        @test htm"<style/>" |> r == "<style></style>"

        # Surprisingly common specifics
        @test_broken htm"""<script>
            document.getElementById("demo").innerHTML = "Hello JavaScript!";
        </script>""" |> r == """<script>
            document.getElementById("demo").innerHTML = "Hello JavaScript!";
        </script>"""
        @test htm"<img src=img_girl.jpg alt='Girl in a jacket' width=500 height=600/>" |> r == """<img alt="Girl in a jacket" height="600" src="img_girl.jpg" width="500" />"""
        @test htm"<img src=red-circle.svg height=32 width=32 alt='A red circle'/>" |> r == """<img height="32" alt="A red circle" src="red-circle.svg" width="32" />"""
        @test htm"<p>My favorite color is <del>blue</del> <ins>red</ins>!</p>" |> r == "<p>My favorite color is <del>blue</del><ins>red</ins>&#33;</p>"

        @test htm"<source src=horse.ogg type='audio/ogg'/>" |> r == """<source src="horse.ogg" type="audio/ogg" />"""
        @test htm"<template>
            <h2>Flower</h2>
            <img src=img_white_flower.jpg width=214 height=204/>
        </template>" |> r == """<template><h2>Flower</h2><img height="204" src="img_white_flower.jpg" width="214" /></template>"""
    end

    @testset "Common SVG elements" begin
        # TODO: make this more complete
        @test htm"""<svg width=100 height=100>
            <circle cx=50 cy=50 r=40 stroke=green stroke-width=4 fill=yellow/>
        </svg>""" |> r == """<svg height="100" width="100"><circle cy="50" stroke-width="4" stroke="green" r="40" fill="yellow" cx="50" /></svg>"""
    end

    @testset "Return types" begin
        @test htm"<div>🍍</div>" isa Hyperscript.Node
        @test htm"🍍" isa String
        @test htm"" === nothing
        @test htm"<div /><div />" isa Vector{Hyperscript.Node{Hyperscript.HTMLSVG}}
        @test htm"🍍<div />" isa Vector{Any}
    end

    @testset "Whitespace" begin
        @test htm"""
            <div class=fruit>
                🍍
            </div>
        """ |> r == "<div class=\"fruit\">\n        🍍\n    </div>"
    end

    @testset "Edge cases" begin
        @test htm"<html class=no-js lang=\"\" />" |> r == "<html class=\"no-js\" lang=\"\"></html>"
    end

    @testset "Interpolations" begin
        @testset "Variables" begin
            @testset "As children" begin
                child = "🍍"
                @test htm"<div>$(child)</div>" |> r == "<div>🍍</div>"
            end

            @testset "As attributes" begin
                @testset "As keys" for key in ("class", :class, nothing, true, missing, 1, 1.0, [1, 2, 3], (1, 2, 3), "class" => "fruit")
                    @test_throws MethodError htm"<div $(key)=fruit></div>"
                end

                @testset "As values" begin
                    value = "fruit"
                    @test htm"<div class=$(value)></div>" |> r == "<div class=\"fruit\"></div>"
                end
            end

            @testset "As tags" begin
                tag = "div"
                @testset "Matching end-tag" begin
                    @testset "Complete tags" begin
                        @test htm"<$(tag)></$(tag)>" |> r == "<div></div>"
                    end

                    @testset "Partial tags" begin
                        @test htm"<h$(tag)></h$(tag)>" |> r == "<hdiv></hdiv>"
                    end
                end

                @testset "Universal end-tag" begin
                    @testset "Complete tags" begin
                        @test htm"<$(tag)><//>" |> r == "<div></div>"
                    end

                    @testset "Partial tags" begin
                        @test htm"<h$(tag)><//>" |> r == "<hdiv></hdiv>"
                    end
                end
            end
        end

        @testset "Literals" begin
            @testset "As children" begin
                @test htm"<div>$(nothing)</div>" |> r == "<div></div>"
                @test htm"<div>$(missing)</div>" |> r == "<div>missing</div>"
                @test htm"<div>$(1)</div>" |> r == "<div>1</div>"
                @test htm"<div>$(1.0)</div>" |> r == "<div>1.0</div>"
                @test htm"<div>$(true)</div>" |> r == "<div></div>"
                @test htm"<div>$(:symbol)</div>" |> r == "<div>symbol</div>"
                @test htm"<div>$(\"string\")</div>" |> r == "<div>string</div>"
                @test htm"<div>$([1, 2, 3])</div>" |> r == "<div>123</div>"
                @test htm"<div>$((1, 2, 3))</div>" |> r == "<div>123</div>"
                @test htm"<div>$(\"class\" => \"fruit\")</div>" |> r == "<div>&#34;class&#34; &#61;&#62; &#34;fruit&#34;</div>"
                @test htm"<div>$(Dict(\"class\" => \"fruit\"))</div>" |> r == "<div>Dict&#40;&#34;class&#34; &#61;&#62; &#34;fruit&#34;&#41;</div>"

                @testset "Exotic objects" begin
                    @test htm"<div>$(md\"# 🍍\")</div>" |> r == "<div><div class=\"markdown\"><h1>🍍</h1>\n</div></div>"
                    @test htm"<div>$(html\"<div></div>\")</div>" |> r == "<div><div></div></div>"
                    @test htm"<div>$(HTML(\"<div></div>\"))</div>" |> r == "<div><div></div></div>"
                end
            end

            @testset "As attributes" begin
                @testset "As keys" begin
                    @test_throws MethodError htm"<div $(Dict(\"class\" => \"fruit\"))=pineapple></div>" |> r == "<div class=\"fruit\" =\"pineapple\"></div>"
                end

                @testset "As values" begin
                    @test htm"<div key=$(nothing)></div>" |> r == "<div></div>"
                    @test_throws TypeError htm"<div key=$(missing)></div>" |> r == "<div key=\"missing\"></div>"
                    @test htm"<div key=$(1)></div>" |> r == "<div key=\"1\"></div>"
                    @test htm"<div key=$(1.0)></div>" |> r == "<div key=\"1.0\"></div>"
                    @test htm"<div key=$(true)></div>" |> r == "<div key></div>"
                    @test htm"<div key=$(:symbol)></div>" |> r == "<div key=\"symbol\"></div>"
                    @test htm"<div key=$(\"string\")></div>" |> r == "<div key=\"string\"></div>"
                    @test htm"<div key=$(\"class\" => \"fruit\")></div>" |> r == "<div key=\"&#34;class&#34; =&#62; &#34;fruit&#34;\"></div>"
                    @test htm"<div key=$(Dict(\"class\" => \"fruit\"))></div>" |> r == "<div key=\"Dict(&#34;class&#34; =&#62; &#34;fruit&#34;)\"></div>"
                end
            end

            @testset "As tags" begin
                @testset "Matching end-tag" begin
                    @testset "Complete tags" begin
                        @test_throws MethodError htm"<$(nothing)></$(nothing)>" |> r == "<nothing></nothing>"
                        @test_throws MethodError htm"<$(missing)></$(missing)>" |> r == "<missing></missing>"
                        @test_throws MethodError htm"<$(1)></$(1)>" |> r == "<1></1>"
                        @test_throws MethodError htm"<$(1.0)></$(1.0)>" |> r == "<1.0></1.0>"
                        @test_throws MethodError htm"<$(true)></$(true)>" |> r == "<true></true>"
                        @test_throws MethodError htm"<$(:symbol)></$(:symbol)>" |> r == "<symbol></symbol>"
                        @test htm"<$(\"string\")></$(\"string\")>" |> r == "<string></string>"
                        @test htm"<$([1, 2, 3])></$([1, 2, 3])>" |> r == "<123></123>"
                        @test_throws MethodError htm"<$(\"class\" => \"fruit\")></$(\"class\" => \"fruit\")>" |> r == "<&#34;class&#34; &#61;&#62; &#34;fruit&#34;></&#34;class&#34; &#61;&#62; &#34;fruit&#34;>"
                        @test_throws MethodError htm"<$(Dict(\"class\" => \"fruit\"))></$(Dict(\"class\" => \"fruit\"))>" |> r == "<Dict&#40;&#34;class&#34; &#61;&#62; &#34;fruit&#34;&#41;></Dict&#40;&#34;class&#34; &#61;&#62; &#34;fruit&#34;&#41;>"
                    end

                    @testset "Partial tags" begin
                        @test htm"<h$(nothing)></h$(nothing)>" |> r == "<hnothing></hnothing>"
                        @test htm"<h$(missing)></h$(missing)>" |> r == "<hmissing></hmissing>"
                        @test htm"<h$(1)></h$(1)>" |> r == "<h1></h1>"
                        @test htm"<h$(1.0)></h$(1.0)>" |> r == "<h1.0></h1.0>"
                        @test htm"<h$(true)></h$(true)>" |> r == "<htrue></htrue>"
                        @test htm"<h$(:symbol)></h$(:symbol)>" |> r == "<hsymbol></hsymbol>"
                        @test htm"<h$(\"string\")></h$(\"string\")>" |> r == "<hstring></hstring>"
                        @test htm"<h$([1, 2, 3])></h$([1, 2, 3])>" |> r == "<h123></h123>"
                        @test htm"<h$(\"class\" => \"fruit\")></h$(\"class\" => \"fruit\")>" |> r == "<h&#34;class&#34; &#61;&#62; &#34;fruit&#34;></h&#34;class&#34; &#61;&#62; &#34;fruit&#34;>"
                        @test htm"<h$(Dict(\"class\" => \"fruit\"))></h$(Dict(\"class\" => \"fruit\"))>" |> r == "<hDict&#40;&#34;class&#34; &#61;&#62; &#34;fruit&#34;&#41;></hDict&#40;&#34;class&#34; &#61;&#62; &#34;fruit&#34;&#41;>"
                    end
                end

                @testset "Universal end-tag" begin
                    @testset "Complete tags" begin
                        @test_throws MethodError htm"<$(nothing)><//>" |> r == "<nothing></nothing>"
                        @test_throws MethodError htm"<$(missing)><//>" |> r == "<missing></missing>"
                        @test_throws MethodError htm"<$(1)><//>" |> r == "<1></1>"
                        @test_throws MethodError htm"<$(1.0)><//>" |> r == "<1.0></1.0>"
                        @test_throws MethodError htm"<$(true)><//>" |> r == "<true></true>"
                        @test_throws MethodError htm"<$(:symbol)><//>" |> r == "<symbol></symbol>"
                        @test htm"<$(\"string\")><//>" |> r == "<string></string>"
                        @test htm"<$([1, 2, 3])><//>" |> r == "<123></123>"
                        @test_throws MethodError htm"<$(\"class\" => \"fruit\")><//>" |> r == "<&#34;class&#34; &#61;&#62; &#34;fruit&#34;></&#34;class&#34; &#61;&#62; &#34;fruit&#34;>"
                        @test_throws MethodError htm"<$(Dict(\"class\" => \"fruit\"))><//>" |> r == "<Dict&#40;&#34;class&#34; &#61;&#62; &#34;fruit&#34;&#41;></Dict&#40;&#34;class&#34; &#61;&#62; &#34;fruit&#34;&#41;>"
                    end

                    @testset "Partial tags" begin
                        @test htm"<h$(nothing)><//>" |> r == "<hnothing></hnothing>"
                        @test htm"<h$(missing)><//>" |> r == "<hmissing></hmissing>"
                        @test htm"<h$(1)><//>" |> r == "<h1></h1>"
                        @test htm"<h$(1.0)><//>" |> r == "<h1.0></h1.0>"
                        @test htm"<h$(true)><//>" |> r == "<htrue></htrue>"
                        @test htm"<h$(:symbol)><//>" |> r == "<hsymbol></hsymbol>"
                        @test htm"<h$(\"string\")><//>" |> r == "<hstring></hstring>"
                        @test htm"<h$([1, 2, 3])><//>" |> r == "<h123></h123>"
                        @test htm"<h$(\"class\" => \"fruit\")><//>" |> r == "<h&#34;class&#34; &#61;&#62; &#34;fruit&#34;></h&#34;class&#34; &#61;&#62; &#34;fruit&#34;>"
                        @test htm"<h$(Dict(\"class\" => \"fruit\"))><//>" |> r == "<hDict&#40;&#34;class&#34; &#61;&#62; &#34;fruit&#34;&#41;></hDict&#40;&#34;class&#34; &#61;&#62; &#34;fruit&#34;&#41;>"
                    end
                end
            end
        end
    end

    @testset "Escaped characters`" begin
        @test htm"<p>Look, Ma, $(\"<em>automatic escaping</em>\")!</p>" |> r == "<p>Look, Ma, &#60;em&#62;automatic escaping&#60;/em&#62;&#33;</p>"

        @testset "Escaped dollar signs`" begin
            @test htm"<div>\$notvar</div>" |> r == raw"<div>&#36;notvar</div>"
            @test htm"<div>\$(notvar)</div>" |> r == raw"<div>&#36;&#40;notvar&#41;</div>"

            @test htm"<\$notvar />" |> r == raw"<&#36;notvar></&#36;notvar>"
            @test_broken htm"<div \$notvar />" |> r == raw"""<div &#36;notvar></div>"""

            @test htm"<\$(notvar) />" |> r == raw"<&#36;&#40;notvar&#41;></&#36;&#40;notvar&#41;>"
            @test_broken htm"<div \$(notvar) />" |> r == raw"""<div &#36;&#40;notvar&#41;></div>"""

            @test_broken htm"<div \$notvar=fruit />" |> r == raw"""<div &#36;notvar="fruit"></div>"""
            @test_broken htm"<div class=\$notvar />" |> r == raw"""<div class="$notvar"></div>"""

            @test_broken htm"<div \$(notvar)=fruit />" |> r == raw"""<div &#36;&#40;notvar&#41;="fruit"></div>"""
            @test_broken htm"<div class=\$(notvar) />" |> r == raw"""<div class="$(notvar)"></div>"""

            @test_broken htm"<div \$notvar='fruit' />" |> r == raw"""<div &#36;notvar="fruit"></div>"""
            @test_broken htm"<div class='\$notvar' />" |> r == raw"""<div class="$notvar"></div>"""

            @test_broken htm"<div \$(notvar)='fruit' />" |> r == raw"""<div &#36;&#40;notvar&#41;="fruit"></div>"""
            @test_broken htm"<div class='\$(notvar)' />" |> r == raw"""<div class="$(notvar)"></div>"""
        end

        @testset "HTML entity escape trick" begin
            @test htm"<p>🍍 🍌</p>" |> r == "<p>🍍 🍌</p>"
            @test htm"<p>🍍&nbsp;🍌</p>" |> r == "<p>🍍&#38;nbsp;🍌</p>"
            @test htm"<p>🍍$(html\"&nbsp;\")🍌</p>" |> r == "<p>🍍&nbsp;🍌</p>"
            @test htm"<p>🍍$(HTML(\"&nbsp;\"))🍌</p>" |> r == "<p>🍍&nbsp;🍌</p>"
        end
    end

    @testset "Create elements" begin
        @test HTM.create_element("div", []) |> r == "<div></div>"
        @test HTM.create_element("div", [], []) |> r == "<div></div>"
        @test HTM.create_element("div", [], "Hi!") |> r == "<div>Hi&#33;</div>"
        @test HTM.create_element("div", [], ["Hi!"]) |> r == "<div>Hi&#33;</div>"
        @test HTM.create_element("div", ["class" => "fruit"]) |> r == "<div class=\"fruit\"></div>"
        @test HTM.create_element("div", ["class" => "fruit"], "Hi!") |> r == "<div class=\"fruit\">Hi&#33;</div>"
        @test HTM.create_element("div", ["class" => "fruit"], "Hi ", "there!") |> r == "<div class=\"fruit\">Hi there&#33;</div>"

        @test HTM.create_element("button", ["class" => "fruit", "disabled" => nothing]) |> r == "<button class=\"fruit\" disabled></button>"
        @test HTM.create_element("button", ["class" => "fruit", "disabled" => nothing], "Click me") |> r == "<button class=\"fruit\" disabled>Click me</button>"

        @test HTM.create_element("circle", ["fill" => "orange"]) |> r == "<circle fill=\"orange\" />"
    end

    @testset "Internal representation" begin
        @test HTM.parsenode(IOBuffer("<div />")) == HTM.Node(["div"])
        @test HTM.parsenode(IOBuffer("<div>Hi!</div>")) == HTM.Node(["div"], [], ["Hi!"])
        @test HTM.parsenode(IOBuffer("<div class=fruit />")) == HTM.Node(["div"], [:class => ["fruit"]])
        @test HTM.parsenode(IOBuffer("<div class=fruit>Hi!</div>")) == HTM.Node(["div"], [:class => ["fruit"]], ["Hi!"])
        @test HTM.parsenode(IOBuffer("<div class=fruit>Hi there!</div>")) == HTM.Node(["div"], [:class => ["fruit"]], ["Hi there!"])

        @test HTM.parsenode(IOBuffer("<button class=fruit disabled />")) == HTM.Node(["button"], [:class => ["fruit"], :disabled => [raw"$(true)"]])
        @test HTM.parsenode(IOBuffer("<button class=fruit disabled>Click me</button>")) == HTM.Node(["button"], [:class => ["fruit"], :disabled => [raw"$(true)"]], ["Click me"])

        @test HTM.parsenode(IOBuffer("<circle fill=orange />")) == HTM.Node(["circle"], [:fill => ["orange"]])

        @testset "Stress tests" begin
            quotes = ("", '"', '\'')
            separators = ("", ' ', '\n', '\t', "  ")

            @testset "Basic syntax" begin
                voiddiv = HTM.parsenode(IOBuffer("<div />"))
                litclass = HTM.parsenode(IOBuffer("<div class=fruit />"))
                offlitclass = HTM.parsenode(IOBuffer("<div class=fruit draggable />"))

                let c = "Hi there!"
                    nonvoiddiv = HTM.parsenode(IOBuffer("<div>$(c)</div>"))
                    fruitnonvoiddiv = HTM.parsenode(IOBuffer("<div class=fruit>$(c)</div>"))
                    draggablefruitnonvoiddiv = HTM.parsenode(IOBuffer("<div class=fruit draggable>$(c)</div>"))

                    @testset "Separator `$(s)`" for s in separators
                        @test HTM.parsenode(IOBuffer("<div$(s)/>")) == voiddiv

                        @test HTM.parsenode(IOBuffer("<div$(s)></div>")) == voiddiv

                        @test HTM.parsenode(IOBuffer("<div$(s)>$(c)</div>")) == nonvoiddiv

                        @testset "Quote `$(q)`" for q in quotes
                            @test HTM.parsenode(IOBuffer("<div class=$(q)fruit$(q)$(s)/>")) == litclass
                            @test HTM.parsenode(IOBuffer("<div class=$(q)fruit$(q) draggable$(s)/>")) == offlitclass

                            @test HTM.parsenode(IOBuffer("<div class=$(q)fruit$(q)$(s)></div>")) == litclass
                            @test HTM.parsenode(IOBuffer("<div class=$(q)fruit$(q) draggable$(s)></div>")) == offlitclass

                            @test HTM.parsenode(IOBuffer("<div class=$(q)fruit$(q)$(s)>$(c)</div>")) == fruitnonvoiddiv
                            @test HTM.parsenode(IOBuffer("<div class=$(q)fruit$(q) draggable$(s)>$(c)</div>")) == draggablefruitnonvoiddiv
                        end
                    end
                end
            end

            @testset "Dollar signs" begin
                @test HTM.parsenode(IOBuffer("<div>\$notvar</div>")) == HTM.parsenode(IOBuffer(raw"<div>$notvar</div>"))
                @test HTM.parsenode(IOBuffer("<div>\$(notvar)</div>")) == HTM.parsenode(IOBuffer(raw"<div>$(notvar)</div>"))

                @testset "Separator `$(s)`" for s in separators
                    @test HTM.parsenode(IOBuffer("<\$notvar$(s)/>")) == HTM.parsenode(IOBuffer(raw"<$notvar></$notvar>"))
                    @test HTM.parsenode(IOBuffer("<div \$notvar$(s)/>")) == HTM.parsenode(IOBuffer(raw"""<div $notvar></div>"""))

                    @test HTM.parsenode(IOBuffer("<\$(notvar)$(s)/>")) == HTM.parsenode(IOBuffer(raw"<$(notvar)></$(notvar)>"))
                    @test HTM.parsenode(IOBuffer("<div \$(notvar)$(s)/>")) == HTM.parsenode(IOBuffer(raw"""<div $(notvar)></div>"""))

                    @testset "Quote `$(q)`" for q in quotes
                        @test HTM.parsenode(IOBuffer("<div \$notvar=$(q)fruit$(q)$(s)/>")) == HTM.parsenode(IOBuffer(raw"""<div $notvar="fruit"></div>"""))
                        @test HTM.parsenode(IOBuffer("<div class=$(q)\$notvar$(q)$(s)/>")) == HTM.parsenode(IOBuffer(raw"""<div class="$notvar"></div>"""))

                        @test HTM.parsenode(IOBuffer("<div \$(notvar)=$(q)fruit$(q)$(s)/>")) == HTM.parsenode(IOBuffer(raw"""<div $(notvar)="fruit"></div>"""))
                        @test HTM.parsenode(IOBuffer("<div class=$(q)\$(notvar)$(q)$(s)/>")) == HTM.parsenode(IOBuffer(raw"""<div class="$(notvar)"></div>"""))
                    end
                end
            end
        end
    end
end
