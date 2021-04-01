using JSX
using Test

using JSX: Node

@testset "JSX.jl" begin
    # Who doesn't love hand-made, artisanal tests?

    # Some simple tests for single tags in different forms.
    @test htm"<hr />" == Node(:hr, Dict(), [])
    @test htm"<meta charset=\"UTF-8\" />" == Node(:meta, Dict(:charset => "UTF-8"), [])
    @test htm"<a></a>" == Node(:a, Dict(), [])
    @test htm"<title>JSX</title>" == Node(:title, Dict(), ["JSX"])
    @test htm"<html lang=\"pt-BR\"></html>" == Node(:html, Dict(:lang => "pt-BR"), [])
    @test htm"<a href=\"kitty.jpg\">A kitty!</a>" == Node(:a, Dict(:href => "kitty.jpg"), ["A kitty!"])
    @test htm"<noscript><strong>Sorry, no JavaScript!</strong></noscript>" == Node(:noscript, Dict(), [Node(:strong, Dict(), ["Sorry, no JavaScript!"])])

    # A wild lonely tag has appeared!
    @test htm"""
        <section>
            <h1>Awesome title</h1>
            <p>A <strong>bold</strong> paragraph!</p>
            <img src="kitty.jpg" />
        </section>
    """ == Node(:section, Dict(), [
        Node(:h1, Dict(), ["Awesome title"]),
        Node(:p, Dict(), [
            "A ",
            Node(:strong, Dict(), ["bold"]),
            " paragraph!",
        ]),
        Node(:img, Dict(:src => "kitty.jpg"), []),
    ])

    # A wild attribute has appeared!
    @test htm"""
        <person name="John" surname="Doe">
            A <em>nice</em> guy
        </person>
    """ == Node(:person, Dict(:name => "John", :surname => "Doe"), [
        " A ",
        Node(:em, Dict(), ["nice"]),
        " guy ",
    ])

    # TODO: make this more clever! htm"<country name=\"Brazil\", continent=\"South America\">" should call this function!
    country(name, continent) = htm"""
        <country>
            <name>$name</name>
            <continent>$continent</continent>
        </country>
    """
    @test country("Brazil", "South America") == Node(:country, Dict(), [Node(:name, Dict(), ["Brazil"]), Node(:continent, Dict(), ["South America"])])
end
