@testset "Literals" begin
    # Some simple tests for single tags in different forms
    @test htm"<hr />" == JSX.Node(:hr)
    @test htm"<hr/>" == JSX.Node(:hr)
    @test htm"<meta charset=\"UTF-8\" />" == JSX.Node{:meta}(attrs=[:charset => "UTF-8"])
    @test htm"<a></a>" == JSX.Node(:a)
    @test htm"<title>JSX</title>" == JSX.Node{:title}(["JSX"])
    @test htm"<html lang=\"pt-BR\"></html>" == JSX.Node{:html}(attrs=[:lang => "pt-BR"])
    @test htm"<a href=\"kitty.jpg\">A kitty!</a>" == JSX.Node{:a}(
        ["A kitty!"],
        [:href => "kitty.jpg"],
    )
    @test htm"<noscript><strong>Sorry, no JavaScript!</strong></noscript>" == JSX.Node{:noscript}([JSX.Node{:strong}(["Sorry, no JavaScript!"])])

    @test htm"Ceci nest pas une string" == JSX.Node{:dummy}(["Ceci nest pas une string"])

    # A wild lonely tag has appeared!
    @test htm"""
        <section>
            <h1>Awesome title</h1>
            <p>A <strong>bold</strong> paragraph!</p>
            <img src="kitty.jpg" />
        </section>
    """ == JSX.Node{:section}([
        JSX.Node{:h1}(["Awesome title"]),
        JSX.Node{:p}([
            "A ",
            JSX.Node{:strong}(["bold"]),
            " paragraph!",
        ]),
        JSX.Node{:img}(attrs=[:src => "kitty.jpg"]),
    ])

    # A wild attribute has appeared!
    @test htm"""
    <div id="John" class="person">
        A <em>nice</em> guy
    </div>
    """ == JSX.Node{:div}([
            " A ",
            JSX.Node{:em}(["nice"]),
            " guy ",
        ],
        [:id => "John", :class => "person"],
    )

    # A wild root node has appeared!
    @test htm"<img /><second />" == JSX.Node{:dummy}([JSX.Node(:img), JSX.Node(:second)])

    # A wild comment has appeared!
    @test htm"""
        <div>
            <!-- I am a comment! -->
            I am not.
        </div>
    """ == JSX.Node{:div}([JSX.Node{:comment}([" I am a comment! "]), " I am not. "])
end