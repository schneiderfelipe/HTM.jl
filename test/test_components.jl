@testset "Components" begin
    # A wild component has appeared!
    let f(; who="world!") = "Hello $who"
        @test htm"<f />" == JSX.Node{:component}([f()])
        @test htm"<f/>" == JSX.Node{:component}([f()])

        @test htm"<f who=dear />" == JSX.Node{:component}([f(who="dear")])
        @test htm"<f who=\"honey\" />" == JSX.Node{:component}([f(who="honey")])

        let who = "planet"
            @test htm"<f who=$who />" == JSX.Node{:component}([f(who=who)])
            @test htm"<f who=\"$who\" />" == JSX.Node{:component}([f(who=who)])
        end
    end

    let f(; name="John", surname="Doe") = "$name $surname"
        @test htm"<f />" == JSX.Node{:component}([f()])
        @test htm"<f name=Sarah />" == JSX.Node{:component}([f(name="Sarah")])
        @test htm"<f surname=Silva />" == JSX.Node{:component}([f(surname="Silva")])
        @test htm"<f name=João surname=Silva />" == JSX.Node{:component}([f(name="João", surname="Silva")])
        @test htm"<f name=João surname=Silva/>" == JSX.Node{:component}([f(name="João", surname="Silva")])
        @test htm"<f surname=Silva name=João />" == JSX.Node{:component}([f(name="João", surname="Silva")])

        # Components don't work when interpolated
        @test htm"<$(\"f\") />" == JSX.Node(:f)
    end

    let f(; name="John", surname="Doe") = htm"<div class=name><h1>$surname,</h1> <h2>$name</h2></div>"
        @test htm"<div class=person><f /></div>" == JSX.Node{:div}(
            [JSX.Node{:component}([f()])],
            ["class" => "person"],
        )
        @test htm"<div class=person><f name=Sarah /></div>" == JSX.Node{:div}(
            [JSX.Node{:component}([f(name="Sarah")])],
            ["class" => "person"],
        )
        @test htm"<div class=person><f surname=Silva /></div>" == JSX.Node{:div}(
            [JSX.Node{:component}([f(surname="Silva")])],
            ["class" => "person"],
        )
        @test htm"<div class=person><f name=João surname=Silva /></div>" == JSX.Node{:div}(
            [JSX.Node{:component}([f(name="João", surname="Silva")])],
            ["class" => "person"],
        )
        @test htm"<div class=person><f name=João surname=Silva/></div>" == JSX.Node{:div}(
            [JSX.Node{:component}([f(name="João", surname="Silva")])],
            ["class" => "person"],
        )
        @test htm"<div class=person><f surname=Silva name=João /></div>" == JSX.Node{:div}(
            [JSX.Node{:component}([f(name="João", surname="Silva")])],
            ["class" => "person"],
        )
    end
end