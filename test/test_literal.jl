@testset "Literals" begin
    # Some simple tests for single tags in different forms
    @test htm"<hr />" == HyperscriptLiteral.Node(:hr)
    @test htm"<hr/>" == HyperscriptLiteral.Node(:hr)
    @test htm"<meta charset=\"UTF-8\" />" == HyperscriptLiteral.Node{:meta}(attrs=[:charset => "UTF-8"])
    @test htm"<a></a>" == HyperscriptLiteral.Node(:a)
    @test htm"<title>HyperscriptLiteral</title>" == HyperscriptLiteral.Node{:title}(["HyperscriptLiteral"])
    @test htm"<html lang=\"pt-BR\"></html>" == HyperscriptLiteral.Node{:html}(attrs=[:lang => "pt-BR"])
    @test htm"<a href=\"kitty.jpg\">A kitty!</a>" == HyperscriptLiteral.Node{:a}(
        ["A kitty!"],
        [:href => "kitty.jpg"],
    )
    @test htm"<noscript><strong>Sorry, no JavaScript!</strong></noscript>" == HyperscriptLiteral.Node{:noscript}([HyperscriptLiteral.Node{:strong}(["Sorry, no JavaScript!"])])

    @test htm"Ceci nest pas une string" == HyperscriptLiteral.Node{:dummy}(["Ceci nest pas une string"])

    # A wild lonely tag has appeared!
    @test htm"""
        <section>
            <h1>Awesome title</h1>
            <p>A <strong>bold</strong> paragraph!</p>
            <img src="kitty.jpg" />
        </section>
    """ == HyperscriptLiteral.Node{:section}([
        HyperscriptLiteral.Node{:h1}(["Awesome title"]),
        HyperscriptLiteral.Node{:p}([
            "A ",
            HyperscriptLiteral.Node{:strong}(["bold"]),
            " paragraph!",
        ]),
        HyperscriptLiteral.Node{:img}(attrs=[:src => "kitty.jpg"]),
    ])

    # A wild attribute has appeared!
    @test htm"""
    <div id="John" class="person">
        A <em>nice</em> guy
    </div>
    """ == HyperscriptLiteral.Node{:div}([
            " A ",
            HyperscriptLiteral.Node{:em}(["nice"]),
            " guy ",
        ],
        [:id => "John", :class => "person"],
    )

    # A wild root node has appeared!
    @test htm"<img /><second />" == HyperscriptLiteral.Node{:dummy}([HyperscriptLiteral.Node(:img), HyperscriptLiteral.Node(:second)])

    # A wild comment has appeared!
    @test htm"""
        <div>
            <!-- I am a comment! -->
            I am not.
        </div>
    """ == HyperscriptLiteral.Node{:div}([HyperscriptLiteral.Node{:comment}([" I am a comment! "]), " I am not. "])
end