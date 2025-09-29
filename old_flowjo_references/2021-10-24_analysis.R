parentdir <- '/Users/chsiung/ARC Institute Dropbox/Chris Hsiung/Cas12a/Flow/2021-10-24_chsiung_Exp1-K562-pCH38-MOI-Day6'

flowjoexportdir <- file.path( parentdir, 'flowjoexport' )
figdir <- file.path( parentdir, 'Figures')
outputdir <- file.path( parentdir, 'output')
library(readr)
library(stringr)
library(dplyr)
library(data.table)
library(ggplot2)
#library(bestNormalize)
library(tidyr)

gfpdt <- fread( file.path( flowjoexportdir, 'GFPpos_combodf.txt') ) %>%
   filter( `RL1-A` > 0 & `VL1-A` > 0 & `YL1-A` > 0 & `BL1-A` > 0 ) # remove zero signal events

p3dt <- fread( file.path( flowjoexportdir, 'P3_combodf.txt')) %>%
   filter( `RL1-A` > 0 & `VL1-A` > 0 & `YL1-A` > 0 & `BL1-A` > 0) # remove zero signal events

# pCHID <- fread(file.path( parentdir, 'pCHIDs.txt'))

# gCHID <- fread(file.path(parentdir, 'gCHIDs.txt'))

gfpdt <- dplyr::mutate( gfpdt, log10_RL1A = log10(`RL1-A`),
                          log10_VL1A = log10(`VL1-A`),
                          log10_BL1A = log10(`BL1-A`),
                          log10_YL1A = log10(`YL1-A`),
                          log2_RL1A = log2(`RL1-A`),
                          log2_VL1A = log2(`VL1-A`),
                          log2_BL1A = log2(`BL1-A`),
                          log2_YL1A = log2(`YL1-A`),
                        Cells = 'K562',
                        pCHID = 'holder',
                        Description = 'holder'
) %>%
   # left_join( . , pCHID, by = 'pCHID') %>%
   # left_join( . , gCHID, by = 'gCHID' ) %>%
   dplyr::mutate(
      Backbone2 = ifelse( Backbone == 'pRG212', 'CROPseq+3pDRWT', 'other' ),
      Backbone2 = ifelse( Backbone == 'pCH39', 'U6+3pDR8', Backbone2),
      Backbone2 = ifelse( Backbone == 'pCH38', 'EF1alpha+3pDR8+bglobpolyA', Backbone2 ),
      Backbone2 = ifelse( Backbone == 'uninfected', 'uninfected', Backbone2 )
   )


p3dt <- dplyr::mutate( p3dt, 
              log10_RL1A = log10(`RL1-A`),
               log10_VL1A = log10(`VL1-A`),
               log10_BL1A = log10(`BL1-A`),
               log10_YL1A = log10(`YL1-A`),
               log2_RL1A = log2(`RL1-A`),
               log2_VL1A = log2(`VL1-A`),
               log2_BL1A = log2(`BL1-A`),
               log2_YL1A = log2(`YL1-A`),
               Cells = 'K562',
               pCHID = 'holder',
               Description = 'holder'
) %>%
  # left_join( . , pCHID, by = 'pCHID') %>%
  # left_join( . , gCHID, by = 'gCHID' ) %>%
  dplyr::mutate(
    Backbone2 = ifelse( Backbone == 'pRG212', 'CROPseq+3pDRWT', 'other' ),
    Backbone2 = ifelse( Backbone == 'pCH39', 'U6+3pDR8', Backbone2),
    Backbone2 = ifelse( Backbone == 'pCH38', 'EF1alpha+3pDR8+bglobpolyA', Backbone2 ),
    Backbone2 = ifelse( Backbone == 'uninfected', 'uninfected', Backbone2 )
  )


GFPthres <- quantile( subset( p3dt, Spacer == 'uninfected')$`log10_BL1A`, 0.999)


## pool summary across Stains
p3_summarydt <- group_by( p3dt, Sample, Spacer, Backbone2, gCHID, crRNAMOI ) %>%
  dplyr::summarise(
    percGFPon = round( sum( log10_BL1A > GFPthres )/n()*100, 1)
  )
  
  
