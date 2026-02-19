#  DBM - invivo

#rm(list=ls())
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

# directories -------------------------------------------------------------

getwd()

# Load data ---------------------------------------------------------------

load("DBM_data1.RData")
load("DBM_data2.RData")

atlas='/scratch/m/mchakrav/jrasgado/sudmex_alcohol_rat/analysis/smri/DBM_invivo/DBM/data/ROI_mask.mnc'

# Obtain Jacobians 

coords=read_csv("Jac4Histology/coords_Jac.csv")

Jdata_jacobians = drop_na(Jdata)

for (i in seq(1:length(coords$x)) ) {
Jdata_jacobians[coords$label[i]] = mincGetWorldVoxel(Jdata$Subject, coords$x[i], coords$y[i], coords$z[i])

}

write_csv(Jdata_jacobians,"Jac4Histology/ROI_jacobians.csv")
