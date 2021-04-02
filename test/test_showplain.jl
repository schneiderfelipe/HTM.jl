@testset "Show plain text" begin
    @test repr("text/plain", htm"<h1>Do I work?</h1>") == "<h1>Do I work?</h1>"
    let text = "Do I work?"
        @test repr("text/plain", htm"<h1>$text</h1>") == "<h1>Do I work?</h1>"
    end
    @test repr("text/plain", htm"""<h1>$(md"Do **I** workd?")</h1>""") == "<h1>  Do I workd?</h1>"

    @test repr("text/plain", htm"<plain lang=pt-BR>My plain page</plain>") == "<plain lang=\"pt-BR\">My plain page</plain>"

    # A complex example has appeared!
    @test repr("text/plain", htm"""
        <section>
            <noscript><strong>Sorry, no JavaScript!</strong></noscript>

            <h1>Awesome title</h1>
            <p>A <strong>bold</strong> paragraph!</p>
            <img src="kitty.jpg" />

            <hr />

            <person name="John" surname="Doe">
                A <em>nice</em> guy
            </person>
        </section>
        <first /><second />
    """) == "<section><noscript><strong>Sorry, no JavaScript!</strong></noscript><h1>Awesome title</h1><p>A <strong>bold</strong> paragraph!</p><img src=\"kitty.jpg\" /><hr /><person name=\"John\" surname=\"Doe\"> A <em>nice</em> guy </person></section><first /><second />"

    @test repr("text/plain", htm"<∫ dω=\"dx\" x₀=\"0\" x₁=\"∞\" note=\"hard math\">√(x²)</∫>") == "<∫ dω=\"dx\" x₀=\"0\" x₁=\"∞\" note=\"hard math\">√(x²)</∫>"

    # Wild types have appeared!
    for val in (
        '#',
        23,
        5.0,
        [1, 2, 3],
        [1.0, 2.0, 3.0],
        (1, 2, 3),
        ("Hi", 5, 23.0),
        Dict(1 => 2, 2 => 3),
        Dict("fnord" => 23, "eris" => 5),
    )
        io = IOBuffer()
        show(io, "text/plain", val)

        @test repr("text/plain", htm"""<span>
            Our value: $val
        </span>""") == "<span> Our value: $(String(take!(io)))</span>"
    end

    # We treat strings differently
    let val = "Hello world!"
        @test repr("text/plain", htm"""<span>
            Our value: $val
        </span>""") == "<span> Our value: $val</span>"
    end
end