# factordf <- dplyr::select( gfpdt, pCHID, Description) %>%
#    dplyr::mutate(
#       pCHnumeric = as.numeric( str_replace( gfpdt$pCHID, 'pCH', '' ))
#    ) %>%
#    dplyr::arrange( pCHnumeric )

# gfpdt$Description <- factor( gfpdt$Description, levels = unique( factordf$Description ) )

# gfpdt$pCHID <- factor( gfpdt$pCHID, levels = unique( factordf$pCHID))



write.table( gfpdt, file.path( outputdir, '2021-10-24_allgfpdf.txt'), col.names = TRUE, row.names = FALSE, quote = FALSE, sep = '\t' )

#######


## CD151
cd151dt <- filter( gfpdt, Stain == 'CD151-APC + CD55-PE' & grepl( 'CD151|NT-3', Spacer ) )

cd151_summarydt <- dplyr::group_by( cd151dt, Sample, Cells, Spacer, Backbone2, gCHID, crRNAMOI ) %>%
   dplyr::summarise(
      lower5perc_log10RL1A = quantile( log10_RL1A, 0.05, na.rm = TRUE ),
      spearmanrho_CD151vGFP = cor.test( log10_RL1A, log10_BL1A, method = 'spearman' )$estimate,
      spearmanrho_CD151vBFP = cor.test( log10_RL1A, log10_VL1A, method = 'spearman' )$estimate
   ) %>%
   ungroup()

cd151_NT3thres <- subset( cd151_summarydt, Spacer == 'NT-3') %>%
   dplyr::select( Cells, Backbone2, lower5perc_log10RL1A, crRNAMOI ) %>%
   unique()

cd151_summarydt2 <- left_join( cd151dt, cd151_NT3thres, by = c( 'Cells', 'Backbone2', 'crRNAMOI') ) %>%
   dplyr::mutate(
      cd151_status = ifelse( log10_RL1A <= lower5perc_log10RL1A, 'OFF', 'ON')
   ) %>%
   group_by( Cells, Backbone2, lower5perc_log10RL1A, gCHID, Spacer, crRNAMOI ) %>%
   dplyr::summarise (
      perc_cd151off = round( sum( cd151_status == 'OFF' )/length(cd151_status)*100, 1)
   )

# cd151_summarydt$Description <- factor( cd151_summarydt$Description, levels = unique( factordf$Description ) )
# cd151_summarydt$pCHID <- factor( cd151_summarydt$pCHID, levels = unique( factordf$pCHID))

# cd151_summarydt2$Description <- factor( cd151_summarydt2$Description, levels = unique( factordf$Description ) )
# cd151_summarydt2$pCHID <- factor( cd151_summarydt2$pCHID, levels = unique( factordf$pCHID))


## CD81
cd81dt <- filter( gfpdt, Stain == 'CD55-APC + CD81-PE' & grepl( 'CD81|NT-3', Spacer ) )

cd81_summarydt <- dplyr::group_by( cd81dt, Sample, Cells, Spacer, Backbone2, gCHID, crRNAMOI ) %>%
   dplyr::summarise(
      log10avrg_YL1A = log10( mean(`YL1-A`)),
      lower5perc_log10YL1A = quantile( log10_YL1A, 0.05, na.rm = TRUE ),
      spearmanrho_CD81vGFP = cor.test( log10_YL1A, log10_BL1A, method = 'spearman' )$estimate,
      spearmanrho_CD81vBFP = cor.test( log10_YL1A, log10_VL1A, method = 'spearman' )$estimate
   ) %>%
   ungroup()

cd81_NT3thres <- subset( cd81_summarydt, Spacer == 'NT-3') %>%
   dplyr::select( Cells, Backbone2, lower5perc_log10YL1A, crRNAMOI ) %>%
   unique()

cd81_summarydt2 <- left_join( cd81dt, cd81_NT3thres, by = c( 'Cells', 'Backbone2', 'crRNAMOI') ) %>%
   dplyr::mutate(
      cd81_status = ifelse( log10_YL1A <= lower5perc_log10YL1A, 'OFF', 'ON')
   ) %>%
   group_by( Cells, Backbone2, lower5perc_log10YL1A, gCHID, Spacer, crRNAMOI ) %>%
   dplyr::summarise (
      perc_cd81off = round( sum( cd81_status == 'OFF' )/length(cd81_status)*100, 1)
   )

