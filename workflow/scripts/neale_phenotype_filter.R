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
filename <- grep('tabix', grep('filename', headers, ignore.case=TRUE, value=TRUE), ignore.case=TRUE, value=TRUE, invert=TRUE)
manifest <- as.data.frame(manifest)
rownames(manifest) <- manifest[,filename]
query <- read.table(opt$query)[[1]]

index <- which(manifest[,filename] %in% query)

if (!file.exists(opt$error)) {
  write.table(c('File', 'Error'), opt$error, row.names=FALSE, col.names=FALSE, quote=FALSE, sep='\t')
}

write.table(cbind(manifest[query[rowSums(manifest[query,grep('^n_', grep(opt$pop, headers, value=TRUE), value=TRUE)], na.rm=TRUE) == 0], filename], 'Population Missing'), opt$error, col.names=FALSE, quote=FALSE, append=TRUE, sep=',')

write.table(manifest[query[rowSums(manifest[query,grep('^n_', grep(opt$pop, headers, value=TRUE), value=TRUE)], na.rm=TRUE) > 0], filename], opt$output, row.names=FALSE, col.names=FALSE, quote=FALSE)

write.table(manifest[query[rowSums(manifest[query,grep('^n_', grep(opt$pop, headers, value=TRUE), value=TRUE)], na.rm=TRUE) >0], ], opt$metadata, row.names=FALSE, sep='\t')
