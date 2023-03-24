library(readr)
library(optparse)

option_list <- list(
  make_option(c("-q", "--query"), type='character', action='store', default=NA,
              help = "File containing the query terms used to extract phenotypes"),
  #make_option(c("-p", "--pop"), type='character', action='store', default='EUR',
  #            help = "Population used for downstream analysis, phenotypes extracted only if contains provided population. Default value is EUR"),
  make_option(c("-m", "--manifest"), type='character', action='store', default=NA,
              help = "Pan-UK Biobank phenotype manifest file"),
  make_option(c("-o", "--output"), type='character', action='store', default='neale_input.txt',
              help = "Output file name"),
  #make_option(c("-e", "--error"), type='character', action='store', default="extract_phenotype.error",
  #            help = "Error file name"),
  make_option(c("--metadata"), type='character', action='store', default="phenotype_metadata.tsv",
              help = "Phenotype metadata file name")
)

opt <- parse_args(OptionParser(option_list=option_list))


manifest <- read_tsv(opt$manifest)
headers <- colnames(manifest)
filename <- grep('tabix', grep('filename', headers, ignore.case=TRUE, value=TRUE), ignore.case=TRUE, value=TRUE, invert=TRUE)
query <- read.table(opt$query, sep='\t')[[1]]

get_populated_rows <- function(query) {
  names <- c()
  for (i in c("phenocode", "description")) {
    names <- c(names, grep(i, headers, ignore.case=TRUE))
  }
  rows <- c()
  for (i in names) {
    rows <- c(rows, grep(query, manifest[[i]], ignore.case=TRUE))
  }
  rows <- sort(unique(rows))
  return(rows)
}

all_results <- c()
for(i in query) {
  all_results <- c(all_results, get_populated_rows(i))
}
all_results <- sort(unique(all_results))

write.table(manifest[all_results, filename], opt$output, row.names=FALSE, col.names=FALSE, quote=FALSE)

write.table(manifest[all_results, ], opt$metadata, row.names=FALSE, col.names=FALSE, quote=TRUE, sep='\t')

#write.table(manifest[all_results[rowSums(manifest[all_results,grep('^n_', grep(opt$pop, headers, value=TRUE), value=TRUE)], na.rm=TRUE) == 0], filename], opt$error, row.names=FALSE, col.names=FALSE, quote=FALSE)

#write.table(manifest[all_results[rowSums(manifest[all_results,grep('^n_', grep(opt$pop, headers, value=TRUE), value=TRUE)], na.rm=TRUE) > 0], filename], opt$output, row.names=FALSE, col.names=FALSE, quote=FALSE)

#write.table(manifest[all_results[rowSums(manifest[all_results,grep('^n_', grep(opt$pop, headers, value=TRUE), value=TRUE)], na.rm=TRUE) >0], ], opt$metadata, row.names=FALSE, sep='\t')
