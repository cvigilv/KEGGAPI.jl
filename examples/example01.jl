using Revise
using KEGGAPI
using DataFrames

# Info Examples
info_kegg = KEGGAPI.kegg_info("kegg");
info_pathway = KEGGAPI.kegg_info("pathway");
info_module = KEGGAPI.kegg_info("module");

# List examples
## List organisms (genomes)
kegg_organisms = KEGGAPI.kegg_list("genome");
## List pathways
kegg_pathways = KEGGAPI.kegg_list("pathway");
## List modules
kegg_modules = KEGGAPI.kegg_list("module");
## List orthologies
kegg_orthologies = KEGGAPI.kegg_list("ko");
## List human genes
kegg_genes = KEGGAPI.kegg_list("hsa", "genes");

# Find Examples
## Find a compound
kegg_compounds = KEGGAPI.kegg_find("compound", "glucose");
kegg_compounds = KEGGAPI.kegg_find("compound", "C7H10O5", "formula");
kegg_compounds = KEGGAPI.kegg_find("compound", "174.05", "exact_mass");
kegg_compounds = KEGGAPI.kegg_find("compound", "300-310", "mol_weight");
## Find a pathway
kegg_pathways = KEGGAPI.kegg_find("pathway", "glycolysis");
## Find a gene
kegg_genes = KEGGAPI.kegg_find("genes", "glycolysis");
kegg_genes = KEGGAPI.kegg_find("genes", "shiga toxin");
## Find a drug
kegg_drugs = KEGGAPI.kegg_find("drug", "aspirin");
## Find a disease
kegg_diseases = KEGGAPI.kegg_find("disease", "cancer");
## Find a module
kegg_modules = KEGGAPI.kegg_find("module", "M00001");
## Find an orthology
kegg_orthologies = KEGGAPI.kegg_find("ko", "K00844");
## Find a brite hierarchy
kegg_brite = KEGGAPI.kegg_find("brite", "DNA Polymerase");

# Conv Examples
## Convert from KEGG to NCBI
kegg_conv = KEGGAPI.kegg_conv("eco", "ncbi-geneid");
## Convert from NCBI to KEGG
kegg_conv = KEGGAPI.kegg_conv("ncbi-geneid", "eco");

# Get Examples
## Get a pathway
kegg_pathway = KEGGAPI.kegg_get(["eco00010"]);
## Get a gene
kegg_gene = KEGGAPI.kegg_get(["eco:b0002"]);
## Get a compound
kegg_compound = KEGGAPI.kegg_get(["cpd:C00022"]);
## Get a drug
kegg_drug = KEGGAPI.kegg_get(["dr:D00111"]);
## Get a drug and a gene
kegg_drug_gene = KEGGAPI.kegg_get(["dr:D00111", "eco:b0002"]);
## Get a disease
kegg_disease = KEGGAPI.kegg_get(["ds:H00025"]);

# Link Examples
## Link a pathway to a gene
kegg_link = KEGGAPI.kegg_link("pathway", "hsa");
## Link a pathway to a compound
kegg_link = KEGGAPI.kegg_link("pathway", "cpd");
## Link a pathway to a drug
kegg_link = KEGGAPI.kegg_link("pathway", "dr");
## Link a drug to ATC codes as RDF (turtle)
kegg_link_rdf = KEGGAPI.kegg_link("atc", "D00564", "turtle");

# DDI Examples
## Find adverse drug-drug interactions for a drug
kegg_ddi = KEGGAPI.kegg_ddi("D00564");
## Find interactions among several drugs
kegg_ddi = KEGGAPI.kegg_ddi(["D00564", "D00100"]);

# Image Examples
## Get a pathway map image (bytes)
kegg_image = KEGGAPI.kegg_get("hsa00010", :image);
## Save an image to disk
open("image.png", "w") do io
    write(io, kegg_image.data)
end
