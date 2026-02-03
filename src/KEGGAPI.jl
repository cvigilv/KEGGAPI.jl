module KEGGAPI

import HTTP: get

export request, info, list, find, get_image, kegg_get, conv, link, save_image

include("Structures.jl")
include("Parsers.jl")
include("List.jl")
include("Find.jl")
include("Conv.jl")
include("Link.jl")
include("Get.jl")
include("Requests.jl")
include("Info.jl")
include("Images.jl")


precompile(request, (String,))
precompile(request_other, (String,))
precompile(kegg_get, (Vector,))

end
