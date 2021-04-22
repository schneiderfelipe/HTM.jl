@testset "Object interpolation" begin
    # Sanity checks
    @test htm"<h1> $ </h1>" == HyperscriptLiteral.Node{:h1}([" \$ "])
    @test htm"<h1>$ </h1>" == HyperscriptLiteral.Node{:h1}(["\$ "])
    @test htm"<h1> $</h1>" == HyperscriptLiteral.Node{:h1}([" \$"])
    @test htm"<h1>$</h1>" == HyperscriptLiteral.Node{:h1}(["\$"])

    @test htm"<h1>\$name</h1>" == HyperscriptLiteral.Node{:h1}(["\$name"])
    let name = "John Doe"
        @test htm"<h1>$name</h1>" == HyperscriptLiteral.Node{:h1}([name])
    end

    # Wild math expressions have appeared!
    @test htm"<span>$(1 + 2)</span>" == HyperscriptLiteral.Node{:span}([3])
    @test htm"$(1 + 2)" == HyperscriptLiteral.Node{:dummy}([3])
    @test htm"<span>$(√4)</span>" == HyperscriptLiteral.Node{:span}([2.0])
    @test htm"$(√4)" == HyperscriptLiteral.Node{:dummy}([2.0])

    # Wild Markdown snippets have appeared!
    let markdown = md"*Hello* **world** from [Markdown](https://docs.julialang.org/en/v1/stdlib/Markdown/)"
        @test htm"<section>$markdown</section>" == HyperscriptLiteral.Node{:section}([markdown])
        @test htm"<section>$markdown $markdown</section>" == HyperscriptLiteral.Node{:section}([markdown, markdown])
        @test htm"""
            <section>
                <h1>$(md"My awesome title!")</h1>
                $markdown $markdown
            </section>
        """ == HyperscriptLiteral.Node{:section}([HyperscriptLiteral.Node{:h1}([md"My awesome title!"]), markdown, markdown])
    end

    # Wild HyperscriptLiteral snippets have appeared!
    let title = htm"<h1>Hello world!</h1>"
        @test htm"<section>$title</section>" == HyperscriptLiteral.Node{:section}([HyperscriptLiteral.Node{:h1}(["Hello world!"])])
    end
    let friend = "Cebolinha", title = htm"<h1>Hello $friend</h1>"
        @test htm"<section>$title</section>" == HyperscriptLiteral.Node{:section}([HyperscriptLiteral.Node{:h1}(["Hello ", friend])])
    end

    # Native HTML
    let title = html"<h1>Hello world!</h1>"
        @test htm"<section>$title</section>" == HyperscriptLiteral.Node{:section}([title])
    end

    # Wild containers have appeared!
    @test htm"""<span>
        $(1 + 2 + 3),
        $([1, 2, 3]),
        $((1, 2, 3)),
        $(Dict(1 => 2, 2 => 3))
    </span>""" == HyperscriptLiteral.Node{:span}([6, ", ", [1, 2, 3], ", ", (1, 2, 3), ", ", Dict(2 => 3,1 => 2)])

    # I heard you like interpolations so we put an interpolation in your
    # interpolation! Unfortunately, this does not work as expected, but it
    # should not fail. Plus, if it makes you feel better, it is consistent
    # with how @md_str works, for instance.
    @test htm"""
        <section>
            <h1>$(md"I have a $(\"variable inside\")")</h1>
        </section>
    """ == HyperscriptLiteral.Node{:section}([HyperscriptLiteral.Node{:h1}(["\$(md\"I have a variable inside\")"])])
end