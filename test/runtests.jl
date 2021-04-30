using HTM
using HTM: parsetag, Tag
using Hyperscript
using Hyperscript: render
using Test

@testset "HTM.jl" begin
    # Do we have 100% coverage?
    # Do we have examples in the documentation?

    @testset "Features" begin
        @testset "Spread props" begin
            props = Dict("class" => "fruit")
            @test htm"<div $(props)></div>" |> render == "<div class=\"fruit\"></div>"
        end

        @testset "Self-closing tags" begin
            @test htm"<div />" |> render == "<div></div>"
            @test htm"<circle />" |> render == "<circle />"
        end

        @testset "Multiple root elements (fragments)" begin
            @test htm"<div /><div />" == (htm"<div />", htm"<div />")
        end

        @testset "Boolean attributes" begin
            @test htm"<div draggable />" |> render == "<div draggable></div>"
            @test htm"<div draggable=$(true) />" |> render == "<div draggable></div>"
            @test htm"<div draggable=$(false) />" |> render == "<div></div>"
        end

        @testset "HTML's optional quotes" begin
            @test htm"<div class=fruit></div>" |> render == "<div class=\"fruit\"></div>"
        end

        @testset "Components" begin
            struct Fruit
                name::String
                emoji::Char
            end
            @test htm"$(Fruit(\"pineapple\", '🍍'))" == Fruit("pineapple", '🍍')
            Base.show(io::IO, m::MIME"text/html", 🍎::Fruit) = show(io, m, htm"$(🍎.name): <div class=fruit>$(🍎.emoji)</div>")
            Base.show(io::IO, ::MIME"text/plain", 🍎::Fruit) = show(io, MIME("text/html"), 🍎)
            @test_broken htm"<p>$(Fruit(\"pineapple\", '🍍'))</p>" |> render == "<p>pineapple: <div class=\"fruit\">🍍</div></p>"
        end

        @testset "Generic end-tags" begin
            @test htm"<div>🍍<//>" |> render == "<div>🍍</div>"
        end

        @testset "Support for HTML-style comments" begin
            @test_skip htm"<div><!-- comment --></div>" |> render == "<div><!-- comment --></div>"
        end

        @testset "Styles" begin
            styles = Dict("background" => "orange")
            @test_broken htm"<span style=$(styles)>pineapple</span>" |> render == "<span style=\"background: orange\">pineapple</span>"
        end

        @testset "Callbacks" begin
            @test_broken htm"<button onclick=$(() -> pineapples += 1)>🍍</button>" |> render == "<button onclick=\"pineapples += 1\">🍍</button>"
        end
    end

    @testset "Return types" begin
        @test htm"<div>🍍</div>" isa Hyperscript.Node
        @test htm"🍍" isa String
        @test htm"" === nothing
        @test htm"<div /><div />" isa Tuple
    end

    @testset "Whitespace" begin
        # TODO
        @test_broken htm"""
            <div class="warning">
                Warning!
            </div>
        """ == htm"""<div class="warning">
            Warning!
        </div>"""
    end

    @testset "Interpolations" begin
        @testset "As children" begin
            @test htm"<div>$(nothing)</div>" |> render == "<div></div>"
            @test htm"<div>$(missing)</div>" |> render == "<div>missing</div>"
            @test htm"<div>$(1)</div>" |> render == "<div>1</div>"
            @test htm"<div>$(1.0)</div>" |> render == "<div>1.0</div>"
            @test htm"<div>$(true)</div>" |> render == "<div>true</div>"
            @test htm"<div>$(:symbol)</div>" |> render == "<div>symbol</div>"
            @test htm"<div>$(\"string\")</div>" |> render == "<div>string</div>"
            @test htm"<div>$([1, 2, 3])</div>" |> render == "<div>123</div>"
            @test htm"<div>$((1, 2, 3))</div>" |> render == "<div>123</div>"
            @test htm"<div>$(\"fruit\" => \"pineapple\")</div>" |> render == "<div>&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;</div>"
            @test htm"<div>$(Dict(\"fruit\" => \"pineapple\"))</div>" |> render == "<div>Dict&#40;&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;&#41;</div>"
        end

        @testset "As props" begin
            @testset "As keys" begin
                @test_throws MethodError htm"<div $(nothing)=fruit></div>" |> render == "<div nothing=\"fruit\"></div>"
                @test_throws MethodError htm"<div $(missing)=fruit></div>" |> render == "<div missing=\"fruit\"></div>"
                @test_throws MethodError htm"<div $(1)=fruit></div>" |> render == "<div 1=\"fruit\"></div>"
                @test_throws MethodError htm"<div $(1.0)=fruit></div>" |> render == "<div 1.0=\"fruit\"></div>"
                @test_throws MethodError htm"<div $(true)=fruit></div>" |> render == "<div true></div>"
                @test_throws MethodError htm"<div $(:symbol)=fruit></div>" |> render == "<div symbol=\"fruit\"></div>"
                @test_throws MethodError htm"<div $(\"string\")=fruit></div>" |> render == "<div string=\"fruit\"></div>"
                @test_throws MethodError htm"<div $([1, 2, 3])=fruit></div>" |> render == "<div 123=\"fruit\"></div>"
                @test_throws MethodError htm"<div $((1, 2, 3))=fruit></div>" |> render == "<div 123=\"fruit\"></div>"
                @test_throws MethodError htm"<div $(\"fruit\" => \"pineapple\")=fruit></div>" |> render == "<div &#34;fruit&#34; =&#62; &#34;pineapple&#34;=\"fruit\"></div>"
                @test htm"<div $(Dict(\"fruit\" => \"pineapple\"))=fruit></div>" |> render == "<div fruit=\"pineapple\" =\"fruit\"></div>"
            end

            @testset "As values" begin
                @test htm"<div key=$(nothing)></div>" |> render == "<div></div>"
                @test_throws TypeError htm"<div key=$(missing)></div>" |> render == "<div key=\"missing\"></div>"
                @test htm"<div key=$(1)></div>" |> render == "<div key=\"1\"></div>"
                @test htm"<div key=$(1.0)></div>" |> render == "<div key=\"1.0\"></div>"
                @test htm"<div key=$(true)></div>" |> render == "<div key></div>"
                @test htm"<div key=$(:symbol)></div>" |> render == "<div key=\"symbol\"></div>"
                @test htm"<div key=$(\"string\")></div>" |> render == "<div key=\"string\"></div>"
                @test htm"<div key=$([1, 2, 3])></div>" |> render == "<div key=\"123\"></div>"
                @test htm"<div key=$((1, 2, 3))></div>" |> render == "<div key=\"123\"></div>"
                @test htm"<div key=$(\"fruit\" => \"pineapple\")></div>" |> render == "<div key=\"&#34;fruit&#34; =&#62; &#34;pineapple&#34;\"></div>"
                @test htm"<div key=$(Dict(\"fruit\" => \"pineapple\"))></div>" |> render == "<div key=\"Dict{String, Any}(&#34;fruit&#34; =&#62; &#34;pineapple&#34;)\"></div>"
            end
        end

        @testset "As tags" begin
            @testset "Matching end-tag" begin
                @testset "Complete tags" begin
                    @test htm"<$(nothing)></$(nothing)>" |> render == "<nothing></nothing>"
                    @test htm"<$(missing)></$(missing)>" |> render == "<missing></missing>"
                    @test htm"<$(1)></$(1)>" |> render == "<1></1>"
                    @test htm"<$(1.0)></$(1.0)>" |> render == "<1.0></1.0>"
                    @test_broken htm"<$(true)></$(true)>" |> render == "<true></true>"
                    @test htm"<$(:symbol)></$(:symbol)>" |> render == "<symbol></symbol>"
                    @test htm"<$(\"string\")></$(\"string\")>" |> render == "<string></string>"
                    @test htm"<$([1, 2, 3])></$([1, 2, 3])>" |> render == "<123></123>"
                    @test htm"<$((1, 2, 3))></$((1, 2, 3))>" |> render == "<123></123>"
                    @test htm"<$(\"fruit\" => \"pineapple\")><//>" |> render == "<&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;></&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;>"
                    @test htm"<$(Dict(\"fruit\" => \"pineapple\"))><//>" |> render == "<Dict&#123;String, Any&#125;&#40;&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;&#41;></Dict&#123;String, Any&#125;&#40;&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;&#41;>"
                end

                @testset "Partial tags" begin
                    @test htm"<h$(nothing)></h$(nothing)>" |> render == "<hnothing></hnothing>"
                    @test htm"<h$(missing)></h$(missing)>" |> render == "<hmissing></hmissing>"
                    @test htm"<h$(1)></h$(1)>" |> render == "<h1></h1>"
                    @test htm"<h$(1.0)></h$(1.0)>" |> render == "<h1.0></h1.0>"
                    @test_broken htm"<h$(true)></h$(true)>" |> render == "<htrue></htrue>"
                    @test htm"<h$(:symbol)></h$(:symbol)>" |> render == "<hsymbol></hsymbol>"
                    @test htm"<h$(\"string\")></h$(\"string\")>" |> render == "<hstring></hstring>"
                    @test htm"<h$([1, 2, 3])></h$([1, 2, 3])>" |> render == "<h123></h123>"
                    @test htm"<h$((1, 2, 3))></h$((1, 2, 3))>" |> render == "<h123></h123>"
                    @test htm"<h$(\"fruit\" => \"pineapple\")></h$(\"fruit\" => \"pineapple\")>" |> render == "<h&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;></h&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;>"
                    @test htm"<h$(Dict(\"fruit\" => \"pineapple\"))></h$(Dict(\"fruit\" => \"pineapple\"))>" |> render == "<hDict&#123;String, Any&#125;&#40;&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;&#41;></hDict&#123;String, Any&#125;&#40;&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;&#41;>"
                end
            end

            @testset "Universal end-tag" begin
                @testset "Complete tags" begin
                    @test htm"<$(nothing)><//>" |> render == "<nothing></nothing>"
                    @test htm"<$(missing)><//>" |> render == "<missing></missing>"
                    @test htm"<$(1)><//>" |> render == "<1></1>"
                    @test htm"<$(1.0)><//>" |> render == "<1.0></1.0>"
                    @test_broken htm"<$(true)><//>" |> render == "<true></true>"
                    @test htm"<$(:symbol)><//>" |> render == "<symbol></symbol>"
                    @test htm"<$(\"string\")><//>" |> render == "<string></string>"
                    @test htm"<$([1, 2, 3])><//>" |> render == "<123></123>"
                    @test htm"<$((1, 2, 3))><//>" |> render == "<123></123>"
                    @test htm"<$(\"fruit\" => \"pineapple\")><//>" |> render == "<&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;></&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;>"
                    @test htm"<$(Dict(\"fruit\" => \"pineapple\"))><//>" |> render == "<Dict&#123;String, Any&#125;&#40;&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;&#41;></Dict&#123;String, Any&#125;&#40;&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;&#41;>"
                end

                @testset "Partial tags" begin
                    @test htm"<h$(nothing)><//>" |> render == "<hnothing></hnothing>"
                    @test htm"<h$(missing)><//>" |> render == "<hmissing></hmissing>"
                    @test htm"<h$(1)><//>" |> render == "<h1></h1>"
                    @test htm"<h$(1.0)><//>" |> render == "<h1.0></h1.0>"
                    @test_broken htm"<h$(true)><//>" |> render == "<htrue></htrue>"
                    @test htm"<h$(:symbol)><//>" |> render == "<hsymbol></hsymbol>"
                    @test htm"<h$(\"string\")><//>" |> render == "<hstring></hstring>"
                    @test htm"<h$([1, 2, 3])><//>" |> render == "<h123></h123>"
                    @test htm"<h$((1, 2, 3))><//>" |> render == "<h123></h123>"
                    @test htm"<h$(\"fruit\" => \"pineapple\")><//>" |> render == "<h&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;></h&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;>"
                    @test htm"<h$(Dict(\"fruit\" => \"pineapple\"))><//>" |> render == "<hDict&#123;String, Any&#125;&#40;&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;&#41;></hDict&#123;String, Any&#125;&#40;&#34;fruit&#34; &#61;&#62; &#34;pineapple&#34;&#41;>"
                end
            end
        end
    end

    @testset "Escaped characters`" begin
        @test htm"<p>Look, Ma, $(\"<em>automatic escaping</em>\")!</p>" |> render == "<p>Look, Ma, &#60;em&#62;automatic escaping&#60;/em&#62;&#33;</p>"

        @testset "Escaped dollar signs`" begin
            @test htm"<div>\$notvar</div>" |> render == raw"<div>&#36;notvar</div>"
            @test htm"<div>\$(notvar)</div>" |> render == raw"<div>&#36;&#40;notvar&#41;</div>"

            @test htm"<\$notvar />" |> render == raw"<&#36;notvar></&#36;notvar>"
            @test htm"<div \$notvar />" |> render == raw"""<div &#36;notvar></div>"""

            @test htm"<\$(notvar) />" |> render == raw"<&#36;&#40;notvar&#41;></&#36;&#40;notvar&#41;>"
            @test htm"<div \$(notvar) />" |> render == raw"""<div &#36;&#40;notvar&#41;></div>"""

            @test htm"<div \$notvar=fruit />" |> render == raw"""<div &#36;notvar="fruit"></div>"""
            @test htm"<div class=\$notvar />" |> render == raw"""<div class="$notvar"></div>"""

            @test htm"<div \$(notvar)=fruit />" |> render == raw"""<div &#36;&#40;notvar&#41;="fruit"></div>"""
            @test htm"<div class=\$(notvar) />" |> render == raw"""<div class="$(notvar)"></div>"""

            @test htm"<div \$notvar=\"fruit\" />" |> render == raw"""<div &#36;notvar="fruit"></div>"""
            @test htm"<div class=\"\$notvar\" />" |> render == raw"""<div class="$notvar"></div>"""

            @test htm"<div \$(notvar)=\"fruit\" />" |> render == raw"""<div &#36;&#40;notvar&#41;="fruit"></div>"""
            @test htm"<div class=\"\$(notvar)\" />" |> render == raw"""<div class="$(notvar)"></div>"""
        end
    end

    @testset "create_element" begin
        @test create_element("div", (), ()) |> render == "<div></div>"
        @test create_element("div", (), "Hi!") |> render == "<div>Hi&#33;</div>"
        @test create_element("div", Dict("class" => "fruit")) |> render == "<div class=\"fruit\"></div>"
        @test create_element("div", Dict("class" => "fruit"), "Hi!") |> render == "<div class=\"fruit\">Hi&#33;</div>"
        @test create_element("div", Dict("class" => "fruit"), "Hi ", "there!") |> render == "<div class=\"fruit\">Hi there&#33;</div>"

        @test create_element("button", Dict("class" => "fruit", "disabled" => nothing)) |> render == "<button class=\"fruit\" disabled></button>"
        @test create_element("button", Dict("class" => "fruit", "disabled" => nothing), "Click me") |> render == "<button class=\"fruit\" disabled>Click me</button>"

        @test create_element("circle", Dict("fill" => "orange")) |> render == "<circle fill=\"orange\" />"
    end

    @testset "Tag (IR)" begin
        @test parsetag(IOBuffer("<div />")) == Tag("div", Dict())
        @test parsetag(IOBuffer("<div>Hi!</div>")) == Tag("div", Dict(), (), ["Hi!"])
        @test parsetag(IOBuffer("<div class=fruit />")) == Tag("div", Dict("class" => "fruit"))
        @test parsetag(IOBuffer("<div class=fruit>Hi!</div>")) == Tag("div", Dict("class" => "fruit"), (), ["Hi!"])
        @test parsetag(IOBuffer("<div class=fruit>Hi there!</div>")) == Tag("div", Dict("class" => "fruit"), (), ["Hi there!"])

        @test parsetag(IOBuffer("<button class=fruit disabled />")) == Tag("button", Dict("class" => "fruit", "disabled" => true))
        @test parsetag(IOBuffer("<button class=fruit disabled>Click me</button>")) == Tag("button", Dict("class" => "fruit", "disabled" => true), (), ["Click me"])

        @test parsetag(IOBuffer("<circle fill=orange />")) == Tag("circle", Dict("fill" => "orange"))

        @testset "Stress tests" begin
            quotes = ("", '"', '\'')
            separators = ("", ' ', '\n', '\t', "  ")

            @testset "Basic syntax" begin
                voiddiv = parsetag(IOBuffer("<div />"))
                litclass = parsetag(IOBuffer("<div class=fruit />"))
                offlitclass = parsetag(IOBuffer("<div class=fruit draggable />"))

                let c = "Hi there!"
                    nonvoiddiv = parsetag(IOBuffer("<div>$(c)</div>"))
                    fruitnonvoiddiv = parsetag(IOBuffer("<div class=fruit>$(c)</div>"))
                    draggablefruitnonvoiddiv = parsetag(IOBuffer("<div class=fruit draggable>$(c)</div>"))

                    @testset "Separator `$(s)`" for s in separators
                        @test parsetag(IOBuffer("<div$(s)/>")) == voiddiv

                        @test parsetag(IOBuffer("<div$(s)></div>")) == voiddiv

                        @test parsetag(IOBuffer("<div$(s)>$(c)</div>")) == nonvoiddiv

                        @testset "Quote `$(q)`" for q in quotes
                            @test parsetag(IOBuffer("<div class=$(q)fruit$(q)$(s)/>")) == litclass
                            @test parsetag(IOBuffer("<div class=$(q)fruit$(q) draggable$(s)/>")) == offlitclass

                            @test parsetag(IOBuffer("<div class=$(q)fruit$(q)$(s)></div>")) == litclass
                            @test parsetag(IOBuffer("<div class=$(q)fruit$(q) draggable$(s)></div>")) == offlitclass

                            @test parsetag(IOBuffer("<div class=$(q)fruit$(q)$(s)>$(c)</div>")) == fruitnonvoiddiv
                            @test parsetag(IOBuffer("<div class=$(q)fruit$(q) draggable$(s)>$(c)</div>")) == draggablefruitnonvoiddiv
                        end
                    end
                end
            end

            @testset "Dollar signs" begin
                @test parsetag(IOBuffer("<div>\$notvar</div>")) == parsetag(IOBuffer(raw"<div>$notvar</div>"))
                @test parsetag(IOBuffer("<div>\$(notvar)</div>")) == parsetag(IOBuffer(raw"<div>$(notvar)</div>"))

                @testset "Separator `$(s)`" for s in separators
                    @test parsetag(IOBuffer("<\$notvar$(s)/>")) == parsetag(IOBuffer(raw"<$notvar></$notvar>"))
                    @test parsetag(IOBuffer("<div \$notvar$(s)/>")) == parsetag(IOBuffer(raw"""<div $notvar></div>"""))

                    @test parsetag(IOBuffer("<\$(notvar)$(s)/>")) == parsetag(IOBuffer(raw"<$(notvar)></$(notvar)>"))
                    @test parsetag(IOBuffer("<div \$(notvar)$(s)/>")) == parsetag(IOBuffer(raw"""<div $(notvar)></div>"""))

                    @testset "Quote `$(q)`" for q in quotes
                        @test parsetag(IOBuffer("<div \$notvar=$(q)fruit$(q)$(s)/>")) == parsetag(IOBuffer(raw"""<div $notvar="fruit"></div>"""))
                        @test parsetag(IOBuffer("<div class=$(q)\$notvar$(q)$(s)/>")) == parsetag(IOBuffer(raw"""<div class="$notvar"></div>"""))

                        @test parsetag(IOBuffer("<div \$(notvar)=$(q)fruit$(q)$(s)/>")) == parsetag(IOBuffer(raw"""<div $(notvar)="fruit"></div>"""))
                        @test parsetag(IOBuffer("<div class=$(q)\$(notvar)$(q)$(s)/>")) == parsetag(IOBuffer(raw"""<div class="$(notvar)"></div>"""))
                    end
                end
            end
        end
    end
end