# cd81_summarydt$Description <- factor( cd81_summarydt$Description, levels = unique( factordf$Description ) )
# cd81_summarydt$pCHID <- factor( cd81_summarydt$pCHID, levels = unique( factordf$pCHID))
# 
# cd81_summarydt2$Description <- factor( cd81_summarydt2$Description, levels = unique( factordf$Description ) )
# cd81_summarydt2$pCHID <- factor( cd81_summarydt2$pCHID, levels = unique( factordf$pCHID))

## CD55-APC
cd55APCdt <- filter( gfpdt, Stain == 'CD55-APC + CD81-PE' & grepl( 'CD55|NT-3', Spacer ) )

cd55APC_summarydt <- dplyr::group_by( cd55APCdt, Sample, Cells, Spacer, Backbone2, gCHID, crRNAMOI ) %>%
   dplyr::summarise(
      log10avrg_RL1A = log10( mean(`RL1-A`)),
      lower5perc_log10RL1A = quantile( log10_RL1A, 0.05, na.rm = TRUE ),
      spearmanrho_cd55vGFP = cor.test( log10_RL1A, log10_BL1A, method = 'spearman' )$estimate,
      spearmanrho_cd55vBFP = cor.test( log10_RL1A, log10_VL1A, method = 'spearman' )$estimate
   ) %>%
   ungroup()

cd55APC_NT3thres <- subset( cd55APC_summarydt, Spacer == 'NT-3') %>%
   dplyr::select( Cells, Backbone2, lower5perc_log10RL1A, crRNAMOI ) %>%
   unique()

cd55APC_summarydt2 <- left_join( cd55APCdt, cd55APC_NT3thres, by = c( 'Cells','Backbone2', 'crRNAMOI') ) %>%
   dplyr::mutate(
      cd55_status = ifelse( log10_RL1A <= lower5perc_log10RL1A, 'OFF', 'ON')
   ) %>%
   group_by( Cells, lower5perc_log10RL1A, gCHID, Spacer, Backbone2, crRNAMOI ) %>%  ## add Backbone2 as grouping variable here
   dplyr::summarise (
      perc_cd55off = round( sum( cd55_status == 'OFF' )/length(cd55_status)*100, 1)
   )

## CD55-PE

cd55PEdt <- filter( gfpdt, Stain == 'CD151-APC + CD55-PE' & grepl( 'CD55|NT-3', Spacer ) )

cd55PE_summarydt <- dplyr::group_by( cd55PEdt, Sample, Cells, Spacer, Backbone2, gCHID, crRNAMOI ) %>%
  dplyr::summarise(
    log10avrg_YL1A = log10( mean(`YL1-A`)),
    lower5perc_log10YL1A = quantile( log10_YL1A, 0.05, na.rm = TRUE ),
    spearmanrho_cd55vGFP = cor.test( log10_YL1A, log10_BL1A, method = 'spearman' )$estimate,
    spearmanrho_cd55vBFP = cor.test( log10_YL1A, log10_VL1A, method = 'spearman' )$estimate
  ) %>%
  ungroup()

cd55PE_NT3thres <- subset( cd55PE_summarydt, Spacer == 'NT-3') %>%
  dplyr::select( Cells, Backbone2, lower5perc_log10YL1A, crRNAMOI ) %>%
  unique()

cd55PE_summarydt2 <- left_join( cd55PEdt, cd55PE_NT3thres, by = c( 'Cells', 'Backbone2', 'crRNAMOI') ) %>%
  dplyr::mutate(
    cd55_status = ifelse( log10_YL1A <= lower5perc_log10YL1A, 'OFF', 'ON')
  ) %>%
  group_by( Cells, lower5perc_log10YL1A, gCHID, Spacer, Backbone2, crRNAMOI ) %>%  ## add Backbone2 as grouping variable here
  dplyr::summarise (
    perc_cd55off = round( sum( cd55_status == 'OFF' )/length(cd55_status)*100, 1)
  )

