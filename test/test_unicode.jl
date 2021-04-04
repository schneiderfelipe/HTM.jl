@testset "Unicode strings" begin
    # Wild Unicode characters have appeared!
    @test htm"""
        <olá atenção="qualé mané" caça="com gato em samba canção">
            Não se faça de pamonha meu irmão!
        </olá>""" == JSX.Node{:olá}(
            [JSX.Node{:text}([" Não se faça de pamonha meu irmão! "])],
            ["atenção" => "qualé mané", "caça" => "com gato em samba canção"],
        )
    @test htm"<∫ dω=\"dx\" x₀=\"0\" x₁=\"∞\" note=\"hard math\">√(x²)</∫>" == JSX.Node{:∫}(
        [JSX.Node{:text}(["√(x²)"])],
        ["dω" => "dx", "x₀" => "0", "x₁" => "∞", "note" => "hard math"],
    )
end