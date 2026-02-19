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
library(effects)

# directories -------------------------------------------------------------
args <- commandArgs()
smooth <- args[6]

path <- "/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/smri/DBM_invivo"
atlas=paste0(path,"/DBM/tomodel/atlas_labels_registered.mnc")
mask=paste0(path,"/jacobians/output/secondlevel/final/average/mask_shapeupdate.mnc")
setwd(paste0(path,"/DBM/smooth_",smooth,"/"))
dir.create("data", recursive = T)

# Load data ---------------------------------------------------------------

load("DBM_data.RData")

# Extract peaks
Model1=Mod1
Lmod1_peaks <- mincFindPeaks(Model1, column = 'tvalue-poly(Age, 2)1:GroupMor', direction = "both", threshold = 2.5, minDistance = 4) 
Pmod1_peaks <- mincFindPeaks(Model1, column = 'tvalue-poly(Age, 2)2:GroupMor', direction = "both", threshold = 2.5, minDistance = 4) 

mod_peaks <- list(Lmod1_peaks,Pmod1_peaks) %>% 
  map(~ mincLabelPeaks(.x,  atlas, defs="../data/SIGMA_InVivo_Anatomical_Brain_Atlas_ListOfStructures.csv") ) %>% 
  set_names(c("Lmod1_peaks","Pmod1_peaks"))

dir.create("Peaks")

mod_peaks %>% iwalk(~write_csv(.x, paste0(getwd(),"/Peaks/",.y, ".csv")))

# Trayectories -------------------------------------------------------------

mod_peaks <- mod_peaks %>% map(~ .x %>% mutate(label_clean = label %>% make_clean_names()) )

ROIs <- names(mod_peaks) %>% map(~ mod_peaks[[.x]] %>% add_column(Model = rep(.x, nrow(mod_peaks[[.x]]) )) ) %>% reduce(rbind) %>% mutate(ROI_model = str_c(label_clean,'_',Model) )

Jdata_jacobians <- Jdata %>% select(RID,Session,Subject,Group,Age,Sex,Batch)

for (i in seq(1:length(ROIs$x)) ) {
Jdata_jacobians[ROIs$ROI_model[i]] = mincGetWorldVoxel(Jdata$Subject, ROIs$x[i], ROIs$y[i], ROIs$z[i])
}

dir.create("Trayectories")

write_csv(Jdata_jacobians,"Trayectories/Jdata_jacobians.csv")
write_csv(ROIs,"Peaks/ROIs.csv")

# Plotting ----------------------------------------------------------------

theme_settings <- theme(text = element_text(size=20),
                        axis.text.x = element_text(size=15))

# colors
pal_group <- c("#737373","#8d289f")
                        
nROI <- ROIs$ROI_model

# Linear

dir.create("Trayectories/Linear/Group", recursive = TRUE)

plots_ROIs_L <- NULL
for (i in 1:length(nROI)) {
  ROI <- nROI[i]
  plots_ROIs_L[[ROI]] <- ggscatter(Jdata_jacobians,
                  x = "Age", y = ROI, group = "Group",
                  color = "Group", linewidth =2,
                  palette = pal_group,
                  add.params = list(size = 2, alpha = 0.5),
                  plot_type ="b",
                  title = gsub('_left','',ROIs$label[i]),
                  xlab = "Age (PND)",
                  ylab = "Local volume",
                  font.x = c(16,"bold"),
                  font.y = c(16,"bold"),
                  font.tickslab = c(14,"bold")) +
        geom_line(data = as_tibble(Effect(c("Group", "Age"),
                                          lmer(get(ROI) ~ Age*Group + 
                                                 Batch + (1 |RID), data = Jdata_jacobians), 
                                          xlevels=list(Age=seq(min(Jdata_jacobians$Age),
                                                               max(Jdata_jacobians$Age),1)))), 
                  aes(y=fit, color = Group), size=2) +
        geom_ribbon(data = as_tibble(Effect(c("Group", "Age"),
                                            lmer(get(ROI) ~ Age*Group + 
                                                 Batch + (1 |RID), data = Jdata_jacobians), 
                                            xlevels=list(Age=seq(min(Jdata_jacobians$Age),
                                                                 max(Jdata_jacobians$Age),1)))), 
		  aes(y=fit, ymin=lower, ymax=upper, fill = Group), alpha=0.3) +
        theme(legend.position = "none",
              plot.title = element_text(hjust = 0.5,size = 16, face = "bold")) + 
        theme_settings 
}
  
