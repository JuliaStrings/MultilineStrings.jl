using BlockScalars
using Documenter

makedocs(;
    modules=[BlockScalars],
    authors="Invenia Technical Computing Corporation",
    repo="https://github.com/invenia/BlockScalars.jl/blob/{commit}{path}#L{line}",
    sitename="BlockScalars.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://invenia.github.io/BlockScalars.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
    strict=true,
    checkdocs=:exports,
)

deploydocs(;
    repo="github.com/invenia/BlockScalars.jl",
)
