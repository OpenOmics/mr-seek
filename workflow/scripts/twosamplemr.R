#ml R/4.2.0
#loadNamespace('mr.raps', lib.loc='/data/chenv3/mr-seek_tools/')
library(remotes)
library(optparse)
library(TwoSampleMR)
library(data.table)
library(dplyr)

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
    help="Database to download gwas from"),
  make_option(c("-c", "--clump"), action='store_true', default=FALSE,
    help="Run clumping on harmonised data"),
  make_option(c("--path"), type='character', action='store', default=NA,
    help="Path to where database files are saved"),
  make_option(c("--pval"), type='double', action='store', default=NA,
    help="P-value threshold used to filter outcome SNPs for Neale database"),
  make_option(c("--error"), type='character', action='store', default=NA,
    help="Error file to log any exposure or outcome files that failed")
)

opt <- parse_args(OptionParser(option_list=option_list))

process_exposure <- function(x) {
  exp <- read.table(x, header=TRUE, sep=',')
  #Will exposure data be pulled in from the instruments existing catalogue?
  #MRInstruments package?
  if (opt$exp_flag == "pqtl") {
    addition <- as.data.frame(stringr::str_split(exp[,1], ':', simplify = T))[,1:4]
    colnames(addition) <- c("Chromosome", "hg37_genpos", "A0", "A1")
    exp <- cbind(exp, addition)
    discovery <- grep('discovery', colnames(exp), ignore.case=TRUE, value=TRUE)

    exposure_dat <- format_data(exp, type="exposure",
                                snp_col = "rsID",
                                beta_col = grep('BETA', discovery, ignore.case=TRUE, value=TRUE)[[1]],
                                se_col = grep('SE', discovery, ignore.case=TRUE, value=TRUE)[[1]],
                                eaf_col = grep('A1FREQ', discovery, ignore.case=TRUE, value=TRUE)[[1]],
                                effect_allele_col = "A1",
                                other_allele_col = "A0",
                                chr_col = 'Chromosome',
                                pos_col = 'hg37_genpos',
                                pval_col = grep('log10', discovery, ignore.case=TRUE, value=TRUE),
                                log_pval = TRUE)
    exposure_dat$id.exposure <- tools::file_path_sans_ext(basename(x))
  }else if (opt$exp_flag == "template1") {
    addition <- as.data.frame(stringr::str_split(exp[,'SNP'], ':', simplify=T))[,1:5]
    colnames(addition) <- c("Chromosome", "hg38_genpos", "A0", "A1", "RSID")
    exp <- cbind(exp, addition)
    exp$SE <- exp[,grep('Fx', colnames(exp), ignore.case=TRUE, value=TRUE)] / exp$T
    exp$log10P <- -exp$log10P
    exposure_dat <- format_data(exp, type="exposure",
                                snp_col = grep("RSID", colnames(exp), ignore.case=TRUE, value=TRUE)[[length(grep("RSID", colnames(exp), ignore.case=TRUE, value=TRUE))]],
                                beta_col = grep('Fx', colnames(exp), ignore.case=TRUE, value=TRUE)[[1]],
                                se_col = grep('^SE', colnames(exp), ignore.case=TRUE, value=TRUE)[[1]],
                                eaf_col = grep('EAF', colnames(exp), ignore.case=TRUE, value=TRUE)[[1]],
                                effect_allele_col = "A1",
                                other_allele_col = "A0",
                                chr_col = 'Chromosome',
                                pos_col = 'hg38_genpos',
                                pval_col = grep('log10', colnames(exp), ignore.case=TRUE, value=TRUE),
                                log_pval = TRUE)
    exposure_dat$id.exposure <- tools::file_path_sans_ext(basename(x))
  }else if (dim(exp)[[2]] == 1) {
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
  } else {
    print("Current exposure input format not handled, please double-check input or reach out for assistance")
    stop("Current exposure input format not handled, please double-check input or reach out for assistance")
  }
  return(exposure_dat)
}


exp_files <- strsplit(opt$exp, ',')[[1]]
exp_files <- unique(exp_files)
exposure_dat <- c()
for (filename in exp_files) {
  print(filename)
  tryCatch({
    exposure_dat <- rbind(exposure_dat, process_exposure(filename))
  }, error=function(cond) {
    write.table(cbind(basename(filename), 'Problem Loading Exposure File for MR'), opt$error, row.names=FALSE, col.names=FALSE, quote=FALSE, append=TRUE, sep=',')
  })
}

if (opt$clump) {
  exposure_dat <- clump_data(
    exposure_dat,
    clump_kb = 10000,
    clump_r2 = 0.001,
    clump_p1 = 1,
    clump_p2 = 1,
    pop = opt$pop
  )
}

exp_snp_list <- list()
exp_snp_list$rsid <- exposure_dat$SNP
exp_snp_list$custom <- tolower(paste(exposure_dat$chr.exposure, exposure_dat$pos.exposure, exposure_dat$other_allele.exposure, exposure_dat$effect_allele.exposure, sep='_'))
exp_snp_list <- as.data.frame(exp_snp_list)
exp_snp_list <- exp_snp_list %>%  distinct(.keep_all = TRUE)

