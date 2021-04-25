using HyperscriptLiteral
using Documenter

DocMeta.setdocmeta!(HyperscriptLiteral, :DocTestSetup, :(using HyperscriptLiteral); recursive=true)

makedocs(;
    modules=[HyperscriptLiteral],
    authors="Felipe S. S. Schneider <schneider.felipe@posgrad.ufsc.br> and contributors",
    repo="https://github.com/schneiderfelipe/HyperscriptLiteral.jl/blob/{commit}{path}#{line}",
    sitename="HyperscriptLiteral.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://schneiderfelipe.github.io/HyperscriptLiteral.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Guide" => "guide.md",
        "How it works" => "howitworks.md",  # change to "Design"
        "Related packages" => "related.md",
        "Docstrings" => "autodocs.md",
    ],
)

deploydocs(;
    repo="github.com/schneiderfelipe/HyperscriptLiteral.jl",
)