### A Pluto.jl notebook ###
# v0.20.24

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ 88a0f4bc-9397-4588-9471-2ce3f14c3240
begin
	using Pkg
	Pkg.activate(joinpath(@__DIR__, ".."))
	Pkg.instantiate()

	using Luxor
	using PlutoUI
	using Random
end

# ╔═╡ 6202d84a-e3ed-4e46-aba2-0893669c0892
md"""
# The KEGGAPI.jl logo

The [KEGG](https://www.kegg.jp) mark is an egg packed with a mosaic of curved
tiles. This notebook redraws that egg with [Luxor](https://juliagraphics.github.io/Luxor.jl/)
in the Julia logo palette. No lettering is drawn — the wordmark is layered on
separately.

Move the sliders near the bottom to explore variants, then tick the export box
to write `keggapi-egg.svg` and `keggapi-egg.png` next to this notebook. Running
the file headlessly renders both with the settings saved here:

```
julia --project=assets assets/logo/make_logo.jl
```
"""

# ╔═╡ 0f30cc00-48b7-44f1-9302-fd094a9cd2af
md"""
## Palette

The four official [Julia logo colours](https://github.com/JuliaLang/julia-logo-graphics),
on black ink. The ink fills the egg, separates neighbouring tiles, and shows
through wherever the mosaic leaves a gap.
"""

# ╔═╡ 45eb0392-116f-4582-8ec5-5b1d552fc2d6
begin
	JULIA_BLUE = "#4063D8"
	JULIA_GREEN = "#389826"
	JULIA_RED = "#CB3C33"
	JULIA_PURPLE = "#9558B2"

	PALETTE = [JULIA_BLUE, JULIA_GREEN, JULIA_RED, JULIA_PURPLE]
	INK = "#000000"
end

# ╔═╡ fc7522e6-8afb-44f0-b7dd-39a5def03bcf
md"""
## Style

Every proportion of the logo lives in one struct, so a variant is a single call:
`LogoStyle(seed = 7, egg_taper = 0.2)`. Lengths are in design units; the drawing
is scaled to whatever output width you ask for.
"""

# ╔═╡ 3ce1e716-c8e1-4d95-931e-960324a4c81c
"""
    LogoStyle

Proportions and randomness of the logo.

# Fields
- `palette::Vector{String}`: tile colours, dealt out evenly.
- `ink::String`: egg fill, and the colour of the gutters between tiles.
- `egg_length::Float64`, `egg_width::Float64`: long and short axes of the egg.
- `egg_taper::Float64`: how much fatter one end is than the other; `0` is a plain ellipse.
- `tilt::Float64`: radians the narrow tip is raised above horizontal.
- `margin::Float64`: clear space around the egg.
- `tile_radius::Float64`: radius of the half-donut every tile is cut from.
- `tile_width::Float64`: thickness of a tile.
- `tile_gap::Float64`: ink left between neighbouring tiles.
- `grid_step::Float64`: nominal spacing of tile centres; the density knob.
- `grid_jitter::Float64`: fraction of `grid_step` a centre may wander.
- `seed::Int`: fixed, so a given style always yields the same mosaic.
- `light_angle::Float64`: direction of the light; `-π/2` is straight above.
- `light_distance::Float64`: how far the light sits from the centre, as a fraction of the egg.
- `highlight::Float64`: opacity of the lit spot; `0` turns it off.
- `shading::Float64`: opacity of the shadow at the far edge; `0` leaves the egg flat.
"""
Base.@kwdef struct LogoStyle
	palette::Vector{String} = PALETTE
	ink::String = INK
	egg_length::Float64 = 860.0
	egg_width::Float64 = 630.0
	egg_taper::Float64 = 0.16
	tilt::Float64 = deg2rad(12)
	margin::Float64 = 14.0
	tile_radius::Float64 = 56.0
	tile_width::Float64 = 42.0
	tile_gap::Float64 = 5.0
	grid_step::Float64 = 54.0
	grid_jitter::Float64 = 0.9
	seed::Int = 57
	light_angle::Float64 = deg2rad(-70)
	light_distance::Float64 = 0.52
	highlight::Float64 = 0.12
	shading::Float64 = 0.70