##

plotboxjitter <- function( df, xvar, yvar, alphavar, colorvar, fontsize = 15 ){
      plot <- ggplot() +
            geom_boxplot( data = df, aes_string( x = xvar, y = yvar, color = colorvar  ), width = 0.2, outlier.shape = NA, position = 'dodge' ) +
            geom_jitter( data = df, aes_string( x = xvar, y = yvar, color = colorvar ), alpha = alphavar, size = 0.5 ) +
         theme_bw( base_size = fontsize ) +
         theme( text = element_text(size = fontsize),
                legend.position = 'right',
                legend.direction = 'vertical',
                legend.text = element_text( size = rel(2)),
                plot.title = element_text(hjust = 0.5, size = rel(2)),
                axis.text.x = element_text(angle = 90, size = rel(2)),
                panel.background = element_blank()
         )

      return(plot)
}





setwd( figdir)# 


png( 'Boxjitter_CD55APC_log10RL1A.png', width = 11, height = 7, units = 'in', res = 300 )
p1 <- plotboxjitter( df = cd55APCdt, xvar = 'log10_RL1A', yvar = 'Spacer', alphavar = 0.05, colorvar = 'crRNAMOI', fontsize = 12) +
  geom_text( data = cd55APC_summarydt2, aes( y = Spacer, x = 1, label = paste0( perc_cd55off, '%') ), size = 8 ) +
  geom_vline( data = cd55APC_summarydt2, aes( xintercept = lower5perc_log10RL1A ), linetype = 'dashed' ) +
  facet_grid( crRNAMOI~Backbone2, scales = 'free_y' ) +
  theme( strip.text.x = element_text(size = 15)) +
  ggtitle( 'CD55-APC, K562 Day6 ')
print(p1)
dev.off()

png( 'Boxjitter_CD55PE_log10YL1A.png', width = 11, height = 7, units = 'in', res = 300 )
p1 <- plotboxjitter( df = cd55PEdt, xvar = 'log10_YL1A', yvar = 'Spacer', alphavar = 0.2, colorvar = 'crRNAMOI', fontsize = 12) +
  geom_text( data = cd55PE_summarydt2, aes( y = Spacer, x = 2, label = paste0( perc_cd55off, '%') ), size = 8 ) +
  geom_vline( data = cd55PE_summarydt2, aes( xintercept = lower5perc_log10YL1A ), linetype = 'dashed' ) +
  facet_grid( crRNAMOI~Backbone2, scales = 'free_y' ) +
  theme( strip.text.x = element_text(size = 15)) +
  ggtitle( 'CD55-PE, K562 Day6 ')
print(p1)
dev.off()

png( 'Boxjitter_CD81PE_log10YL1A.png', width = 13, height = 7, units = 'in', res = 300 )
p1 <- plotboxjitter( df = cd81dt, xvar = 'log10_YL1A', yvar = 'Spacer', alphavar = 0.2, colorvar = 'crRNAMOI', fontsize = 12) +
  geom_text( data = cd81_summarydt2, aes( y = Spacer, x = 2, label = paste0( perc_cd81off, '%') ), size = 8 ) +
  geom_vline( data = cd81_summarydt2, aes( xintercept = lower5perc_log10YL1A ), linetype = 'dashed' ) +
  facet_grid( crRNAMOI~Backbone2, scales = 'free_y' ) +
  theme( strip.text.x = element_text(size = 15)) +
  ggtitle( 'CD81-PE, K562 Day6 ')
print(p1)
dev.off()



png( 'Boxjitter_cd151_log10RL1A.png', width = 11, height = 7, units = 'in', res = 300 )
p1 <- plotboxjitter( df = cd151dt, xvar = 'log10_RL1A', yvar = 'Spacer', alphavar = 0.2, colorvar = 'crRNAMOI', fontsize = 12) +
   geom_text( data = cd151_summarydt2, aes( y = Spacer, x = 2, label = paste0( perc_cd151off, '%') ), size = 8 ) +
   geom_vline( data = cd151_summarydt2, aes( xintercept = lower5perc_log10RL1A ), linetype = 'dashed' ) +
   facet_grid( crRNAMOI~Backbone2, scales = 'free_y') +
  theme( strip.text.x = element_text(size = 15)) +
   ggtitle( 'cd151-APC, K562 Day6')
