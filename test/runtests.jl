using JSX
using Test

using JSX: Node

@testset "JSX.jl" begin
    # Who doesn't love hand-made, artisanal tests?

    # Some simple tests for single tags in different forms.
    @test htm"<hr />" == Node(:hr, NamedTuple(), [])
    @test htm"<meta charset=\"UTF-8\" />" == Node(:meta, (charset="UTF-8",), [])
    @test htm"<a></a>" == Node(:a, NamedTuple(), [])
    @test htm"<title>JSX</title>" == Node(:title, NamedTuple(), ["JSX"])
    @test htm"<html lang=\"pt-BR\"></html>" == Node(:html, (lang="pt-BR",), [])
    @test htm"<a href=\"kitty.jpg\">A kitty!</a>" == Node(:a, (href="kitty.jpg",), ["A kitty!"])
    @test htm"<noscript><strong>Sorry, no JavaScript!</strong></noscript>" == Node(:noscript, NamedTuple(), [Node(:strong, NamedTuple(), ["Sorry, no JavaScript!"])])

    # A wild lonely tag has appeared!
    @test htm"""
        <section>
            <h1>Awesome title</h1>
            <p>A <strong>bold</strong> paragraph!</p>
            <img src="kitty.jpg" />
        </section>
    """ == Node(:section, NamedTuple(), [
        Node(:h1, NamedTuple(), ["Awesome title"]),
        Node(:p, NamedTuple(), [
            "A ",
            Node(:strong, NamedTuple(), ["bold"]),
            " paragraph!",
        ]),
        Node(:img, (src="kitty.jpg",), []),
    ])

    # A wild attribute has appeared!
    @test htm"""
        <person name="John" surname="Doe">
            A <em>nice</em> guy
        </person>
    """ == Node(:person, (name="John", surname="Doe"), [
        " A ",
        Node(:em, NamedTuple(), ["nice"]),
        " guy ",
    ])

    # TODO: make this more clever! htm"<country name=\"Brazil\", continent=\"South America\">" should call this function!
    country(name, continent) = htm"""
        <country>
            <name>$name</name>
            <continent>$continent</continent>
        </country>
    """
    @test country("Brazil", "South America") == Node(:country, NamedTuple(), [Node(:name, NamedTuple(), ["Brazil"]), Node(:continent, NamedTuple(), ["South America"])])
end