end

# ╔═╡ ee0d1dbe-ddf1-4929-a8ac-1a8aaa23b6ac
md"""
## The egg

The outline is an ellipse whose half-thickness is modulated along its long axis:

$h(\varphi) = \tfrac{1}{2} W \sin\varphi \, (1 - k \cos\varphi)$

At ``k = 0`` this is a plain ellipse. Raising ``k`` fattens one end and narrows
the other; because the ends stay elliptical the tip rounds off instead of coming
to a point. Around ``k = 0.16`` the two ends differ in curvature by about the
same ratio as a hen's egg. The curve is then turned so the tip points up and to
the right, and recentred on its own bounding box.
"""

# ╔═╡ e1b99af7-495a-4ffc-b08c-d1b7f5a27e01
"""
    turn(p::Point, angle::Real) -> Point

Rotate `p` about the origin. Positive angles turn clockwise on screen, since
Luxor's y axis points down.
"""
turn(p::Point, angle::Real) = Point(
	p.x * cos(angle) - p.y * sin(angle),
	p.x * sin(angle) + p.y * cos(angle),
)

# ╔═╡ 61ba30f2-71b7-45c6-bd2a-f41faaf81c7a
"""
    egg_outline(style::LogoStyle; steps::Int = 360) -> Vector{Point}

The egg silhouette as a closed polygon of `steps` points, tilted and centred on
the origin.
"""
function egg_outline(style::LogoStyle; steps::Int = 360)::Vector{Point}
	k = style.egg_taper
	# Normalise so the fattest point is exactly `egg_width` across.
	peak = maximum(sin(φ) * (1 - k * cos(φ)) for φ in range(0, π, length = 2001))
	points = [
		turn(
			Point(
				(style.egg_length / 2) * cos(φ),
				(style.egg_width / 2) * sin(φ) * (1 - k * cos(φ)) / peak,
			),
			-style.tilt,
		)
		for φ in range(0, 2π, length = steps + 1)[1:steps]
	]
	box = BoundingBox(points)
	middle = (box[1] + box[2]) / 2
	return [p - middle for p in points]
end

# ╔═╡ 0da8b1be-a5dc-48e9-902f-050d034f89c9
"""
    design_size(style::LogoStyle) -> Tuple{Float64, Float64}

Width and height of the drawing in design units: the egg's bounding box plus its
margin. The tilt changes the aspect ratio, so the canvas follows the egg rather
than the other way round.
"""
function design_size(style::LogoStyle)::Tuple{Float64, Float64}
	box = BoundingBox(egg_outline(style))
	return (boxwidth(box) + 2style.margin, boxheight(box) + 2style.margin)
end

# ╔═╡ 224ba7db-f453-4f52-8351-a9bc201b9a58
md"""
## The mosaic

Every tile is the same shape: a half-donut, a 180° arc of fixed radius and
width, with round caps for the tips. Only position, rotation and colour change.
Centres come from a jittered grid, and colours are dealt from a shuffled deck
rather than sampled independently, so all four appear in equal measure instead
of one thinning out by chance.

Each tile is stroked twice — once fat in ink, then once at its own width in
colour. The ink pass carves a gutter out of whatever is already on the canvas,
which separates neighbours without any overlap bookkeeping. The mosaic is
clipped to the outline, so tiles are cut flush at the edge of the egg.
"""

# ╔═╡ 285547da-2fab-43dd-a582-347f91fa8070
"""
    Tile

One piece of the mosaic: a half-donut centred on `center`, swept from
`startangle`, in `colour`.
"""
struct Tile
	center::Point
	startangle::Float64
	colour::String
end

