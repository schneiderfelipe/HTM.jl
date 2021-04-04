@testset "String interpolation" begin
    let name = "Brazil", continent = "south-america"
        @test htm"""
            <div>
                <span>$name</span>
                <span>$continent</span>
            </div>
        """ == JSX.Node{:div}([JSX.Node{:span}([JSX.Node{:text}(["Brazil"])]), JSX.Node{:span}([JSX.Node{:text}(["south-america"])])])

        # Using quotation marks
        @test htm"""
            <div id="$name" class="$continent" />
        """ == JSX.Node{:div}(attrs=["id" => "Brazil", "class" => "south-america"])
    end

    let imgtag = "img", imgattr = "src", imgurl = "https://julialang.org/assets/infra/logo.svg", alt = "The Julia Programming Language"
        img = htm"<$imgtag $imgattr=$imgurl alt=$alt />"
        @test img == JSX.Node(imgtag, attrs=[imgattr => imgurl, "alt" => alt])

        let atag = "a", aattr = "href", aurl = "https://julialang.org/", text = "The Julia Programming Language"
            # Great Scott!
            @test htm"<$atag $aattr=\"$aurl\">$text</$atag>" == JSX.Node(
                atag,
                [JSX.Node{:text}([text])],
                [aattr => aurl],
            )
            @test htm"<$atag $aattr=\"$aurl\">$text $img</$atag>" == JSX.Node(
                atag, [JSX.Node{:text}([text, img])],
                [aattr => aurl],
            )
        end
    end
end