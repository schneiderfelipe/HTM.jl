using JSX
using Documenter

DocMeta.setdocmeta!(JSX, :DocTestSetup, :(using JSX); recursive=true)

makedocs(;
    modules=[JSX],
    authors="Felipe S. S. Schneider <schneider.felipe@posgrad.ufsc.br> and contributors",
    repo="https://github.com/schneiderfelipe/JSX.jl/blob/{commit}{path}#{line}",
    sitename="JSX.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://schneiderfelipe.github.io/JSX.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/schneiderfelipe/JSX.jl",
)
