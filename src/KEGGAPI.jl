module KEGGAPI

import HTTP: get

export request, kegg_info, kegg_list, kegg_find, kegg_get, kegg_conv, kegg_link, @kegg_str

include("Structures.jl")
include("Parsers.jl")
include("List.jl")
include("Find.jl")
include("Conv.jl")
include("Link.jl")
include("Get.jl")
include("Requests.jl")
include("Info.jl")


precompile(request, (String,))
precompile(request_other, (String,))
precompile(kegg_get, (Vector,))

end
