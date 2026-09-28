using RegularlySampledFormat
using Documenter

DocMeta.setdocmeta!(RegularlySampledFormat, :DocTestSetup, :(using RegularlySampledFormat); recursive=true)

makedocs(;
    modules=[RegularlySampledFormat],
    authors="sfomel <sergey.fomel@gmail.com> and contributors",
    sitename="RegularlySampledFormat.jl",
    format=Documenter.HTML(;
        canonical="https://sfomel.github.io/RegularlySampledFormat.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/sfomel/RegularlySampledFormat.jl",
    devbranch="main",
)
