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

atlas = "/scratch/m/mchakrav/jrasgado/sudmex_alcohol_rat/Atlas/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Brain_Atlases/SIGMA_Anatomical_Atlas/InVivo_Atlas/SIGMA_InVivo_Anatomical_Brain_Atlas.mnc"

listROI = "/scratch/m/mchakrav/jrasgado/sudmex_alcohol_rat/Atlas/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Brain_Atlases/SIGMA_Anatomical_Atlas/InVivo_Atlas/SIGMA_InVivo_Anatomical_Brain_Atlas_ListOfStructures2.csv"

# Extract Jacobians volumes

Volumes_jacobian <- anatGetAll(filenames=Jdata$Subject, 
                      atlas=atlas, 
                      method="jacobians",
                      defs=listROI)

Volumes_means <- anatGetAll(filenames=Jdata$Subject, 
                      atlas=atlas, 
                      method ="means",
                      defs=listROI)

Volumes_sums <- anatGetAll(filenames=Jdata$Subject, 
                      atlas=atlas, 
                      method ="sums",
                      defs=listROI)

Vjacobian <- Volumes_jacobian %>% as_tibble %>%  mutate(
  Subject = Jdata$Subject,
  RID = Jdata$RID,
  Session = Jdata$Session,
  Group = Jdata$Group,
  Sex = Jdata$Sex,
  Batch = Jdata$Batch) %>% 
  select(RID,Group,Session,Sex,Batch,Subject,everything())

Vmeans <- Volumes_means %>% as_tibble %>%  mutate(
  Subject = Jdata$Subject,
  RID = Jdata$RID,
  Session = Jdata$Session,
  Group = Jdata$Group,
  Sex = Jdata$Sex,
  Batch = Jdata$Batch) %>% 
  select(RID,Group,Session,Sex,Batch,Subject,everything())

Vsums <- Volumes_sums %>% as_tibble %>%  mutate(
  Subject = Jdata$Subject,
  RID = Jdata$RID,
  Session = Jdata$Session,
  Group = Jdata$Group,
  Sex = Jdata$Sex,
  Batch = Jdata$Batch) %>% 
  select(RID,Group,Session,Sex,Batch,Subject,everything())

dir.create("Volumes")

write_csv(Vjacobian, "Volumes/Volumes_jacobians.csv")
write_csv(Vmeans, "Volumes/Volumes_means.csv")
write_csv(Vsums, "Volumes/Volumes_sums.csv")
