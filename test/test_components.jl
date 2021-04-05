@testset "Components" begin
    # A wild component has appeared!
    let f(; who="world!") = "Hello $who"
        @test htm"<f />" == JSX.Node{:dummy}([f()])
        @test htm"<f/>" == JSX.Node{:dummy}([f()])

        @test htm"<f who=dear />" == JSX.Node{:dummy}([f(who="dear")])
        @test htm"<f who=\"honey\" />" == JSX.Node{:dummy}([f(who="honey")])

        let who = "planet"
            @test htm"<f who=$who />" == JSX.Node{:dummy}([f(who=who)])
            @test htm"<f who=\"$who\" />" == JSX.Node{:dummy}([f(who=who)])
        end
    end

    let f(; name="John", surname="Doe") = "$name $surname"
        @test htm"<f />" == JSX.Node{:dummy}([f()])
        @test htm"<f name=Sarah />" == JSX.Node{:dummy}([f(name="Sarah")])
        @test htm"<f surname=Silva />" == JSX.Node{:dummy}([f(surname="Silva")])
        @test htm"<f name=João surname=Silva />" == JSX.Node{:dummy}([f(name="João", surname="Silva")])
        @test htm"<f name=João surname=Silva/>" == JSX.Node{:dummy}([f(name="João", surname="Silva")])
        @test htm"<f surname=Silva name=João />" == JSX.Node{:dummy}([f(name="João", surname="Silva")])

        # Components don't work when interpolated, unfortunately
        @test htm"<$(\"f\") />" == JSX.Node(:f)
    end

    # Components have to be wrapped in dummy Nodes so that we always return Nodes, even after component evaluation
    let f(; name="John", surname="Doe") = htm"<div class=name><h1>$surname,</h1> <h2>$name</h2></div>"
        @test htm"<div class=person><f /></div>" == JSX.Node{:div}(
            [JSX.Node{:dummy}([f()])],
            ["class" => "person"],
        )
        @test htm"<div class=person><f name=Sarah /></div>" == JSX.Node{:div}(
            [JSX.Node{:dummy}([f(name="Sarah")])],
            ["class" => "person"],
        )
        @test htm"<div class=person><f surname=Silva /></div>" == JSX.Node{:div}(
            [JSX.Node{:dummy}([f(surname="Silva")])],
            ["class" => "person"],
        )
        @test htm"<div class=person><f name=João surname=Silva /></div>" == JSX.Node{:div}(
            [JSX.Node{:dummy}([f(name="João", surname="Silva")])],
            ["class" => "person"],
        )
        @test htm"<div class=person><f name=João surname=Silva/></div>" == JSX.Node{:div}(
            [JSX.Node{:dummy}([f(name="João", surname="Silva")])],
            ["class" => "person"],
        )
        @test htm"<div class=person><f surname=Silva name=João /></div>" == JSX.Node{:div}(
            [JSX.Node{:dummy}([f(name="João", surname="Silva")])],
            ["class" => "person"],
        )
    end
end