print(p1)
dev.off()


# make scatter plots for gfp, cd55/cd81

png('Scatter_CD55APCvGFP.png', width = 13, height = 10, units = 'in', res = 300 )

dftoplot <- cd55APCdt
dftoplot2 <- cd55APC_summarydt
p2 <- ggplot() +
   geom_point( data = dftoplot, aes( x = log10_BL1A, y = log10_RL1A, color = Backbone2 ), alpha = 0.75, size = 0.75 ) +
   geom_text( data = dftoplot2, aes( x = 5, y = 0.5, label = paste0( 'Rho = ', round( unique(spearmanrho_cd55vGFP), 2)) ) ) +
   facet_grid( Spacer~Backbone2+crRNAMOI ) +
   theme_bw( base_size = 12 ) +
   theme( legend.position = 'none',
          legend.direction = 'vertical',
          legend.text = element_text( size = rel(1.5)),
          plot.title = element_text(hjust = 0.5),
          axis.text.x = element_text(angle = 90),
          panel.background = element_blank()
   ) +
   ggtitle( 'CD55-APC vs. GFP, K562 Day6')
print(p2)
dev.off()



png('Scatter_CD55APCvBFP.png', width = 13, height = 10, units = 'in', res = 300 )

dftoplot <- cd55APCdt
dftoplot2 <- cd55APC_summarydt
p2 <- ggplot() +
  geom_point( data = dftoplot, aes( x = log10_VL1A, y = log10_RL1A, color = Backbone2 ), alpha = 0.75, size = 0.75 ) +
  geom_text( data = dftoplot2, aes( x = 5, y = 0.5, label = paste0( 'Rho = ', round( unique(spearmanrho_cd55vBFP), 2)) ) ) +
  facet_grid( Spacer~Backbone2+crRNAMOI ) +
  theme_bw( base_size = 12 ) +
  theme( legend.position = 'none',
         legend.direction = 'vertical',
         legend.text = element_text( size = rel(1.5)),
         plot.title = element_text(hjust = 0.5),
         axis.text.x = element_text(angle = 90),
         panel.background = element_blank()
  ) +
  ggtitle( 'CD55-APC vs. BFP, K562 Day6')
print(p2)
dev.off()


png('Scatter_CD55APCvCD81PE.png', width = 12, height = 6.5, units = 'in', res = 300 )

dftoplot <- subset( cd55APCdt, Backbone2 == 'U6+3pDR8')
dftoplot2 <- subset( cd55APC_summarydt, Backbone2 == 'U6+DR8')
p2 <- ggplot() +
  geom_point( data = dftoplot, aes( x = log10_YL1A, y = log10_RL1A, color = Backbone2 ), alpha = 0.15, size = 0.75 ) +
  # geom_text( data = dftoplot2, aes( x = 5, y = 0.5, label = paste0( 'Rho = ', round( unique(spearmanrho_cd55vGFP), 2)) ) ) +
  facet_grid( Backbone2+crRNAMOI~Spacer ) +
  theme_bw( base_size = 12 ) +
  theme( legend.position = 'none',
         legend.direction = 'vertical',
         legend.text = element_text( size = rel(1.5)),
         plot.title = element_text(hjust = 0.5),
         axis.text.x = element_text(angle = 90),
         panel.background = element_blank()
  ) +
  ggtitle( 'CD55-APC vs. CD81-PE, K562 Day6')
print(p2)
dev.off()


## when you have time, calculate odds ratio
# https://rdrr.io/cran/epitools/man/oddsratio.html


png('Scatter_CD55PEvCD151APC.png', width = 12, height = 8, units = 'in', res = 300 )