1:length(plots_ROIs_L) %>% map(~ ggsave(filename = paste0("Trayectories/Linear/Group/",plots_ROIs_L[.x] %>% names(),".png"), plot = plots_ROIs_L[[.x]],dpi = 300, width = 5.5, height = 4.5) ) 

#-------------------------------------------------------------------------

# Polynomial

dir.create("Trayectories/Polynomial/Group", recursive = TRUE)

plots_ROIs <- NULL
for (i in 1:length(nROI)) {
  ROI <- nROI[i]
  plots_ROIs[[ROI]] <- ggscatter(Jdata_jacobians,
                  x = "Age", y = ROI, group = "Group",
                  color = "Group", linewidth =2,
                  palette = pal_group,
                  add.params = list(size = 2, alpha = 0.5),
                  plot_type ="b",
                  title = gsub('_left','',ROIs$label[i]),
                  xlab = "Age (PND)",
                  ylab = "Local volume",
                  font.x = c(16,"bold"),
                  font.y = c(16,"bold"),
                  font.tickslab = c(14,"bold")) +
        geom_line(data = as_tibble(Effect(c("Group", "Age"),
                                          lmer(get(ROI) ~ poly(Age,2)*Group + 
                                                Batch + (1 |RID), data = Jdata_jacobians), 
                                          xlevels=list(Age=seq(min(Jdata_jacobians$Age),
                                                               max(Jdata_jacobians$Age),1)))), 
                  aes(y=fit, color = Group), size=2) +
        geom_ribbon(data = as_tibble(Effect(c("Group", "Age"),
                                            lmer(get(ROI) ~ poly(Age,2)*Group + 
                                                Batch + (1 |RID), data = Jdata_jacobians), 
                                            xlevels=list(Age=seq(min(Jdata_jacobians$Age),
                                                                 max(Jdata_jacobians$Age),1)))), 
		  aes(y=fit, ymin=lower, ymax=upper, fill = Group), alpha=0.3) +
        theme(legend.position = "none",
              plot.title = element_text(hjust = 0.5,size = 16, face = "bold")) + 
        theme_settings 
}
  
1:length(plots_ROIs) %>% map(~ ggsave(filename = paste0("Trayectories/Polynomial/Group/",plots_ROIs[.x] %>% names(),".png"), plot = plots_ROIs[[.x]],dpi = 300, width = 5.5, height = 4.5) ) 

# Creating table of peaks -------------------------------------------------

ROI_table <- ROIs %>% mutate(ROIs = gsub('_left','',label %>% 
                        str_split(pattern = " ", n = 2) %>% 
                        reduce(rbind) %>% .[,2]),
                      Hemisphere = label %>% 
                        str_split(pattern = " ", n = 2) %>% 
                        reduce(rbind) %>% .[,1],
                      "t-value" = value,
                      Coordinates = str_c(round(x,2),',',round(y,2),',',round(z,2)),
                      Effect = case_when(value > 0 ~ "Increase",
                                         TRUE ~ "Decrease"),
                      Model2 = case_when(Model == "Lmod1_peaks" ~ "Model 1",
                                        Model == "Pmod1_peaks" ~ "Model 1"),
                      Contrast = case_when(Model == "Lmod1_peaks" ~ "Mor > Ctrl",
                                        Model == "Pmod1_peaks" ~ "Mor > Ctrl"),
 		      Type = case_when(Model == "Lmod1_peaks" ~ "Linear",
                                        Model == "Pmod1_peaks" ~ "Poly") ) %>% 
  select(Model2,Type,Contrast,ROIs, Hemisphere, Coordinates, Effect, "t-value")

write_csv(ROIs,"Trayectories/ROIs.csv")
write_csv(ROI_table,"Trayectories/ROI_table.csv")

#save(atlas,mod_peaks,theme_settings,plots_ROIs_L,plots_ROIs,Jdata_jacobians,ROIs,ROI_table,nROI, file = "Trayectories_data.RData")