# ╔═╡ 885181fb-f7a0-41e1-b835-0c710351b830
"""
    mosaic_tiles(style::LogoStyle) -> Vector{Tile}

Scatter tiles over a jittered grid covering the egg, then shuffle them. The grid
runs one step past the outline on every side so tiles are clipped by the edge
rather than stopping short of it.
"""
function mosaic_tiles(style::LogoStyle)::Vector{Tile}
	rng = MersenneTwister(style.seed)
	step = style.grid_step
	box = BoundingBox(egg_outline(style))
	xs = (box[1].x - step):step:(box[2].x + step)
	ys = (box[1].y - step):step:(box[2].y + step)

	ncells = length(xs) * length(ys)
	deck = shuffle!(rng, repeat(style.palette, cld(ncells, length(style.palette))))

	tiles = Tile[]
	for (i, (x, y)) in enumerate(Iterators.product(xs, ys))
		center = Point(
			x + step * style.grid_jitter * (rand(rng) - 0.5),
			y + step * style.grid_jitter * (rand(rng) - 0.5),
		)
		push!(tiles, Tile(center, 2π * rand(rng), deck[i]))
	end
	return shuffle!(rng, tiles)
end

# ╔═╡ db007800-97a2-4d2d-ade8-8777c6c6c784
"""
    draw_mosaic(tiles::Vector{Tile}, style::LogoStyle, zoom::Real)

Paint the tiles in order, ink pass first. `setline` takes device pixels and
ignores the current transform, so widths are pre-multiplied by `zoom` to keep
tiles in proportion at every output size.
"""
function draw_mosaic(tiles::Vector{Tile}, style::LogoStyle, zoom::Real)
	setlinecap("round")
	for tile in tiles
		sethue(style.ink)
		setline((style.tile_width + 2style.tile_gap) * zoom)
		arc(tile.center, style.tile_radius, tile.startangle, tile.startangle + π, :stroke)
		sethue(tile.colour)
		setline(style.tile_width * zoom)
		arc(tile.center, style.tile_radius, tile.startangle, tile.startangle + π, :stroke)
	end
	return nothing
end

# ╔═╡ e49dcc22-9f32-4c7a-a1df-a524199b37a0
md"""
## Shading

A radial gradient over the finished mosaic gives the egg some volume: a lit spot
where the light falls, fading to a shadow on the far side. The light sits above
and a little to the right, so the shadow gathers along the bottom left. The
gradient covers the egg and nothing else, so the background stays transparent.
"""

# ╔═╡ b165bdcd-9f80-4c4f-810c-e14f7eb9d853
"""
    draw_shading(outline::Vector{Point}, style::LogoStyle)

Lay a radial light-to-shadow gradient over the egg. Does nothing when both
`highlight` and `shading` are zero.
"""
function draw_shading(outline::Vector{Point}, style::LogoStyle)
	(style.highlight == 0 && style.shading == 0) && return nothing

	box = BoundingBox(outline)
	halfwidth, halfheight = boxwidth(box) / 2, boxheight(box) / 2
	light = Point(
		style.light_distance * halfwidth * cos(style.light_angle),
		style.light_distance * halfheight * sin(style.light_angle),
	)
	# End the gradient exactly at the point of the outline furthest from the
	# light, so the darkest stop lands on the far rim instead of somewhere off
	# the canvas — that is what turns a flat vignette into a lit solid.
	reach = maximum(distance(light, p) for p in outline)

	shade = blend(light, 0.0, light, reach)
	addstop(shade, 0.0, (1, 1, 1, style.highlight))
	addstop(shade, 0.18, (1, 1, 1, 0.0))
	addstop(shade, 0.55, (0, 0, 0, style.shading / 5))
	addstop(shade, 1.0, (0, 0, 0, style.shading))
	setblend(shade)
	poly(outline, :fill, close = true)
	return nothing
end

# ╔═╡ 01306fe6-9541-4de2-baff-3f7f156da4c3
md"""
## Drawing and export
"""

# ╔═╡ a43097e8-3bdb-41e9-8e5e-f14206fd8f8c
"""
    draw_logo(width::Real, style::LogoStyle = LogoStyle())

Draw the logo `width` pixels across, centred on the current origin, leaving the
transform as it found it. Callers place it; `render` just centres the page.
"""
function draw_logo(width::Real, style::LogoStyle = LogoStyle())
	zoom = width / first(design_size(style))
	outline = egg_outline(style)
	@layer begin
		scale(zoom)
		sethue(style.ink)
		poly(outline, :fill, close = true)

		@layer begin
			poly(outline, :clip, close = true)
			draw_mosaic(mosaic_tiles(style), style, zoom)
		end

		draw_shading(outline, style)
	end
	return nothing
