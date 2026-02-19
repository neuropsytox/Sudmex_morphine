#!/usr/bin/env Rscript

# Clear workspace
rm(list = ls())
# packages´ ---------------------------------------------------------------

library(tidyverse)
library(RMINC)
library(dplyr)
library(parallel)
library(lmerTest)
library(lme4)
library(magrittr)
library(janitor)
library(ggpubr)
library(effects)
library(grid)
library(MRIcrotome)

#for i in $(ls -d Seed_based/Clusterize_maps/uncorrected/M1_fc_dataset_*/__tmp_*/olay_clust_reset_thr.nii); do nii2mnc $i ${i%.*}.mnc; done

path <- "/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/fmri"
setwd(path)

# Load anat vol
#anatVol=mincArray(mincGetVolume(paste0(path,"/../../../neuropsytox_utils/Atlas/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_InVivo_Template/SIGMA_InVivo_Brain_Template_Masked.mnc")))
anatVol=mincArray(mincGetVolume(paste0(path,"/Atlas/template_sharpen_shapeupdate_brain.mnc")))

# Load fmri maps
fmriMaps_paths <- list.files(paste0(path,"/Seed_based/Clusterize_maps/uncorrected"), pattern = "_registered.mnc", full.names = TRUE, recursive = TRUE)
fmriMaps_paths_name <- sapply(fmriMaps_paths, function(x) strsplit(x, "/")[[1]][12]) %>% as.vector()
fmriMaps <- lapply(fmriMaps_paths, function(x) mincArray(mincGetVolume(x))) %>% set_names(fmriMaps_paths_name)

dir.create("Seed_based/Clusterize_maps/fig_tmaps",recursive=T)
for (fmp in fmriMaps_paths_name){
    svg(paste0("Seed_based/Clusterize_maps/fig_tmaps/",fmp,".svg"), height = 8, width = 11, bg = "transparent")
    sliceSeries(nrow = 4, ncol = 8, begin = 20, end = 130) %>%
    anatomy(anatVol, low=0, high=3) %>%   
       overlay(fmriMaps[[fmp]], low=1.96, high=10, symmetric = T) %>%
      contours(abs(fmriMaps[[fmp]]),
        levels=c(2.58,3.29), col=c("yellow","green"), lty=4) %>% 
    draw()
    dev.off()
}
