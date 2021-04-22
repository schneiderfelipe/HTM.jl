@testset "Attributes" begin
    @test htm"""<canvas id="myCanvas" width="200" height="200" style="border: 1px solid;" />""" == HyperscriptLiteral.Node{:canvas}(attrs=[
        :id => "myCanvas",
        :width => "200",
        :height => "200",
        :style => "border: 1px solid;",
    ])

    @test htm"""<canvas id=myCanvas width=200 height=200 style="border: 1px solid;" />""" == HyperscriptLiteral.Node{:canvas}(attrs=[
        :id => "myCanvas",
        :width => 200,
        :height => 200,
        :style => "border: 1px solid;",
    ])

    let class="menu"
        @test htm"""<ul class=$class><li>Home</li></ul>""" == HyperscriptLiteral.Node{:ul}([HyperscriptLiteral.Node{:li}(["Home"])], [:class => class])
        @test htm"""<ul class="$class"><li>Home</li></ul>""" == HyperscriptLiteral.Node{:ul}([HyperscriptLiteral.Node{:li}(["Home"])], [:class => class])
    end

    let width=300
        @test htm"""<div width=$width>Lorem ipsum</div>""" == HyperscriptLiteral.Node{:div}(["Lorem ipsum"], [:width => width])
        @test htm"""<div width="$width">Lorem ipsum</div>""" == HyperscriptLiteral.Node{:div}(["Lorem ipsum"], [:width => "$width"])
    end

    # Wild literals have appeared!
    @test htm"<span attr=false>false</span>" == HyperscriptLiteral.Node{:span}(["false"], [:attr => false])
    @test htm"<span attr=1>1</span>" == HyperscriptLiteral.Node{:span}(["1"], [:attr => 1])
    @test htm"<span attr=2.0>2.0</span>" == HyperscriptLiteral.Node{:span}(["2.0"], [:attr => 2.0])
    @test htm"<span attr=three>three</span>" == HyperscriptLiteral.Node{:span}(["three"], [:attr => "three"])
    @test htm"<span attr=\"three\">\"three\"</span>" == HyperscriptLiteral.Node{:span}(["\"three\""], [:attr => "three"])

    for value in (false, 1, 2.0, "three")
        h = htm"<span attr=$value>$value</span>"
        @test h == HyperscriptLiteral.Node{:span}([value], [:attr => value])
        @test repr("text/html", h) == "<span attr=\"$value\">$value</span>"
    end

    let value = "\"three\""
        h = htm"<span attr=$value>$value</span>"
        @test h == HyperscriptLiteral.Node{:span}([value], [:attr => value])
        @test repr("text/html", h) == "<span attr=\"&#34;three&#34;\">&#34;three&#34;</span>"
    end

    # Some other exotic attributes
    for value in (4//1, 5im)
        h = htm"<span attr=$value>$value</span>"
        @test h == HyperscriptLiteral.Node{:span}([value], [:attr => value])
        @test repr("text/html", h) == "<span attr=\"$value\">$value</span>"
    end

    # A wild component has appeared!
    let f(; a=1, b=1) = a / (b + 1)
        @test htm"<f />" == HyperscriptLiteral.Node{:dummy}([f()])
        @test htm"<f/>" == HyperscriptLiteral.Node{:dummy}([f()])

        @test htm"<f a=2 />" == HyperscriptLiteral.Node{:dummy}([f(a=2)])
        @test htm"<f b=3 />" == HyperscriptLiteral.Node{:dummy}([f(b=3)])
        @test htm"<f a=2 b=3 />" == HyperscriptLiteral.Node{:dummy}([f(a=2, b=3)])
        @test htm"<f b=3 a=2 />" == HyperscriptLiteral.Node{:dummy}([f(a=2, b=3)])
        @test htm"<f b=2 a=3 />" == HyperscriptLiteral.Node{:dummy}([f(a=3, b=2)])

        let a = 3, b = 4
            @test htm"<f b=$b a=$a />" == HyperscriptLiteral.Node{:dummy}([f(a=a, b=b)])
        end
    end

    # TODO: test a space between the value and the "=" in an attribute (e.g. class= "fnord")
end