using HTM
using Documenter

DocMeta.setdocmeta!(HTM, :DocTestSetup, :(using HTM); recursive=true)

makedocs(;
    modules=[HTM],
    authors="Felipe S. S. Schneider <schneider.felipe@posgrad.ufsc.br> and contributors",
    repo="https://github.com/schneiderfelipe/HTM.jl/blob/{commit}{path}#{line}",
    sitename="HTM.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://schneiderfelipe.github.io/HTM.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Usage" => "usage.md",
        "Design" => "design.md",
        "Benchmarks" => "benchmarks.md",
        "Related packages" => "related.md",
        "Internals" => "autodocs.md",
    ],
)

deploydocs(;
    repo="github.com/schneiderfelipe/HTM.jl",
)
