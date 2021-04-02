@testset "String interpolation" begin
    let name = "Brazil", continent = "South America"
        @test htm"""
            <country>
                <name>$name</name>
                <continent>$continent</continent>
            </country>
        """ == Node(:country, [], [Node(:name, [], ["Brazil"]), Node(:continent, [], ["South America"])])

        @test htm"""
            <country name="$name" continent="$continent" />
        """ == Node(:country, [:name => "Brazil", :continent => "South America"], [])
    end

    let tag = "a", attr = "href", url = "https://julialang.org/", text = "The Julia Programming Language"
        # Great Scott!
        @test htm"<$tag $attr=\"$url\">$text</$tag>" == Node(Symbol(tag), [Symbol(attr) => url], [text])
    end
end