library(readr)
library(optparse)

option_list <- list(
  make_option(c("-q", "--query"), type='character', action='store', default=NA,
            help = "File containing the GWAS filenames to filter"),
  make_option(c("-p", "--pop"), type='character', action='store', default='EUR',
              help = "Population used for downstream analysis, phenotypes extracted only if contains provided population. Default value is EUR"),
  make_option(c("-m", "--manifest"), type='character', action='store', default=NA,
              help = "Pan-UK Biobank phenotype manifest file"),
  make_option(c("-o", "--output"), type='character', action='store', default='neale_input.txt',
              help = "Output file name"),
  make_option(c("-e", "--error"), type='character', action='store', default="extract_phenotype.error",
              help = "Error file name"),
  make_option(c("--metadata"), type='character', action='store', default="phenotype_metadata.tsv",
              help = "Phenotype metadata file name")
)

opt <- parse_args(OptionParser(option_list=option_list))


manifest <- read_tsv(opt$manifest)
headers <- colnames(manifest)
headers[headers == 'id'] <- 'outcome.id'
colnames(manifest) <- headers

filename <- 'outcome.id'
cols_interest <- c('outcome.id', 'trait', 'note', 'group_name', 'year', 'author', 'sex', 'pmid', 'population', 'unit', 'sample_size', 'nsnp', 'build', 'category', 'subcategory', 'ontology', 'consortium', 'ncase', 'ncontrol')

manifest <- as.data.frame(manifest)
rownames(manifest) <- manifest[,filename]

query <- read.table(opt$query)[[1]]

index <- which(manifest[,filename] %in% query)

if (!file.exists(opt$error)) {
  write.table(t(c('File', 'Error')), opt$error, row.names=FALSE, col.names=FALSE, quote=FALSE, sep=',')
}

pop <- c()
if (opt$pop == "EUR") {
  pop <- c("European")
}else if (opt$pop == "EAS") {
  pop <- c("South East Asian", "East Asian", "Asian unspecified")
}else if (opt$pop == "AFR") {
  pop <- c("Sub-Saharan African", "African unspecified")
}else if (opt$pop == "AMR") {
  pop <- c("African American or Afro-Caribbean", "Mixed", "Other admixed ancestry")
}

if (length(index[!manifest[index,'population'] %in% pop]) > 0) {
  write.table(cbind(manifest[index[!manifest[index,'population'] %in% pop],filename], 'Population Missing'), opt$error, row.names=FALSE, col.names=FALSE, quote=FALSE, append=TRUE, sep=',')
}

if (length(which(!query %in% manifest[,filename])) > 0) {
  write.table(cbind(query[!query %in% manifest[,filename]], 'Outcome Phenotype Not Found'), opt$error, row.names=FALSE, col.names=FALSE, quote=FALSE, append=TRUE, sep=',')
}

write.table(manifest[index[manifest[index,'population'] %in% pop],filename], opt$output, row.names=FALSE, col.names=FALSE, quote=FALSE)

write.table(manifest[index[manifest[index,'population'] %in% pop], cols_interest], opt$metadata, row.names=FALSE, sep='\t')

write.table(manifest[index[manifest[index,'population'] %in% pop], ], paste0(tools::file_path_sans_ext(opt$metadata), '_full.csv'), row.names=FALSE, sep='\t')

