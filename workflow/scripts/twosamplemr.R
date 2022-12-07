#ml R/4.2.0
library(remotes)
library(optparse)
library(TwoSampleMR)
library(data.table)

option_list <- list(
  make_option(c("-w", "--workdir"), type='character', action='store', default=NA,
    help="Path to the working directory"),
  make_option(c("-e", "--exp"), type='character', action='store', default=NA,
    help="Exposure file"),
  make_option(c("-o", "--out"), type='character', action='store', default=NA,
    help="Outcome file"),
  make_option(c("-p", "--pop"), type='character', action='store', default="EUR",
    help="Reference super-population"),
  make_option(c("-f", "--exp_flag"), type='character', action='store', default=NA,
    help="Format for exposure file"),
  make_option(c("-d", "--database"), type='character', action='store', default=NA,
    help="Database to download gwas from")
)

opt <- parse_args(OptionParser(option_list=option_list))

exp <- read.table(opt$exp, header=TRUE, sep=',')
#Will exposure data be pulled in from the instruments existing catalogue?
#MRInstruments package?
if (dim(exp)[[2]] == 1) {
  # Get instruments or SNPs: This function searches for GWAS significant SNPs (for a given p-value) for a specified set of outcomes. It then performs LD based clumping to return only independent significant associations.
  exposure_dat = extract_instruments(
    outcomes = exp[[1]], # Array of outcome IDs (see available_outcomes)
    p1 = 5e-08, # Significance threshold. The default is 5e-8
    clump = TRUE, # Logical; whether to clump results. The default is TRUE
    p2 = 5e-08, # Secondary clumping threshold. The default is 5e-8
    r2 = 0.001, # Clumping r2 cut off. The default is 0.001
    kb = 10000, # Clumping distance cutoff. The default is 10000
    access_token = ieugwasr::check_access_token(), #Google OAuth2 access token. Used to authenticate level of access to data. The default is ieugwasr::check_access_token()
    force_server = FALSE #Force the analysis to extract results from the server rather than the MRInstruments package
  )
}else if (opt$exp_flag == "pqtl") {
  exp$Chromosome <- sapply(exp[,1], function(x) strsplit(x, ':')[[1]][[1]])
  exp$hg37_genpos <- sapply(exp[,1], function(x) strsplit(x, ':')[[1]][[2]])
  exp$A0 <- sapply(exp[,1], function(x) strsplit(x, ':')[[1]][[3]])
  exp$A1 <- sapply(exp[,1], function(x) strsplit(x, ':')[[1]][[4]])

  exposure_dat <- format_data(exp, type="exposure",
                              snp_col = "rsID",
                              beta_col = "BETA_discovery",
                              se_col = "SE_discovery",
                              eaf_col = "A1FREQ_discovery",
                              effect_allele_col = "A1",
                              other_allele_col = "A0")
  exposure_dat$id.exposure <- tools::file_path_sans_ext(basename(opt$exp))
}

if (opt$database == 'neale'){
  outcome_dat <- c()
  files <- strsplit(opt$out, ',')[[1]]
  print(files)
  for (filename in files) {
    data <- fread(filename)
    print(filename)
    #save.image('test.RData')
    out_data <- format_data(data, type="outcome", snp_col="rsid",
        beta_col=paste0("beta_", opt$pop), se_col=paste0("se_", opt$pop),
        eaf_col=paste0("af_", opt$pop), effect_allele_col="alt",
        other_allele_col="ref", pval_col = paste0("pval_", opt$pop),
        log_pval=TRUE)
    #print(head(out_data))
    out_data$outcome <- strsplit(basename(filename), '\\.')[[1]][[1]]
    out_data$id.outcome <- strsplit(basename(filename), '\\.')[[1]][[1]]
    outcome_dat <- rbind(outcome_dat, out_data)
  }
} else {
  out <- read.table(out_file, header=TRUE)
  if (dim(out)[[2]] == 1) {
    # Get effects of instruments on outcome
    outcome_dat = extract_outcome_data(
      snps = exposure_dat$SNP, # Array of SNP rs IDs.
      outcomes = c("ieu-a-7", "ieu-a-10"), # Array of IDs (see id column in output from available_outcomes).
      proxies = TRUE, # Look for LD tags? Default is TRUE
      rsq = 0.8, #Minimum LD rsq value (if proxies = 1). Default = 0.8
      align_alleles = 1, #Try to align tag alleles to target alleles (if proxies = 1). 1 = yes, 0 = no. The default is 1
      palindromes = 1, #Allow palindromic SNPs (if proxies = 1). 1 = yes, 0 = no. The default is 1
      maf_threshold = 0.3, #MAF threshold to try to infer palindromic SNPs. The default is 0.3
      access_token = ieugwasr::check_access_token(), #Google OAuth2 access token. Used to authenticate level of access to data.
      splitsize = 10000,
      proxy_splitsize = 500
    )
  }
}


