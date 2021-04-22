@testset "String interpolation" begin
    let lang = "pt-BR"
        @test htm"<html lang=$lang></html>" == HyperscriptLiteral.Node{:html}(attrs=[:lang => lang])
    end

    let name = "Brazil", continent = "south-america"
        @test htm"""
            <div>
                <span>$name</span>
                <span>$continent</span>
            </div>
        """ == HyperscriptLiteral.Node{:div}([HyperscriptLiteral.Node{:span}(["Brazil"]), HyperscriptLiteral.Node{:span}(["south-america"])])

        # Using quotation marks
        @test htm"""
            <div id="$name" class="$continent" />
        """ == HyperscriptLiteral.Node{:div}(attrs=[:id => "Brazil", :class => "south-america"])
    end

    let imgtag = "img", imgattr = "src", imgurl = "https://julialang.org/assets/infra/logo.svg", alt = "The Julia Programming Language"
        img = htm"<$imgtag $imgattr=$imgurl alt=$alt />"
        @test img == HyperscriptLiteral.Node(imgtag, attrs=[imgattr => imgurl, :alt => alt])

        let atag = "a", aattr = "href", aurl = "https://julialang.org/", text = "The Julia Programming Language"
            # Great Scott!
            @test htm"<$atag $aattr=\"$aurl\">$text</$atag>" == HyperscriptLiteral.Node(
                atag,
                [text],
                [aattr => aurl],
            )
            @test htm"<$atag $aattr=\"$aurl\">$text $img</$atag>" == HyperscriptLiteral.Node(
                atag, [text, img],
                [aattr => aurl],
            )
        end
    end
end