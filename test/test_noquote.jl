@testset "No quotation marks" begin
    @test htm"<html lang=pt-BR></html>" == JSX.Node{:html}(attrs=["lang" => "pt-BR"])

    @test htm"""
    <div id=John class=person>
        A <em>nice</em> guy
    </div>
    """ == JSX.Node{:div}([
            " A ",
            JSX.Node{:em}(["nice"]),
            " guy ",
        ],
        ["id" => "John", "class" => "person"],
    )

    let lang = "pt-BR"
        @test htm"<html lang=$lang></html>" == JSX.Node{:html}(attrs=["lang" => lang])
    end

    let alt = "I have a lot of whitespace"
        @test htm"<img alt=$alt />" == JSX.Node{:img}(attrs=["alt" => alt])
    end
end