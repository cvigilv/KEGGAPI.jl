using Revise
using KEGGAPI
using DataFrames

# Info Examples
kegg_info = KEGGAPI.info("kegg");
kegg_info = KEGGAPI.info("pathway");
kegg_info = KEGGAPI.info("module");

# List examples
## List organisms
kegg_organisms = KEGGAPI.list("organism");
## List pathways
kegg_pathways = KEGGAPI.list("pathway");
## List modules
kegg_modules = KEGGAPI.list("module");
## List orthologies
kegg_orthologies = KEGGAPI.list("orthology");
## List human pathways
kegg_genes = KEGGAPI.list("hsa", "genes");

# Find Examples
## Find a compound
kegg_compounds = KEGGAPI.find("compound", "glucose");
kegg_compounds = KEGGAPI.find("compound", "C7H10O5", "formula");
kegg_compounds = KEGGAPI.find("compound", "174.05", "exact_mass");
kegg_compounds = KEGGAPI.find("compound", "300-310", "mol_weight");
## Find a pathway
kegg_pathways = KEGGAPI.find("pathway", "glycolysis");
## Find a gene
kegg_genes = KEGGAPI.find("genes", "glycolysis");
kegg_genes = KEGGAPI.find("genes", "shiga toxin");
## Find a drug
kegg_drugs = KEGGAPI.find("drug", "aspirin");
## Find a disease
kegg_diseases = KEGGAPI.find("disease", "cancer");
## Find a module
kegg_modules = KEGGAPI.find("module", "M00001");
## Find a orthology
kegg_orthologies = KEGGAPI.find("orthology", "K00844");
## Find a brite hierarchy
kegg_brite = KEGGAPI.find("brite", "DNA Polymerase");

# Conv Examples
## Convert from KEGG to NCBI
kegg_conv = KEGGAPI.conv("eco", "ncbi-geneid");
## Convert from NCBI to KEGG
kegg_conv = KEGGAPI.conv("ncbi-geneid", "eco");

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
kegg_link = KEGGAPI.link("pathway", "hsa");
## Link a pathway to a compound
kegg_link = KEGGAPI.link("pathway", "cpd");
## Link a pathway to a drug
kegg_link = KEGGAPI.link("pathway", "dr");

# Image Examples
## Get an image
kegg_image = KEGGAPI.get_image("hsa00010");
## Save an image
KEGGAPI.save_image(kegg_image, "image.png");
