using JSX
using Test

using JSX: Node

@testset "JSX.jl" begin
    # Who doesn't love hand-made, artisanal tests?

    # Some simple tests for single tags in different forms.
    @test htm"<hr />" == Node("hr", [], [])
    @test htm"<meta charset=\"UTF-8\" />" == Node("meta", ["charset" => "UTF-8"], [])
    @test htm"<a></a>" == Node("a", [], [])
    @test htm"<title>JSX</title>" == Node("title", [], ["JSX"])
    @test htm"<html lang=\"pt-BR\"></html>" == Node("html", ["lang" => "pt-BR"], [])
    @test htm"<a href=\"kitty.jpg\">A kitty!</a>" == Node("a", ["href" => "kitty.jpg"], ["A kitty!"])
    @test htm"<noscript><strong>Sorry, no JavaScript!</strong></noscript>" == Node("noscript", [], [Node("strong", [], ["Sorry, no JavaScript!"])])

    # A wild lonely tag has appeared!
    @test htm"""
        <section>
            <h1>Awesome title</h1>
            <p>A <strong>bold</strong> paragraph!</p>
            <img src="kitty.jpg" />
        </section>
    """ == Node("section", [], [
        Node("h1", [], ["Awesome title"]),
        Node("p", [], [
            "A ",
            Node("strong", [], ["bold"]),
            " paragraph!",
        ]),
        Node("img", ["src" => "kitty.jpg"], []),
    ])

    # A wild attribute has appeared!
    @test htm"""
        <person name="John" surname="Doe">
            A <em>nice</em> guy
        </person>
    """ == Node("person", ["name" => "John", "surname" => "Doe"], [
        " A ",
        Node("em", [], ["nice"]),
        " guy ",
    ])

    let name = "Brazil", continent = "South America"
        # TODO: make this more clever! htm"<country name=\"Brazil\", continent=\"South America\">" should call this function!
        @test htm"""
            <country>
                <name>$name</name>
                <continent>$continent</continent>
            </country>
        """ == Node("country", [], [Node("name", [], ["Brazil"]), Node("continent", [], ["South America"])])

        @test htm"""
            <country name="$name" continent="$continent" />
        """ == Node("country", ["name" => "Brazil", "continent" => "South America"], [])
    end

    let tag = "a", attr = "href", url = "https://julialang.org/", text = "The Julia Programming Language"
        # Great Scott!
        @test htm"<$tag $attr=\"$url\">$text</$tag>" == Node(tag, [attr => url], [text])
    end

    # TODO: test unicode in tags, attributes, content, etc.: we need to check if escape_string is necessary
end