end

# ╔═╡ baa9e532-df18-4227-a36b-15a09a274b8f
"""
    compact_svg(svg::String) -> String

Collapse duplicate `<clipPath>` definitions in an SVG written by Cairo.

Cairo repeats the entire clip path for every drawing operation inside a clipping
group, so the egg outline appears once per stroke — a few hundred identical
copies, and with them most of the file. Keeping the first copy of each distinct
path and pointing the rest at it cuts the mosaic down by better than 10×. Purely
a size fix: the rendered image is byte-identical.
"""
function compact_svg(svg::String)::String
	canonical = Dict{String, String}()   # path data => id of its first copy
	rename = Dict{String, String}()      # duplicate id => id to use instead
	for m in eachmatch(r"<clipPath id=\"([^\"]+)\">(.*?)</clipPath>"s, svg)
		id, body = m.captures
		kept = get!(canonical, body, id)
		kept == id || (rename[id] = kept)
	end
	isempty(rename) && return svg

	svg = replace(svg, r"<clipPath id=\"([^\"]+)\">(.*?)</clipPath>\n?"s => function (block)
		id = match(r"id=\"([^\"]+)\"", block).captures[1]
		return haskey(rename, id) ? "" : block
	end)
	return replace(svg, r"url\(#([^)]+)\)" => function (reference)
		id = reference[6:(end - 1)]
		return "url(#" * get(rename, id, id) * ")"
	end)
end

# ╔═╡ eedc5068-cf0f-4dbb-a177-d7de019c232e
"""
    compact_svg!(filename::String) -> String

Rewrite an SVG file through [`compact_svg`](@ref).
"""
compact_svg!(filename::String) = (write(filename, compact_svg(read(filename, String))); filename)

# ╔═╡ 89554d38-4969-45fa-b4d8-0d5232bc0d12
"""
    render(filename::String; width::Real = 1600, style::LogoStyle = LogoStyle())

Render the logo to `filename` on a transparent background. The format follows
the extension (`.svg`, `.png`, `.pdf`).
"""
function render(
		filename::String;
		width::Real = 1600,
		style::LogoStyle = LogoStyle(),
	)::String
	dwidth, dheight = design_size(style)
	Drawing(round(Int, width), round(Int, width * dheight / dwidth), filename)
	origin()
	draw_logo(width, style)
	finish()
	endswith(filename, ".svg") && compact_svg!(filename)
	return filename
end

# ╔═╡ b9d50420-6fbf-4951-bb7f-ef3ed15e29be
md"""
## Controls

| | |
|---:|:---|
| tip raised | $(@bind tilt_degrees Slider(0:1:90, default = 12, show_value = true))° |
| egg taper | $(@bind egg_taper Slider(0:0.02:0.4, default = 0.16, show_value = true)) |
| egg length | $(@bind egg_length Slider(600:20:1000, default = 860, show_value = true)) |
| egg width | $(@bind egg_width Slider(400:10:800, default = 630, show_value = true)) |
| tile radius | $(@bind tile_radius Slider(20:2:100, default = 56, show_value = true)) |
| tile width | $(@bind tile_width Slider(10:2:80, default = 42, show_value = true)) |
| tile gap | $(@bind tile_gap Slider(0:1:20, default = 5, show_value = true)) |
| grid step | $(@bind grid_step Slider(30:2:120, default = 54, show_value = true)) |
| seed | $(@bind seed Slider(1:100, default = 57, show_value = true)) |
| light angle | $(@bind light_degrees Slider(-180:5:0, default = -70, show_value = true))° |
| light distance | $(@bind light_distance Slider(0:0.02:0.8, default = 0.52, show_value = true)) |
| highlight | $(@bind highlight Slider(0:0.02:0.6, default = 0.12, show_value = true)) |
| shading | $(@bind shading Slider(0:0.05:1, default = 0.7, show_value = true)) |
"""

