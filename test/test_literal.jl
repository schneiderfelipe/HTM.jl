@testset "Literals" begin
    # Some simple tests for single tags in different forms.
    @test htm"<hr />" == Node(:hr, [], [])
    @test htm"<meta charset=\"UTF-8\" />" == Node(:meta, [:charset => "UTF-8"], [])
    @test htm"<a></a>" == Node(:a, [], [])
    @test htm"<title>JSX</title>" == Node(:title, [], ["JSX"])
    @test htm"<html lang=\"pt-BR\"></html>" == Node(:html, [:lang => "pt-BR"], [])
    @test htm"<a href=\"kitty.jpg\">A kitty!</a>" == Node(:a, [:href => "kitty.jpg"], ["A kitty!"])
    @test htm"<noscript><strong>Sorry, no JavaScript!</strong></noscript>" == Node(:noscript, [], [Node(:strong, [], ["Sorry, no JavaScript!"])])

    # Observe that the returned value is always a Node
    @test htm"Ceci nest pas une string" == Node(:root, [], ["Ceci nest pas une string"])

    # A wild lonely tag has appeared!
    @test htm"""
        <section>
            <h1>Awesome title</h1>
            <p>A <strong>bold</strong> paragraph!</p>
            <img src="kitty.jpg" />
        </section>
    """ == Node(:section, [], [
        Node(:h1, [], ["Awesome title"]),
        Node(:p, [], [
            "A ",
            Node(:strong, [], ["bold"]),
            " paragraph!",
        ]),
        Node(:img, [:src => "kitty.jpg"], []),
    ])

    # A wild attribute has appeared!
    @test htm"""
        <person name="John" surname="Doe">
            A <em>nice</em> guy
        </person>
    """ == Node(:person, [:name => "John", :surname => "Doe"], [
        " A ",
        Node(:em, [], ["nice"]),
        " guy ",
    ])

    # A wild root node has appeared!
    @test htm"<first /><second />" == Node(:root, [], [Node(:first, [], []), Node(:second, [], [])])

    # A wild comment has appeared!
    @test htm"""
        <div>
            <!-- I am a comment! -->
            I am not.
        </div>
    """ == Node(:div, [], [Node(:comment, [], [" I am a comment! "]), " I am not. "])
end