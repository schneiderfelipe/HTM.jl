@testset "No quotation marks" begin
    @test htm"<html lang=pt-BR></html>" == HyperscriptLiteral.Node{:html}(attrs=[:lang => "pt-BR"])

    @test htm"""
    <div id=John class=person>
        A <em>nice</em> guy
    </div>
    """ == HyperscriptLiteral.Node{:div}([
            " A ",
            HyperscriptLiteral.Node{:em}(["nice"]),
            " guy ",
        ],
        [:id => "John", :class => "person"],
    )

    let lang = "pt-BR"
        @test htm"<html lang=$lang></html>" == HyperscriptLiteral.Node{:html}(attrs=[:lang => lang])
    end

    let alt = "I have a lot of whitespace"
        @test htm"<img alt=$alt />" == HyperscriptLiteral.Node{:img}(attrs=[:alt => alt])
    end
end