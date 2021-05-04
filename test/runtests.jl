using Markdown
using Test

using Hyperscript

using HTM

const r = Hyperscript.render

@testset "HTM.jl" begin
    # Warning: some test cases may not represent supported usage.
    @testset "Features" begin
        @testset "Spread attributes" begin
            attrs = Dict("class" => "fruit")
            @test htm"<div $(attrs)></div>" |> r == "<div class=\"fruit\"></div>"
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

        @testset "Styles" begin
            style = Dict("background" => "orange")
            @test htm"<span style=$(style)>pineapple</span>" |> r == "<span style=\"background:orange;\">pineapple</span>"
            @test htm"<span style='background:$(style[\"background\"]);'>pineapple</span>" |> r == "<span style=\"background:orange;\">pineapple</span>"
        end

        @testset "Classes" begin
            # TODO: support iterables in general!
            @test htm"<div class=$([\"fruit\", \"sour\", \"sour\"])></div>" |> r == "<div class=\"fruit sour \"></div>"
        end

        @testset "Callbacks" begin
            @test_broken htm"<button onclick=$(() -> pineapples += 1)>🍍</button>" |> r == "<button onclick=\"pineapples += 1\">🍍</button>"
        end
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

    @testset "Interpolations" begin
        @testset "Variables" begin
            @testset "As children" begin
                child = "🍍"
                @test htm"<div>$(child)</div>" |> r == "<div>🍍</div>"
            end

            @testset "As attributes" begin
                @testset "As keys" for key in ("class", :class, nothing, true, missing, 1, 1.0, [1, 2, 3], (1, 2, 3), "fruit" => "pineapple")
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
                @test htm"<div>$(\"fruit\" => \"pineapple\")</div>" |> r == "<div>&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;</div>"
                @test htm"<div>$(Dict(\"fruit\" => \"pineapple\"))</div>" |> r == "<div>Dict&#40;&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;&#41;</div>"

                @testset "Exotic objects" begin
                    @test htm"<div>$(md\"# 🍍\")</div>" |> r == "<div><div class=\"markdown\"><h1>🍍</h1>\n</div></div>"
                    @test htm"<div>$(html\"<div></div>\")</div>" |> r == "<div><div></div></div>"
                    @test htm"<div>$(HTML(\"<div></div>\"))</div>" |> r == "<div><div></div></div>"
                end
            end

            @testset "As attributes" begin
                @testset "As keys" begin
                    @test htm"<div $(Dict(\"fruit\" => \"pineapple\"))=fruit></div>" |> r == "<div fruit=\"pineapple\" =\"fruit\"></div>"
                end

                @testset "As values" begin
                    @test htm"<div key=$(nothing)></div>" |> r == "<div></div>"
                    @test_throws TypeError htm"<div key=$(missing)></div>" |> r == "<div key=\"missing\"></div>"
                    @test htm"<div key=$(1)></div>" |> r == "<div key=\"1\"></div>"
                    @test htm"<div key=$(1.0)></div>" |> r == "<div key=\"1.0\"></div>"
                    @test htm"<div key=$(true)></div>" |> r == "<div key></div>"
                    @test htm"<div key=$(:symbol)></div>" |> r == "<div key=\"symbol\"></div>"
                    @test htm"<div key=$(\"string\")></div>" |> r == "<div key=\"string\"></div>"
                    @test htm"<div key=$(\"fruit\" => \"pineapple\")></div>" |> r == "<div key=\"&#34;fruit&#34; =&#62; &#34;pineapple&#34;\"></div>"
                    @test htm"<div key=$(Dict(\"fruit\" => \"pineapple\"))></div>" |> r == "<div key=\"Dict(&#34;fruit&#34; =&#62; &#34;pineapple&#34;)\"></div>"
                end
            end

            @testset "As tags" begin
                @testset "Matching end-tag" begin
                    @testset "Complete tags" begin
                        @test htm"<$(nothing)></$(nothing)>" |> r == "<nothing></nothing>"
                        @test htm"<$(missing)></$(missing)>" |> r == "<missing></missing>"
                        @test htm"<$(1)></$(1)>" |> r == "<1></1>"
                        @test htm"<$(1.0)></$(1.0)>" |> r == "<1.0></1.0>"
                        @test htm"<$(true)></$(true)>" |> r == "<true></true>"
                        @test htm"<$(:symbol)></$(:symbol)>" |> r == "<symbol></symbol>"
                        @test htm"<$(\"string\")></$(\"string\")>" |> r == "<string></string>"
                        @test htm"<$([1, 2, 3])></$([1, 2, 3])>" |> r == "<123></123>"
                        @test htm"<$(\"fruit\" => \"pineapple\")></$(\"fruit\" => \"pineapple\")>" |> r == "<&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;></&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;>"
                        @test htm"<$(Dict(\"fruit\" => \"pineapple\"))></$(Dict(\"fruit\" => \"pineapple\"))>" |> r == "<Dict&#40;&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;&#41;></Dict&#40;&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;&#41;>"
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
                        @test htm"<h$(\"fruit\" => \"pineapple\")></h$(\"fruit\" => \"pineapple\")>" |> r == "<h&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;></h&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;>"
                        @test htm"<h$(Dict(\"fruit\" => \"pineapple\"))></h$(Dict(\"fruit\" => \"pineapple\"))>" |> r == "<hDict&#40;&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;&#41;></hDict&#40;&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;&#41;>"
                    end
                end

                @testset "Universal end-tag" begin
                    @testset "Complete tags" begin
                        @test htm"<$(nothing)><//>" |> r == "<nothing></nothing>"
                        @test htm"<$(missing)><//>" |> r == "<missing></missing>"
                        @test htm"<$(1)><//>" |> r == "<1></1>"
                        @test htm"<$(1.0)><//>" |> r == "<1.0></1.0>"
                        @test htm"<$(true)><//>" |> r == "<true></true>"
                        @test htm"<$(:symbol)><//>" |> r == "<symbol></symbol>"
                        @test htm"<$(\"string\")><//>" |> r == "<string></string>"
                        @test htm"<$([1, 2, 3])><//>" |> r == "<123></123>"
                        @test htm"<$(\"fruit\" => \"pineapple\")><//>" |> r == "<&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;></&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;>"
                        @test htm"<$(Dict(\"fruit\" => \"pineapple\"))><//>" |> r == "<Dict&#40;&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;&#41;></Dict&#40;&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;&#41;>"
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
                        @test htm"<h$(\"fruit\" => \"pineapple\")><//>" |> r == "<h&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;></h&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;>"
                        @test htm"<h$(Dict(\"fruit\" => \"pineapple\"))><//>" |> r == "<hDict&#40;&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;&#41;></hDict&#40;&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;&#41;>"
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
            @test htm"<div \$notvar />" |> r == raw"""<div &#36;notvar></div>"""

            @test htm"<\$(notvar) />" |> r == raw"<&#36;&#40;notvar&#41;></&#36;&#40;notvar&#41;>"
            @test htm"<div \$(notvar) />" |> r == raw"""<div &#36;&#40;notvar&#41;></div>"""

            @test htm"<div \$notvar=fruit />" |> r == raw"""<div &#36;notvar="fruit"></div>"""
            @test_broken htm"<div class=\$notvar />" |> r == raw"""<div class="$notvar"></div>"""

            @test htm"<div \$(notvar)=fruit />" |> r == raw"""<div &#36;&#40;notvar&#41;="fruit"></div>"""
            @test_broken htm"<div class=\$(notvar) />" |> r == raw"""<div class="$(notvar)"></div>"""

            @test htm"<div \$notvar='fruit' />" |> r == raw"""<div &#36;notvar="fruit"></div>"""
            @test_broken htm"<div class='\$notvar' />" |> r == raw"""<div class="$notvar"></div>"""

            @test htm"<div \$(notvar)='fruit' />" |> r == raw"""<div &#36;&#40;notvar&#41;="fruit"></div>"""
            @test_broken htm"<div class='\$(notvar)' />" |> r == raw"""<div class="$(notvar)"></div>"""
        end

        @testset "HTML entity escape trick" begin
            @test htm"<p>🍍 🍌</p>" |> r == "<p>🍍 🍌</p>"
            @test htm"<p>🍍&nbsp;🍌</p>" |> r == "<p>🍍&#38;nbsp;🍌</p>"
            @test htm"<p>🍍$(html\"&nbsp;\")🍌</p>" |> r == "<p>🍍&nbsp;🍌</p>"
            @test htm"<p>🍍$(HTML(\"&nbsp;\"))🍌</p>" |> r == "<p>🍍&nbsp;🍌</p>"
        end
    end

    @testset "create_element" begin
        @test create_element("div", (), ()) |> r == "<div></div>"
        @test create_element("div", (), "Hi!") |> r == "<div>Hi&#33;</div>"
        @test create_element("div", Dict("class" => "fruit")) |> r == "<div class=\"fruit\"></div>"
        @test create_element("div", Dict("class" => "fruit"), "Hi!") |> r == "<div class=\"fruit\">Hi&#33;</div>"
        @test create_element("div", Dict("class" => "fruit"), "Hi ", "there!") |> r == "<div class=\"fruit\">Hi there&#33;</div>"

        @test create_element("button", Dict("class" => "fruit", "disabled" => nothing)) |> r == "<button class=\"fruit\" disabled></button>"
        @test create_element("button", Dict("class" => "fruit", "disabled" => nothing), "Click me") |> r == "<button class=\"fruit\" disabled>Click me</button>"

        @test create_element("circle", Dict("fill" => "orange")) |> r == "<circle fill=\"orange\" />"
    end

    @testset "Internal representation" begin
        @test HTM.parsenode(IOBuffer("<div />")) == HTM.Node(["div"], Dict())
        @test HTM.parsenode(IOBuffer("<div>Hi!</div>")) == HTM.Node(["div"], Dict(), String[], ["Hi!"])
        @test HTM.parsenode(IOBuffer("<div class=fruit />")) == HTM.Node(["div"], Dict("class" => ["fruit"]))
        @test HTM.parsenode(IOBuffer("<div class=fruit>Hi!</div>")) == HTM.Node(["div"], Dict("class" => ["fruit"]), String[], ["Hi!"])
        @test HTM.parsenode(IOBuffer("<div class=fruit>Hi there!</div>")) == HTM.Node(["div"], Dict("class" => ["fruit"]), String[], ["Hi there!"])

        @test HTM.parsenode(IOBuffer("<button class=fruit disabled />")) == HTM.Node(["button"], Dict("class" => ["fruit"], "disabled" => [raw"$(true)"]))
        @test HTM.parsenode(IOBuffer("<button class=fruit disabled>Click me</button>")) == HTM.Node(["button"], Dict("class" => ["fruit"], "disabled" => [raw"$(true)"]), String[], ["Click me"])

        @test HTM.parsenode(IOBuffer("<circle fill=orange />")) == HTM.Node(["circle"], Dict("fill" => ["orange"]))

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
