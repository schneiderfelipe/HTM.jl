@testset "No quotation marks" begin
    @test htm"<html lang=pt-BR></html>" == JSX.Node(:html, [:lang => "pt-BR"], [])

    @test htm"""
    <div id=John class=person>
        A <em>nice</em> guy
    </div>
    """ == JSX.Node(:div, [:id => "John", :class => "person"], [
        " A ",
        JSX.Node(:em, [], ["nice"]),
        " guy ",
    ])

    let lang = "pt-BR"
        @test htm"<html lang=$lang></html>" == JSX.Node(:html, [:lang => lang], [])
    end

    let alt = "I have a lot of whitespace"
        @test htm"<img alt=$alt />" == JSX.Node(:img, [:alt => alt], [])
    end
end