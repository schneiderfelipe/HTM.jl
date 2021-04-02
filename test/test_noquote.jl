@testset "No quotation marks" begin
    @test htm"<html lang=pt-BR></html>" == Node("html", ["lang" => "pt-BR"], [])

    @test htm"""
        <person name=John surname=Doe>
            A <em>nice</em> guy
        </person>
    """ == Node("person", ["name" => "John", "surname" => "Doe"], [
        " A ",
        Node("em", [], ["nice"]),
        " guy ",
    ])
end