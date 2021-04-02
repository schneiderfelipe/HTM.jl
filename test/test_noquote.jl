@testset "No quotation marks" begin
    @test htm"<html lang=pt-BR></html>" == Node(:html, [:lang => "pt-BR"], [])

    @test htm"""
        <person name=John surname=Doe>
            A <em>nice</em> guy
        </person>
    """ == Node(:person, [:name => "John", :surname => "Doe"], [
        " A ",
        Node(:em, [], ["nice"]),
        " guy ",
    ])

    let lang = "pt-BR"
        @test htm"<html lang=$lang></html>" == Node(:html, [:lang => lang], [])
    end

    let alt = "I have a lot of whitespace"
        @test htm"<img alt=$alt />" == Node(:img, [:alt => alt], [])
    end
end