# ╔═╡ f1c7612b-e130-49c1-ad4a-24493f3eab60
style = LogoStyle(
	egg_length = float(egg_length),
	egg_width = float(egg_width),
	egg_taper = float(egg_taper),
	tilt = deg2rad(tilt_degrees),
	tile_radius = float(tile_radius),
	tile_width = float(tile_width),
	tile_gap = float(tile_gap),
	grid_step = float(grid_step),
	seed = Int(seed),
	light_angle = deg2rad(light_degrees),
	light_distance = float(light_distance),
	highlight = float(highlight),
	shading = float(shading),
)

# ╔═╡ 4c482e97-87e4-44da-9ea3-a19114977f2a
let
	width = 620
	dwidth, dheight = design_size(style)
	Drawing(width, round(Int, width * dheight / dwidth), :svg)
	origin()
	# White only so the preview reads in both Pluto themes; the exported files
	# keep their transparent background.
	background("white")
	draw_logo(width, style)
	finish()
	# Straight from `svgstring` this is a few megabytes of repeated clip paths,
	# which makes dragging a slider crawl.
	HTML(compact_svg(svgstring()))
end

# ╔═╡ d3b444d7-a71c-4a3a-8ff9-00e6e689959f
md"""
Write the files next to this notebook: $(@bind export_files CheckBox(default = false))
"""

# ╔═╡ 1d590a6e-cab9-44e4-9970-0a678923ac51
# A headless `julia make_logo.jl` run has no checkbox to tick, so it always exports.
if export_files || !isdefined(Main, :PlutoRunner)
	written = [
		render(joinpath(@__DIR__, "keggapi-egg.svg"), width = 920, style = style),
		render(joinpath(@__DIR__, "keggapi-egg.png"), width = 1600, style = style),
	]
	Markdown.parse("Wrote:\n" * join("- `" .* written .* "`", "\n"))
else
	md"Nothing written yet."
end

# ╔═╡ Cell order:
# ╟─6202d84a-e3ed-4e46-aba2-0893669c0892
# ╠═88a0f4bc-9397-4588-9471-2ce3f14c3240
# ╟─0f30cc00-48b7-44f1-9302-fd094a9cd2af
# ╠═45eb0392-116f-4582-8ec5-5b1d552fc2d6
# ╟─fc7522e6-8afb-44f0-b7dd-39a5def03bcf
# ╠═3ce1e716-c8e1-4d95-931e-960324a4c81c
# ╟─ee0d1dbe-ddf1-4929-a8ac-1a8aaa23b6ac
# ╠═e1b99af7-495a-4ffc-b08c-d1b7f5a27e01
# ╠═61ba30f2-71b7-45c6-bd2a-f41faaf81c7a
# ╠═0da8b1be-a5dc-48e9-902f-050d034f89c9
# ╟─224ba7db-f453-4f52-8351-a9bc201b9a58
# ╠═285547da-2fab-43dd-a582-347f91fa8070
# ╠═885181fb-f7a0-41e1-b835-0c710351b830
# ╠═db007800-97a2-4d2d-ade8-8777c6c6c784
# ╟─e49dcc22-9f32-4c7a-a1df-a524199b37a0
# ╠═b165bdcd-9f80-4c4f-810c-e14f7eb9d853
# ╟─01306fe6-9541-4de2-baff-3f7f156da4c3
# ╠═a43097e8-3bdb-41e9-8e5e-f14206fd8f8c
# ╠═baa9e532-df18-4227-a36b-15a09a274b8f
# ╠═eedc5068-cf0f-4dbb-a177-d7de019c232e
# ╠═89554d38-4969-45fa-b4d8-0d5232bc0d12
# ╟─b9d50420-6fbf-4951-bb7f-ef3ed15e29be
# ╟─f1c7612b-e130-49c1-ad4a-24493f3eab60
# ╠═4c482e97-87e4-44da-9ea3-a19114977f2a
# ╟─d3b444d7-a71c-4a3a-8ff9-00e6e689959f
# ╠═1d590a6e-cab9-44e4-9970-0a678923ac51
