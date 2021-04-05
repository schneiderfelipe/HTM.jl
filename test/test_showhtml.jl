@testset "Show HTML" begin
    @test repr("text/html", htm"<h1>Do I work?</h1>") == "<h1>Do I work?</h1>"
    let text = "Do I work?"
        @test repr("text/html", htm"<h1>$text</h1>") == "<h1>Do I work?</h1>"
    end
    @test repr("text/html", htm"""<h1>$(md"Do **I** workd?")</h1>""") == "<h1><div class=\"markdown\"><p>Do <strong>I</strong> workd?</p>\n</div></h1>"

    @test repr("text/html", htm"<html lang=pt-BR>My page</html>") == "<html lang=\"pt-BR\">My page</html>"

    # A complex example has appeared!
    @test repr("text/html", htm"""
        <section>
            <noscript><strong>Sorry, no JavaScript!</strong></noscript>

            <h1>Awesome title</h1>
            <p>A <strong>bold</strong> paragraph!</p>
            <img src=kitty.jpg />

            <hr />

            <div id=John class=person>
                A <em>nice</em> guy
            </div>
        </section>
        <img /><second />
    """) == "<section><noscript><strong>Sorry, no JavaScript!</strong></noscript><h1>Awesome title</h1><p>A <strong>bold</strong> paragraph!</p><img src=\"kitty.jpg\" /><hr /><div id=\"John\" class=\"person\"> A <em>nice</em> guy </div></section><img /><second />"

    @test repr("text/html", htm"<∫ dω=\"dx\" x₀=\"0\" x₁=\"∞\" note=\"hard math\">√(x²)</∫>") == "<∫ dω=\"dx\" x₀=\"0\" x₁=\"∞\" note=\"hard math\">√(x²)</∫>"

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
        Dict(:fnord => 23, :eris => 5),
        Dict("fnord" => 23, "eris" => 5),
    )
        io = IOBuffer()
        show(io, "text/plain", val)

        @test repr("text/html", htm"""<span>
            Our value: $val
        </span>""") == "<span> Our value: $(String(take!(io)))</span>"
    end

    # We treat strings differently
    let val = "Hello world!"
        @test repr("text/html", htm"""<span>
            Our value: $val
        </span>""") == "<span> Our value: $val</span>"
    end

    # A wild comment has appeared!
    @test repr("text/html", htm"""
        <div>
            <!-- I am a comment! -->
            I am not.
        </div>
    """) == "<div><!-- I am a comment! --> I am not. </div>"

    # Components!
    let f(; name="John", surname="Doe") = htm"""
        <div id="$name $surname" class=name>
            <h1 id=$surname>$surname,</h1>
            <h2 id=$name>$name</h2>
        </div>
    """
        @test repr("text/html", htm"<div id=\"manager\" class=person><f /></div>") == """<div id="manager" class="person"><div id="John Doe" class="name"><h1 id="Doe">Doe,</h1><h2 id="John">John</h2></div></div>"""
        @test repr("text/html", htm"<div id=\"actor\" class=person><f surname=Silva name=João /></div>") == """<div id="actor" class="person"><div id="João Silva" class="name"><h1 id="Silva">Silva,</h1><h2 id="João">João</h2></div></div>"""
    end
end