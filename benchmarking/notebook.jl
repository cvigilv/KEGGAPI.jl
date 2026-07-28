### A Pluto.jl notebook ###
# v0.20.24

using Markdown
using InteractiveUtils

# ╔═╡ 434324c8-8a87-11f1-adb0-599460332cfd
begin
	using Pkg
	Pkg.activate(".")
	Pkg.add(["CSV", "DataFrames", "Chain", "CairoMakie", "AlgebraOfGraphics"])

	using CSV
	using DataFrames
	using Chain
	using CairoMakie
	using AlgebraOfGraphics
end

# ╔═╡ 39f4659c-fd34-444d-8cbd-1fa73468ffd4
df = CSV.read("/Users/carlos/git/KEGGAPI.jl/benchmarking/benchmark_compare.csv", DataFrame)

# ╔═╡ 1b2ff946-cfca-4e81-9391-cdfe7054fdf5
name_map = Dict(
	"KEGGAPI.jl" => "KEGGAPI.jl",
	"KEGGREST (R)" => "KEGGREST",
	"Bio.KEGG.REST (Python)" => "Bio.KEGG",
	"curl" => "curl"
)

# ╔═╡ 5807e3a7-e12f-4ce4-b19b-37f281397904
let
	px = 250
	set_theme!(theme_minimal())
	f = draw(
		data(filter(r -> r.Function != "getseq", eachrow(df)))
		* mapping(
			:Language => (x -> name_map[String(x)]) => "", 
			:Median => "Seconds per call (median)",
			col=:Function => presorted, 
			color=:Language
		)
		* visual(
			BarPlot,
			direction=:x,
			bar_labels = :y,
			flip_labels_at=(0, 1.1),
			label_formatter = x -> trunc(x, digits=2)
		),
		
		scales(;
			Y = (; categories = ["KEGGAPI.jl", "KEGGREST", "Bio.KEGG", "curl"] |> reverse),
			Color = (; palette = ["gainsboro", "#0031a9", "gainsboro", "gainsboro"])
		),
		figure = (;size=(4*px,px)),
		axis = (; limits=(0, nothing, nothing, nothing), xticks=[-1], bottomspinevisible=false),
		legend = (; show = false),
		facet = (; linkxaxes = :none)
	)
	save("benchmark.svg", f)
	f
end

# ╔═╡ Cell order:
# ╠═434324c8-8a87-11f1-adb0-599460332cfd
# ╠═39f4659c-fd34-444d-8cbd-1fa73468ffd4
# ╠═1b2ff946-cfca-4e81-9391-cdfe7054fdf5
# ╠═5807e3a7-e12f-4ce4-b19b-37f281397904
