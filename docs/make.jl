using MultilineStrings
using Documenter

const IS_CI = get(ENV, "CI", nothing) == "true"

makedocs(;
    modules=[MultilineStrings],
    format=Documenter.HTML(prettyurls=IS_CI),
    pages=[
        "Home" => "index.md",
    ],
    sitename="MultilineStrings.jl",
    checkdocs=:exports,
    linkcheck=true,
    doctest=true,
)

IS_CI && deploydocs(; repo="github.com/JuliaStrings/MultilineStrings.jl")