#if (opt$database == 'neale'){
#  rownames(exp_snp_list) <- exp_snp_list$rsid
#  exposure_dat$SNP <- exp_snp_list[exposure_dat$SNP,'custom']
#}

if (opt$database == 'neale'){
  outcome_dat <- c()
  #files <- strsplit(opt$out, ',')[[1]]
  #files <- unique(files)

  out <- read.table(opt$out)
  files <- sapply(out, function(x) paste0(x, '.rsid.tsv.gz'))
  print(files)
  for (filename in files) {
    tryCatch({
    #data <- fread(filename)
    data <- fread(file.path(opt$path, filename))
    print(filename)

    if (!is.na(opt$pval)) {
      data <- data[which(data[[paste0('pval_', opt$pop)]]  < log(opt$pval)),]
    }

    data[[paste0('pval_', opt$pop)]] <- exp(data[[paste0('pval_', opt$pop)]])
    af <- grep(opt$pop, grep('af', colnames(data), value=TRUE), value=TRUE)
    if (length(af) == 2) {
        af <- grep('cases', af, value=TRUE)
    }
    #data$custom_id <- paste(data$chr, data$pos, data$ref, data$alt, sep='_')

    #Split output rsids
    out_rsid <- stringr::str_split(data$rsid, ',', simplify=TRUE)
    #Find all matching rsids
    temp <- sapply(1:dim(out_rsid)[2], function(x) match(exposure_dat$SNP, out_rsid[,x]))
    #Get location of all matching rsids and the input row they belong to
    match_id <- sapply(which(rowSums(!is.na(temp)) > 0), function(x) temp[x,!is.na(temp[x,])][[1]])
    names(match_id) <- which(rowSums(!is.na(temp)) > 0)
    no_match <- which(rowSums(!is.na(temp)) == 0)
    data_subset <- data[match_id,]
    data_subset$rsid_new <- exposure_dat$SNP[as.integer(names(match_id))]

    out_data <- format_data(data_subset, type="outcome", snp_col="rsid_new",
        beta_col=paste0("beta_", opt$pop), se_col=paste0("se_", opt$pop),
        eaf_col=paste0(af), effect_allele_col="alt",
        other_allele_col="ref", pval_col = paste0("pval_", opt$pop))
    #print(head(out_data))
    out_data$outcome <- strsplit(basename(filename), '\\.')[[1]][[1]]
    out_data$id.outcome <- strsplit(basename(filename), '\\.')[[1]][[1]]
    outcome_dat <- rbind(outcome_dat, out_data[out_data$SNP %in% exposure_dat$SNP,])
  }, error=function(cond) {
    write.table(cbind(basename(filename), 'Problem Loading Neale Phenotype for MR'), opt$error, col.names=FALSE, quote=FALSE, append=TRUE, sep=',')
  })}
} else if (opt$database == 'ieu') {
  out <- read.table(opt$out)
  if (dim(out)[[2]] == 1) {
    # Get effects of instruments on outcome
    outcome_dat = extract_outcome_data(
      snps = exposure_dat$SNP, # Array of SNP rs IDs.
      outcomes = out[[1]], # Array of IDs (see id column in output from available_outcomes).
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


#if (opt$database == 'neale'){
#  rownames(exp_snp_list) <- exp_snp_list$custom
#  dat$SNP <- exp_snp_list[dat$SNP, 'rsid']
#}

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

write.table(dat, 'harmonised_dat.tsv', sep='\t', row.names=FALSE)
write.table(res, 'res.tsv', sep='\t', row.names=FALSE)


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

write.table(het, 'mr_heterogeneity.tsv', sep='\t', row.names=FALSE)

ptm <- proc.time()
comparisons <- names(which(table(paste(dat$id.exposure, dat$id.outcome)) >= 3))
filtered <- do.call(rbind, lapply(comparisons, getdata))
filtered <- filtered[as.character(sort(as.integer(rownames(filtered)))),]
pleio_filtered <- mr_pleiotropy_test(filtered)
proc.time() - ptm
write.table(pleio_filtered[!is.na(pleio_filtered$se),], 'mr_pleiotropy.tsv', sep='\t', row.names=FALSE)

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
write.table(res_single, 'res_single.tsv', sep='\t', row.names=FALSE)

try({
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
})

## Leave one out analysis
res_loo <- mr_leaveoneout(dat)
write.table(res_loo, 'res_loo.tsv', sep='\t', row.names=FALSE)
try({
  dir.create(file.path('leaveoneout'), showWarnings = FALSE)
  p3 <- mr_leaveoneout_plot(res_loo)
  for (i in names(p3)) {
    png(file.path('leaveoneout', paste0(i, '.png')))
    print(p3[[i]])
    dev.off()
  }
})

## Funnel plot
try({
  p4 <- mr_funnel_plot(res_single)
  dir.create(file.path('singlesnp_funnel'), showWarnings = FALSE)
  for (i in names(p4)) {
    png(file.path('singlesnp_funnel', paste0(i, '.png')))
    print(p4[[i]])
    dev.off()
  }
})

sink('twosamplemr_session.log')
sessionInfo()
sink()
