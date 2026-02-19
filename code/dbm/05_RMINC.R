#  DBM - invivo

#rm(list=ls())
# packages´ ---------------------------------------------------------------

library(tidyverse)
library(RMINC)
library(dplyr)
library(parallel)
library(lmerTest)
library(lme4)

args <- commandArgs()
smooth <- args[6]

# directories -------------------------------------------------------------

path <- "/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/smri/DBM_invivo"
# Anatomical mask of selected ROIs
mask=paste0(path,"/DBM/tomodel/atlas_labels_registered.mnc")
#mask=paste0(path,"/jacobians/output/secondlevel/final/average/mask_shapeupdate.mnc")
setwd(paste0(path,"/DBM"))
dir.create("data", recursive = T)
file.copy(from=paste0(path,"/code/DBM_dataset.csv"),to=paste0(path,"/DBM/data/DBM_dataset.csv"),overwrite=T)

# data --------------------------------------------------------------------

#Jdata <- read_csv("data/DBM_dataset.csv") %>% filter( IN == "yes", Group == "Mor" | Group == "Sham")

Jdata <- read_csv(paste0(path,"/DBM/data/DBM_dataset_",smooth,".csv")) %>% filter( IN == "yes", Group == "Mor" | Group == "Sham")

#define what is the type of variables%>%

Jdata <- Jdata %>% mutate(Group = factor(Group) %>% relevel(Group, ref = "Sham"), # Ctrl as reference
			   Age = as.numeric(Age),
			   Sex = factor(Sex),
			   Session = factor(Session),
			   RID = factor(RID),
			   Batch = factor(Batch) ) 
			 
# Modelling

Mod1 <- mincLmer(Subject ~ poly(Age,2)*Group + Batch + (1 |RID), 
                  data = Jdata, 
                  mask = mask,
                  parallel = c("local", 50),
                  REML = TRUE)
                  
fdrMod1 <- (mincFDR(mincLmerEstimateDF(model = Mod1), mask = mask)) 

###

Model_ses <- mincLmer(Subject ~ Session*Group + Batch + (1 |RID), 
                      data = Jdata, 
                      mask = mask,
                      parallel = c("local", 50),
                      REML = TRUE)
                  
fdrMod_ses <- (mincFDR(mincLmerEstimateDF(model = Model_ses), mask = mask)) 

# Saving data

save(Jdata, Mod1, fdrMod1, Model_ses, fdrMod_ses, file = paste0(path,"/DBM/smooth_",smooth,"/DBM_data.RData"))

dir.create(paste0(path,"/DBM/smooth_",smooth,"/tmaps/"))

# Exporting

####
mincWriteVolume(Mod1,paste0(path,"/DBM/smooth_",smooth,"/tmaps/M1-tvalue-Age_GroupMor1.mnc"), 
                column = 'tvalue-poly(Age, 2)1:GroupMor', clobber = TRUE)

mincWriteVolume(Mod1,paste0(path,"/DBM/smooth_",smooth,"/tmaps/M1-tvalue-Age_GroupMor2.mnc"),
                column = 'tvalue-poly(Age, 2)2:GroupMor', clobber = TRUE)

####

mincWriteVolume(Model_ses,paste0(path,"/DBM/smooth_",smooth,"/tmaps/tvalue-Sessionses-T2_GroupMor.mnc"),
                column = 'tvalue-Sessionses-T2:GroupMor', clobber = TRUE)

mincWriteVolume(Model_ses,paste0(path,"/DBM/smooth_",smooth,"/tmaps/tvalue-Sessionses-T3_GroupMor.mnc"),
                column = 'tvalue-Sessionses-T3:GroupMor', clobber = TRUE)

####
print("finished models")
