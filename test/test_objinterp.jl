@testset "Object interpolation" begin
    @test htm"<h1> $ </h1>" == Node("h1", [], [" \$ "])
    @test htm"<h1>$ </h1>" == Node("h1", [], ["\$ "])
    @test htm"<h1> $</h1>" == Node("h1", [], [" \$"])
    @test htm"<h1>$</h1>" == Node("h1", [], ["\$"])

    @test htm"<h1>\$name</h1>" == Node("h1", [], ["\$name"])
    let name = "John Doe"
        @test htm"<h1>$name</h1>" == Node("h1", [], [name])
    end

    # Wild math expressions have appeared!
    @test htm"<math>$(1 + 2)</math>" == Node("math", [], [3])
    @test htm"$(1 + 2)" == 3
    @test htm"<math>$(√4)</math>" == Node("math", [], [2.0])
    @test htm"$(√4)" == 2.0

    # Wild Markdown snippets have appeared!
    let markdown = md"*Hello* **world** from [Markdown](https://docs.julialang.org/en/v1/stdlib/Markdown/)"
        @test htm"<section>$markdown</section>" == Node("section", [], [markdown])
        @test htm"<section>$markdown $markdown</section>" == Node("section", [], [markdown, markdown])
        @test htm"""
            <section>
                <h1>$(md"My awesome title!")</h1>
                $markdown $markdown
            </section>
        """ == Node("section", [], [Node("h1", [], [md"My awesome title!"]), markdown, markdown])
    end
end