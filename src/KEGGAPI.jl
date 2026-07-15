module KEGGAPI

import HTTP: get

include("utils.jl")
include("Conv.jl")
include("Find.jl")
include("Get.jl")
include("Info.jl")
include("Link.jl")
include("List.jl")
include("Parsers.jl")
include("Requests.jl")
include("Structures.jl")

export @kegg_str,
   kegg_conv,
   kegg_find,
   kegg_get,
   kegg_info,
   kegg_link,
   kegg_list,
   request


precompile(request, (String,))
precompile(request_other, (String,))
precompile(kegg_get, (Vector,))

end
