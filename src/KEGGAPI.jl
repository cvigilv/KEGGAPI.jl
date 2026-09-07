module KEGGAPI

import HTTP: get
import Tables

include("utils.jl")
include("Structures.jl")
include("Conv.jl")
include("Ddi.jl")
include("Find.jl")
include("Get.jl")
include("Info.jl")
include("Link.jl")
include("List.jl")
include("Parsers.jl")
include("Requests.jl")

export @kegg_str,
    KeggTable,
    kegg_conv,
    kegg_ddi,
    kegg_find,
    kegg_get,
    kegg_info,
    kegg_link,
    kegg_list,
    request


precompile(request, (String,))
precompile(request_other, (String,))
precompile(kegg_get, (Vector,))
precompile(kegg_ddi, (Vector,))

end
