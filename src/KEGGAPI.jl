module KEGGAPI

import HTTP: get
import .Iterators: partition

include("Conv.jl")
include("Ddi.jl")
include("Find.jl")
include("Get.jl")
include("Info.jl")
include("Link.jl")
include("List.jl")
include("Parsers.jl")
include("Requests.jl")
include("Structures.jl")

export @kegg_str,
    RequestError,
    kegg_conv,
    kegg_ddi,
    kegg_find,
    kegg_get,
    kegg_info,
    kegg_link,
    kegg_list

end
