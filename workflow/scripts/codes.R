library(tidyverse)
library(TwoSampleMR)
library(optparse)

option_list = list(
  make_option(c('-r', '--res'), action = 'store', default = NA, type = 'character', help = 'Result CSV file from TwoSampleMR'),
  make_option(c('-s', '--single'), action = 'store', default = NA, type = 'character', help = 'Single SNP results from TwoSampleMR'),
  make_option(c('-d', '--data'), action = 'store', default = NA, type = 'character', help = 'Harmonized data. Needed to get the exposure and outcome names.'),
  make_option(c('-o','--out'), action = 'store', default = 'all_plots.rds', type = 'character', help = 'Output file name with .rds extension')
)

opt = parse_args(OptionParser(option_list = option_list))

##########################################
# Function to PlotlyFy the Funnel Plot
##########################################

blank_plot <- function(message)
{
  requireNamespace("ggplot2", quietly=TRUE)
  ggplot2::ggplot(data.frame(a=0,b=0,n=message)) + ggplot2::geom_text(ggplot2::aes(x=a,y=b,label=n)) + ggplot2::labs(x=NULL,y=NULL) + ggplot2::theme(axis.text=ggplot2::element_blank(), axis.ticks=ggplot2::element_blank())
}

my_singlenp_funnel_plot<-function(plot_data){
  if (sum(!grepl("All", plot_data$SNP)) < 2) {
    return(blank_plot("Insufficient number of SNPs"))
  }  
  am = grep('All', plot_data$SNP, value = T)
  plot_data$SNP = gsub('All - ', '', plot_data$SNP)
  am <- gsub("All - ", "", am)

  fig = plotly::ggplotly(ggplot(data = plot_data[!plot_data$SNP%in%am, ], aes(x = b, y = 1/se, text = paste0('β: ', round(b,4), '\nSE: ', round(se, 4) ,'\n','SNP: ', SNP)))+
                           geom_point()+
                           geom_vline(data = plot_data[plot_data$SNP%in%am, ], aes(xintercept = b, color = SNP)) + 
                           scale_colour_manual(name = 'MR Method',values = c("#a6cee3",  "#1f78b4", "#b2df8a", "#33a02c", "#fb9a99",  "#e31a1c", "#fdbf6f", "#ff7f00", "#cab2d6", "#6a3d9a", "#ffff99", "#b15928"))+
                           ggpubr::theme_pubr()+
                           labs(x = 'β'), tooltip = 'text'
  )
  
  return(fig)
  
}

my_all_funnel_plots<-function(res_single){
  plot_names = expand.grid(exposures = unique(res_single$id.exposure), outcomes = unique(res_single$id.outcome))
  plot_names$names = paste(plot_names$exposures, plot_names$outcomes, sep = '.')  
  
  funnel_plots<-list()
  for(i in 1:nrow(plot_names)){
    funnel_plots[[plot_names$names[i]]] <- my_singlenp_funnel_plot(
      res_single%>%dplyr::filter(id.exposure == plot_names$exposures[i] & id.outcome == plot_names$outcomes[i])
    )  
  }
  return(funnel_plots)
}



##########################
# Make rds of all plots
###########################

res<-read_csv(opt$res)
dat<-read_csv(opt$data)
res_single<-read_csv(opt$single)

all_plots<-list()
### Scatter plot
all_plots$Scatter <- mr_scatter_plot(res, dat)

### Forest plot
all_plots$Forest <- mr_forest_plot(res_single)

## Leave one out analysis
res_loo <- mr_leaveoneout(dat)
all_plots$LOO <- mr_leaveoneout_plot(res_loo)

## Funnel plot
all_plots$Funnel <- mr_funnel_plot(res_single)


all_plots$Funnel_plotly = my_all_funnel_plots(res_single)


saveRDS(all_plots, opt$out)
