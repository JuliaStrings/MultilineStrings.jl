using MultilineStrings
using Documenter

makedocs(;
    modules=[MultilineStrings],
    authors="Invenia Technical Computing Corporation",
    repo="https://github.com/JuliaStrings/MultilineStrings.jl/blob/{commit}{path}#L{line}",
    sitename="MultilineStrings.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://juliastrings.github.io/MultilineStrings.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
    strict=true,
    checkdocs=:exports,
)

deploydocs(;
    repo="github.com/JuliaStrings/MultilineStrings.jl",
)