dftoplot <- subset( cd55PEdt, Backbone2 == 'U6+3pDR8')
dftoplot2 <- subset( cd55PE_summarydt, Backbone2 == 'U6+3pDR8')
p2 <- ggplot() +
  geom_point( data = dftoplot, aes( x = log10_RL1A, y = log10_YL1A, color = Backbone2 ), alpha = 0.15, size = 0.75 ) +
  # geom_text( data = dftoplot2, aes( x = 5, y = 0.5, label = paste0( 'Rho = ', round( unique(spearmanrho_cd55vGFP), 2)) ) ) +
  facet_grid( Backbone2+crRNAMOI~Spacer ) +
  theme_bw( base_size = 12 ) +
  theme( legend.position = 'none',
         legend.direction = 'vertical',
         legend.text = element_text( size = rel(1.5)),
         plot.title = element_text(hjust = 0.5),
         axis.text.x = element_text(angle = 90),
         panel.background = element_blank()
  ) +
  ggtitle( 'CD55-PE vs. CD151-APC, K562 Day6')
print(p2)
dev.off()


png('Bar_percGFPon_P3.png', width = 22, height = 4.5, units = 'in', res = 300 )
b1 <- ggplot() +
  geom_bar( data = p3_summarydt, aes( x = percGFPon, y = Backbone2), stat = 'identity', position = 'dodge' ) +
  theme_bw( base_size = 15 ) +
  facet_grid( crRNAMOI~Spacer, drop = TRUE, scales = 'free_y' ) +
  xlim( c(0,100) ) +
  ggtitle( 'Percent GFP positive, gated on single cells')
print(b1)
dev.off()

png('Scatter_GFPvsFSC_P3.png', width = 20, height = 20, units = 'in', res = 300 )
dftoplot <- p3dt
p3 <- ggplot() +
  geom_point( data = dftoplot, aes( x = `FSC-A`, y = log10_BL1A, color = Backbone2 ), alpha = 0.15, size = 0.75 ) +
  # geom_text( data = dftoplot2, aes( x = 5, y = 0.5, label = paste0( 'Rho = ', round( unique(spearmanrho_cd55vGFP), 2)) ) ) +
  facet_grid( Spacer~Backbone2+crRNAMOI ) +
  theme_bw( base_size = 12 ) +
  theme( legend.position = 'none',
         legend.direction = 'vertical',
         legend.text = element_text( size = rel(1.5)),
         plot.title = element_text(hjust = 0.5),
         axis.text.x = element_text(angle = 90),
         panel.background = element_blank()
  ) +
  ggtitle( 'GFP vs. FSC, gated on single cells')
print(p3)
dev.off()
# 
# # 
# ###### try to write a function
# dt <- gfpdt
# vartothres = 'log10_RL1A'
# thres = 0.05
# negctrlvar = 'Spacer'
# wellIDvar = 'Sample'
# samplesummarygroupvar = c(wellIDvar, negctrlvar, 'Cells', 'Backbone2', 'crRNAMOI')
# negctrl = 'NT-3'
# negctrlgroupvar = samplesummarygroupvar[ !(samplesummarygroupvar %in% c(wellIDvar, negctrlvar) ) ]
# 
# ## string input for group_by is confusing
# # getPercBelowNegCtrlThres <- function( dt, 
# #                                       vartothres,
# #                                       thres = 0.05,
# #                                       negctrlvar = 'Spacer',
# #                                       wellIDvar = 'Sample',
# #                                       samplesummarygroupvar = c(wellIDvar, negctrlvar, 'Cells', 'Backbone2', 'crRNAMOI'),
# #                                       negctrl = 'NT-3',
# #                                       negctrlgroupvar = samplesummarygroupvar[ !(samplesummarygroupvar %in% c(wellIDvar, negctrlvar) ) ]
# # ){
# #   summarydt <- dplyr::group_by_at( dt, .dots = samplesummarygroupvar ) %>%
# #     dplyr::summarise(
# #       thresvalue= quantile( get(vartothres), thres, na.rm = TRUE )
# #     )
# #   
# #   negctrlthres <- subset( dt, get(negctrlvar) == negctrl ) %>%
# #     dplyr::select( all_of(negctrlgroupvar) ) %>%
# #     unique()
# #   
# #   summarydt2 <- dplyr::left_join( dt, negctrlthres, by = all_of(negctrlgroupvar) )
# # }
