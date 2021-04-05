@testset "Attributes" begin
    @test htm"""<canvas id="myCanvas" width="200" height="200" style="border: 1px solid;" />""" == JSX.Node{:canvas}(attrs=[
        :id => "myCanvas",
        :width => "200",
        :height => "200",
        :style => "border: 1px solid;",
    ])

    @test htm"""<canvas id=myCanvas width=200 height=200 style="border: 1px solid;" />""" == JSX.Node{:canvas}(attrs=[
        :id => "myCanvas",
        :width => 200,
        :height => 200,
        :style => "border: 1px solid;",
    ])

    # TODO: test interpolation with and without quotation marks

    # A wild component has appeared!
    let f(; a=1, b=1) = a / (b + 1)
        @test htm"<f />" == JSX.Node{:dummy}([f()])
        @test htm"<f/>" == JSX.Node{:dummy}([f()])

        @test htm"<f a=2 />" == JSX.Node{:dummy}([f(a=2)])
        @test htm"<f b=3 />" == JSX.Node{:dummy}([f(b=3)])
        @test htm"<f a=2 b=3 />" == JSX.Node{:dummy}([f(a=2, b=3)])
        @test htm"<f b=3 a=2 />" == JSX.Node{:dummy}([f(a=2, b=3)])
        @test htm"<f b=2 a=3 />" == JSX.Node{:dummy}([f(a=3, b=2)])

        let a = 3, b = 4
            @test htm"<f b=$b a=$a />" == JSX.Node{:dummy}([f(a=a, b=b)])
        end
    end
end