using Documenter, TableTraitsUtils

makedocs(
	modules=[TableTraitsUtils],
	sitename="TableTraitsUtils.jl",
	format = Documenter.HTML(analytics = "UA-132838790-1"),
	warnonly = [:missing_docs],
	pages=[
        "Introduction" => "index.md"
    ]
)

deploydocs(
    repo="github.com/queryverse/TableTraitsUtils.jl.git"
)
