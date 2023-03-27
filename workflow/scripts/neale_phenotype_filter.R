library(readr)
library(optparse)
library(dplyr)

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
manifest[filename] <- sapply(manifest[filename], function(x) gsub('.tsv.bgz', '', x))

headers[headers == filename] <- 'outcome.id'
colnames(manifest) <- headers
filename <- 'outcome.id'

cols_interest <- c('outcome.id', 'trait_type', 'phenocode', 'pheno_sex', 'coding', 'description', 'description_more', 'coding_description', 'category', 'n_cases_full_cohort_both_sexes', 'n_cases_full_cohort_females', 'n_cases_full_cohort_males', 'n_cases_AFR', 'n_cases_AMR', 'n_cases_CSA', 'n_cases_EAS', 'n_cases_EUR', 'n_cases_MID', 'n_controls_AFR', 'n_controls_AMR', 'n_controls_CSA', 'n_controls_EAS', 'n_controls_EUR', 'n_controls_MID')

manifest <- as.data.frame(manifest)
rownames(manifest) <- manifest[,filename]
query <- read.table(opt$query)[[1]]
query <- gsub('.tsv.bgz', '', query)

index <- which(manifest[,filename] %in% query)

if (!file.exists(opt$error)) {
  write.table(t(c('File', 'Error')), opt$error, row.names=FALSE, col.names=FALSE, quote=FALSE, sep=',')
}

if (length(which(!query %in% manifest[,filename])) > 0) {
  write.table(cbind(query[!query %in% manifest[,filename]], 'Outcome Phenotype Not Found'), opt$error, col.names=FALSE, quote=FALSE, append=TRUE, sep=',')
}

if (sum(rowSums(manifest[index,grep('^n_', grep(opt$pop, headers, value=TRUE), value=TRUE)], na.rm=TRUE) == 0)) {
  write.table(cbind(manifest[query[rowSums(manifest[index,grep('^n_', grep(opt$pop, headers, value=TRUE), value=TRUE)], na.rm=TRUE) == 0], filename], 'Population Missing'), opt$error, col.names=FALSE, quote=FALSE, append=TRUE, sep=',')
}

write.table(manifest[query[rowSums(manifest[index,grep('^n_', grep(opt$pop, headers, value=TRUE), value=TRUE)], na.rm=TRUE) > 0], filename], opt$output, row.names=FALSE, col.names=FALSE, quote=FALSE)

write.table(manifest[query[rowSums(manifest[index,grep('^n_', grep(opt$pop, headers, value=TRUE), value=TRUE)], na.rm=TRUE) >0], cols_interest], opt$metadata, row.names=FALSE, sep='\t')

write.table(manifest[query[rowSums(manifest[index,grep('^n_', grep(opt$pop, headers, value=TRUE), value=TRUE)], na.rm=TRUE) >0], ] %>% relocate(!!filename), paste0(tools::file_path_sans_ext(opt$metadata), '_full.csv'), row.names=FALSE, sep='\t')