setwd(opt$workdir)

# Harmonise the exposure and outcome data
dat <- harmonise_data(
  exposure_dat, #Output from read_exposure_data.
  outcome_dat, #Output from extract_outcome_data
  action = 2) #Level of strictness in dealing with SNPs.
            #  action = 1: Assume all alleles are coded on the forward strand, i.e. do not attempt to flip alleles
            #  action = 2: Try to infer positive strand alleles, using allele frequencies for palindromes (default, conservative);
            #  action = 3: Correct strand for non-palindromic SNPs, and drop all palindromic SNPs from the analysis (more conservative). If a single value is passed then this action is applied to all outcomes.
            # But multiple values can be supplied as a vector, each element relating to a different outcome.

#clumped <- clump_data(
#  dat,
#  clump_kb = 10000,
#  clump_r2 = 0.001,
#  clump_p1 = 1,
#  clump_p2 = 1,
#  pop = pop
#)

# Perform MR
res <- mr(dat, #Harmonised exposure and outcome data. Output from harmonise_data.
          parameters = default_parameters(), #Parameters to be used for various MR methods. Default is output from default_parameters
          method_list = subset(mr_method_list(), use_by_default)$obj ) #List of methods to use in analysis. See mr_method_list for details.
#dim(res) 5 x 9
#default_parameters() = The default is list(test_dist = "z", nboot = 1000, Cov = 0, penk = 20, phi = 1, alpha = 0.05, Qthresh = 0.05, over.dispersion = TRUE, loss.function = "huber").
#mr_method_list()$name
# [1] "Wald ratio"
# [2] "Maximum likelihood"
# [3] "MR Egger"
# [4] "MR Egger (bootstrap)"
# [5] "Simple median"
# [6] "Weighted median"
# [7] "Penalised weighted median"
# [8] "Inverse variance weighted"
# [9] "IVW radial"
# [10] "Inverse variance weighted (multiplicative random effects)"
# [11] "Inverse variance weighted (fixed effects)"
# [12] "Simple mode"
# [13] "Weighted mode"
# [14] "Weighted mode (NOME)"
# [15] "Simple mode (NOME)"
# [16] "Robust adjusted profile score (RAPS)"
# [17] "Sign concordance test"
# [18] "Unweighted regression"
#

write.table(dat, 'harmonised_dat.csv', sep=',', row.names=FALSE)
write.table(res, 'res.csv', sep=',', row.names=FALSE)


getdata <- function(x) {
  ids <- strsplit(x, ' ')[[1]]
  return(dat[which(dat$id.exposure == ids[1] & dat$id.outcome == ids[2]),])
}
#ptm <- proc.time()
#comparisons <- names(which(table(paste(dat$id.exposure, dat$id.outcome)) >= 2))
#filtered <- do.call(rbind, lapply(comparisons, getdata))
#filtered <- filtered[as.character(sort(as.integer(rownames(filtered)))),]
#het_filtered <- mr_heterogeneity(filtered)
#proc.time() - ptm

#user  system elapsed
#17.463   0.016  17.482

ptm <- proc.time()
het <- mr_heterogeneity(dat)
proc.time() - ptm

#user  system elapsed
#17.020   0.025  17.100

write.table(het, 'mr_heterogeneity.csv', sep=',', row.names=FALSE)

ptm <- proc.time()
comparisons <- names(which(table(paste(dat$id.exposure, dat$id.outcome)) >= 3))
filtered <- do.call(rbind, lapply(comparisons, getdata))
filtered <- filtered[as.character(sort(as.integer(rownames(filtered)))),]
pleio_filtered <- mr_pleiotropy_test(filtered)
proc.time() - ptm
write.table(pleio_filtered[!is.na(pleio_filtered$se),], 'mr_pleiotropy.csv', sep=',', row.names=FALSE)

#ptm <- proc.time()
#pleio <- mr_pleiotropy_test(dat)
#proc.time() - ptm

### Scatter plot
p1 <- mr_scatter_plot(res, dat)
dir.create(file.path('scatterplot'), showWarnings = FALSE)
for (i in names(p1)) {
  png(file.path('scatterplot', paste0(i, '.png')))
  print(p1[[i]])
  dev.off()
}


### Forest plot compare the MR estimates using the different MR methods against the single SNP tests.
res_single <- mr_singlesnp(dat)
write.table(res_single, 'res_single.csv', sep=',', row.names=FALSE)

p2 <- mr_forest_plot(res_single)
dir.create(file.path('singlesnp_forest'), showWarnings = FALSE)
for (i in names(p2)) {
  ids <- strsplit(i, '\\.')[[1]]
  if (length(which(res_single[,'id.exposure'] == ids[1] & res_single[, 'id.outcome'] == ids[2])) > 3) {
    png(file.path('singlesnp_forest', paste0(i, '.png')))
    print(p2[[i]])
    dev.off()
  }
}
