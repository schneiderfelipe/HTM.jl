# Wild Unicode characters have appeared!
@test htm"""
    <olá atenção="qualé mané" caça="com gato em samba canção">
        Não se faça de pamonha meu irmão!
    </olá>""" == Node("olá", ["atenção" => "qualé mané", "caça" => "com gato em samba canção"], [" Não se faça de pamonha meu irmão! "])
@test htm"<∫ dω=\"dx\" x₀=\"0\" x₁=\"∞\" comment=\"hard math\">√(x²)</∫>" == Node("∫", ["dω" => "dx", "x₀" => "0", "x₁" => "∞", "comment" => "hard math"], ["√(x²)"])