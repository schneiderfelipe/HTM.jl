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
            <img src="kitty.jpg" />

            <hr />

            <person name="John" surname="Doe">
                A <em>nice</em> guy
            </person>
        </section>
        <first /><second />
    """) == "<section><noscript><strong>Sorry, no JavaScript!</strong></noscript><h1>Awesome title</h1><p>A <strong>bold</strong> paragraph!</p><img src=\"kitty.jpg\" /><hr /><person name=\"John\" surname=\"Doe\"> A <em>nice</em> guy </person></section><first /><second />"

    @test repr("text/html", htm"<∫ dω=\"dx\" x₀=\"0\" x₁=\"∞\" comment=\"hard math\">√(x²)</∫>") == "<∫ dω=\"dx\" x₀=\"0\" x₁=\"∞\" comment=\"hard math\">√(x²)</∫>"
end