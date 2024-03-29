library(MRPlotly)
library(TwoSampleMR)
library(optparse)

option_list = list(
  make_option(c('-r', '--res'), action = 'store', default = NA, type = 'character', help = 'Result TSV file from TwoSampleMR'),
  make_option(c('-s', '--single'), action = 'store', default = NA, type = 'character', help = 'Single SNP results from TwoSampleMR'),
  make_option(c('-l', '--loo'), action = 'store', default = NA, type = 'character', help = 'Leave one out results from TwoSampleMR'),
  make_option(c('--heterogeneity'), action = 'store', default = NA, type='character', help = 'Heterogeneity results from TwoSampleMR'),
  make_option(c('-p', '--pleiotropy'), action = 'store', default = NA, type='character', help = 'Pleiotropy results from TwoSampleMR'),
  make_option(c('-d', '--data'), action = 'store', default = NA, type = 'character', help = 'Harmonized data. Needed to get the exposure and outcome names.'),
  make_option(c('-m', '--metadata'), action = 'store', default = NA, type = 'character', help = 'Filtered metadata information for each of the outcome phenotypes'),
  make_option(c('--manifest'), action = 'store', default = NA, type = 'character', help = 'Database phenotype manifest files. Comma delimited string containing path to the full phenotype manifest files available'),
  make_option(c('--manifest_name'), action = 'store', default = "Pan-UKBB,ieuGWAS", type = 'character', help = 'Database names corresponding to the provided phenotype manifest files'),
  make_option(c('-o','--out'), action = 'store', default = 'all_plots.rds', type = 'character', help = 'Output file name with .rds extension'),
  make_option(c('-f', '--failed'), action = 'store', default = NA, type = 'character', help = 'CSV or TSV file containing information about failed runs'),
  make_option(c('-v', '--version'), action = 'store', default = NA, type = 'character', help = 'Software version used generated by sessionInfo'),
  make_option(c("--include_data"), action = 'store_true', default = FALSE, type='logical', help = 'Whether or not to include data outputted from TwoSampleMR'),
  make_option(c("--dashboard"), action='store_true', default = 'dashboard', type = 'character', help = 'Name of dashboard to be created')
)

opt = parse_args(OptionParser(option_list = option_list))
opt$manifest <- strsplit(opt$manifest, ',')[[1]]
opt$manifest_name <- strsplit(opt$manifest_name, ',')[[1]]

all.mr.plotly(res = opt$res, res_single = opt$single, res_loo = opt$loo, dat = opt$data, out = opt$out, failed = opt$failed, version = opt$version, include_data = opt$include_data, heterogeneity = opt$heterogeneity, pleiotropy = opt$pleiotropy, pheno_data = opt$metadata, avail_pheno = opt$manifest, avail_pheno_names = opt$manifest_name)

make.dashboard(opt$dashboard)
