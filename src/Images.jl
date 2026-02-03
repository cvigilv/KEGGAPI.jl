"""
KEGGAPI.get_image(pathway) -> Image

Get an image of a specific pathway from the KEGG API.

Example:

```@example
KEGGAPI.get_image("hsa00010")
```
"""
function get_image(pathway_id::String)
    url = "https://rest.kegg.jp/get/$pathway_id/image"
    response = request_other(url)
    return response
end

"""
KEGGAPI.save_image(image, filename) -> filename

Save an image to a file.

# Examples
```example
image = KEGGAPI.get_image("hsa00010")
KEGGAPI.save_image(image, "glycolysis.png")
```
"""
function save_image(image::Vector, filename::String)
    # write a test for the above function  in KEGGAPI/test/runtests.jl
    open(filename, "w") do f
        write(f, image)
    end
    return filename
end
