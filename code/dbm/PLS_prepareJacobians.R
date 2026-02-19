#  DBM - invivo

#rm(list=ls())
# packages´ ---------------------------------------------------------------
# 
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

args <- commandArgs()
smooth <- args[6]

# directories -------------------------------------------------------------
smooth="4vox"
path <- "/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/smri/DBM_invivo"
mask=paste0(path,"/DBM/smooth_",smooth,"/tmaps/M1-tvalue-Age_GroupMor1_mask.mnc")
anatVol=mincArray(mincGetVolume(paste0(path,"/DBM/tomodel/template_sharpen_shapeupdate_brain.mnc")))
setwd(paste0(path,"/DBM/smooth_",smooth))
dir.create("data", recursive = T)

# Load data ---------------------------------------------------------------

load("DBM_data.RData")

data <- read_csv("data/Behavior_metrics4pls_1.csv")

# Create a csv with the paths to the jacobians that you want to include in the analysis
path_jacobians <- paste0(path,"/jacobians/output/secondlevel/resampled-dbm/jacobian/relative/smooth/")

files_names <- list.files(path_jacobians) %>%
    #keep only those who has "T3" in the name
    keep(~ grepl("T3", .)) %>% #CAREFUL WITH THIS
    #keep only those who has "mnc" in the name
    keep(~ grepl("mnc", .)) %>% 
    #keep only those who has smooth in the name
    keep(~ grepl(smooth, .))

# Read in the csv with the listed jacobians that you want to include in the analysis, as you would for a classic twolevel analysis 
# They must be mincs, in this case in a column named "file" 

jacobian_fullpath <- files_names %>%
    str_split(pattern="_") %>% map(~ .x[[1]]) %>% reduce(rbind) %>% as_tibble() %>%
    add_column(relative_jacobian = files_names) %>%
    set_colnames(c("RID","relative_jacobian")) %>% right_join(data,by = "RID",.name_repair) %>%
    mutate(file = paste0(path_jacobians,relative_jacobian)) %>% 
    select(file)

# Read in the minc of the mask 
mask = mincGetVolume(mask)

# Create a column filled with the jacobians, but restricted to the mask
jacobian_fullpath$jacdata = t(sapply(jacobian_fullpath$file, function(f) mincGetVolume(f)[mask > 0]))

# making the jacobian data its own object
braintrix = jacobian_fullpath$jacdata

# Write out the matrix 
# This can then become the brain inputs to your PLS.
write.csv(data %>% select(-c(RID,Group)), file = "data/Behavior_metrics4pls.csv", row.names=FALSE)
write.csv(braintrix, file ="data/Brain_matrix4pls.csv", row.names=FALSE)
