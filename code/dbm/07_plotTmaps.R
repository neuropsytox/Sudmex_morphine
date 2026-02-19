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
library(grid)
library(MRIcrotome)

args <- commandArgs()
smooth <- args[6]


# directories -------------------------------------------------------------
path <- "/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/smri/DBM_invivo"
atlas=paste0(path,"/DBM/tomodel/atlas_labels_registered.mnc")
mask=paste0(path,"/jacobians/output/secondlevel/final/average/mask_shapeupdate.mnc")
anatVol=mincArray(mincGetVolume(paste0(path,"/DBM/tomodel/template_sharpen_shapeupdate_brain.mnc")))
setwd(paste0(path,"/DBM/smooth_",smooth))
dir.create("data", recursive = T)

# Load data ---------------------------------------------------------------

rdata_files <- list.files(pattern = "\\.RData$")

for (rdata_file in rdata_files) {
  load(rdata_file)
}

# Detect how many Mod# or Model# exist in the workspace
mod_count <- sum(ls() %>% str_detect("^Mod\\d+$"))
model_count <- sum(ls() %>% str_detect("^Model\\d+$"))

# Check if Mod1 exists in the workspace
if (!exists("Mod1")) {
  for (i in 1:model_count) {
    assign(paste0("Mod",i), get(paste0("Model",i)))
  }
} 

# Some specifications -----------------------------------------------------

dir.create("fig_tmaps")
last_element_check <- function(model_list) {
  last_elements <- model_list %>% map(~ tail(.x, 1))
  last_elements %>% map_lgl(~ str_detect(.x, paste0("tvalue-poly(Age, 2)2:",Sex_name)))
}

pos_poly1_1 = "#f40752"
pos_poly1_2 = "#FFF347"
neg_poly1_1 = "#3d8bff"
neg_poly1_2 = "#85FDFF"

pos_poly2_1 = "#F28123"
pos_poly2_2 = "#FFF347"
neg_poly2_1 = "#392D69"
neg_poly2_2 = "#E8D7FF"

# Plot Tmaps --------------------------------------------------------------

Mods=c("Mod1") #modify accordig the models
Groups=c("Mor") #modify accordig the groups
Sex_name="Sexmale"

Allthresholds <- Mods %>% map(~ paste0("fdr",.x) ) %>% map(~ attr(get(.x), "thresholds") ) %>% set_names(Mods)
AlldimThr <- Allthresholds %>% map(~ dimnames(.x)[[2]][] )# %>% set_names(Mods)

Mods_wS <- Mods[which(map_lgl(AlldimThr, ~ {any(str_detect(.x,":Sex")) }) == "FALSE")]
Mods_S <- Mods[which(map_lgl(AlldimThr, ~ {any(str_detect(.x,":Sex")) }) == "TRUE")]
Mods_onlyS <- Mods[which(last_element_check(AlldimThr) == "TRUE")]

# Plot Tmaps --------------------------------------------------------------
is_poly <- any(AlldimThr %>% map(~ any(str_detect(.x, "poly\\(Age, 2\\)"))) )
is_age_or_session <- AlldimThr %>% map(~ if (any(str_detect(.x, "Age"))) "Age" else if (any(str_detect(.x, "Session"))) "Session" else NA_character_)

if (is_poly == FALSE) {
  for (Mod in Mods_wS) {

  setwd(paste0(path,"/DBM/smooth_",smooth))

    for (Group in Groups) {

      rois=read_csv("Peaks/ROIs.csv") %>%
        filter(grepl(paste0("L",str_to_lower(Mod)),Model)) 

      fdrMod=paste0("fdr",Mod)
      thresholds=attr(get(fdrMod), "thresholds")
      dimThr=dimnames(thresholds)[[2]][c(-1)]

    is_mod_age_or_session <- if (any(str_detect(dimThr, "Age"))) "Age" else if (any(str_detect(dimThr, "Session"))) "Session" else NA_character_

        if (paste0("tvalue-", is_mod_age_or_session, ":Group", Group) %in% dimThr == TRUE) {
          column_name <- paste0("tvalue-", is_mod_age_or_session, ":Group", Group)
        } else if (paste0("tvalue-", is_mod_age_or_session) %in% dimThr == TRUE) {
          column_name <- paste0("tvalue-",is_mod_age_or_session)
        }

    if (column_name %in% dimThr) {
    
      if (grepl("\\+", Group)) {
        filter_group <- gsub("\\+", "", Group)
      } else {
        filter_group <- Group
      }

      #rois <- rois %>%
      #  filter(grepl(paste0("_",filter_group,"$"), rois$Model))

      print(column_name)  
      assign(paste0(Mod, "_stats1_", Group), mincArray(get(Mod), column_name))

      tFDR01L <- Allthresholds[[Mod]]["0.01", column_name] %>% round(digits=2)
      tFDR5L <- Allthresholds[[Mod]]["0.05", column_name] %>% round(digits=2)
      tFDR1L <- Allthresholds[[Mod]]["0.1", column_name] %>% round(digits=2)
      tFDR15L <- Allthresholds[[Mod]]["0.15", column_name] %>% round(digits=2)
      tFDR2L <- Allthresholds[[Mod]]["0.2", column_name] %>% round(digits=2)
      tmax <- rois$value %>% max() + 1
      anatVol_min <- min(anatVol)
      anatVol_max <- max(anatVol)

      if (tFDR2L %in% NA){
        print("non significant at 20% FDR")
      } else {

      # Generate the default colourmaps
      pospal = colorRampPalette(c("red", "yellow"), alpha=TRUE)(255)
      negpal = colorRampPalette(c("blue", "turquoise1"), alpha=TRUE)(255)

      # Find the crossover point in the map where the colourmap switches to "non transparent"
      # Need to include the alpha term here, but its always opaque
      breakpointpos = pospal[round(tFDR2L/tmax*255) - 1]
      breakpointneg = negpal[round(tFDR2L/tmax*255) - 1]

      # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
      pospalalpha = colorRampPalette(c("#FF000000", breakpointpos), alpha=TRUE)(round(tFDR2L/tmax*255) -1)
      negpalalpha = colorRampPalette(c("#0000FF00", breakpointneg), alpha=TRUE)(round(tFDR2L/tmax*255) - 1)

      # Concatenate the two maps together for a complete map
      combinedpospal = c(pospalalpha, pospal[round(tFDR2L/tmax*255):length(pospal)])
      combinednegpal = c(negpalalpha, negpal[round(tFDR2L/tmax*255):length(negpal)])

        dir.create(paste0("fig_tmaps/single/",Mod,"/",Group), recursive = T)
        for (roi in 1:nrow(rois)) {
          svg(paste0("fig_tmaps/single/",Mod,"/",Group,"/",Mod,"-",rois$ROI_model[roi],".svg"), 
            height = 3, width = 3, bg = "transparent")
          sliceSeries(nrow = 1, ncol = 1, begin = rois$d2[roi], end = rois$d2[roi]) %>%
          anatomy(anatVol, low=anatVol_min+0.5, high=anatVol_max) %>%   
          overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
          draw()
          dev.off()
        }
      }

      if (tFDR5L %in% NA){
        print("non significant at 5% FDR")
      } else {

      # Generate the default colourmaps
      pospal = colorRampPalette(c("red", "yellow"), alpha=TRUE)(255)
      negpal = colorRampPalette(c("blue", "turquoise1"), alpha=TRUE)(255)

      # Find the crossover point in the map where the colourmap switches to "non transparent"
      # Need to include the alpha term here, but its always opaque
      breakpointpos = pospal[round(tFDR5L/tmax*255) - 1]
      breakpointneg = negpal[round(tFDR5L/tmax*255) - 1]

      # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
      pospalalpha = colorRampPalette(c("#FF000000", breakpointpos), alpha=TRUE)(round(tFDR5L/tmax*255) -1)
      negpalalpha = colorRampPalette(c("#0000FF00", breakpointneg), alpha=TRUE)(round(tFDR5L/tmax*255) - 1)

      # Concatenate the two maps together for a complete map
      combinedpospal = c(pospalalpha, pospal[round(tFDR5L/tmax*255):length(pospal)])
      combinednegpal = c(negpalalpha, negpal[round(tFDR5L/tmax*255):length(negpal)])

        dir.create(paste0("fig_tmaps/single/",Mod,"/",Group), recursive = T)
        for (roi in 1:nrow(rois)) {
          svg(paste0("fig_tmaps/single/",Mod,"/",Group,"/",Mod,"-",rois$ROI_model[roi],".svg"), 
            height = 3, width = 3, bg = "transparent")
          sliceSeries(nrow = 1, ncol = 1, begin = rois$d2[roi], end = rois$d2[roi]) %>%
          anatomy(anatVol, low=anatVol_min+0.5, high=anatVol_max) %>%   
          overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
          contours(abs(get(paste0(Mod, "_stats1_", Group))), 
            levels=tFDR5L, 
            col="black", 
            lwd=0.9) %>% 
          draw()
          dev.off()
        }
      }

      if (tFDR01L %in% NA){
        print("non significant at 1% FDR")
      } else {

      # Generate the default colourmaps
      pospal = colorRampPalette(c("red", "yellow"), alpha=TRUE)(255)
      negpal = colorRampPalette(c("blue", "turquoise1"), alpha=TRUE)(255)

      # Find the crossover point in the map where the colourmap switches to "non transparent"
      # Need to include the alpha term here, but its always opaque
      breakpointpos = pospal[round(tFDR5L/tmax*255) - 1]
      breakpointneg = negpal[round(tFDR5L/tmax*255) - 1]

      # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
      pospalalpha = colorRampPalette(c("#FF000000", breakpointpos), alpha=TRUE)(round(tFDR5L/tmax*255) -1)
      negpalalpha = colorRampPalette(c("#0000FF00", breakpointneg), alpha=TRUE)(round(tFDR5L/tmax*255) - 1)

      # Concatenate the two maps together for a complete map
      combinedpospal = c(pospalalpha, pospal[round(tFDR5L/tmax*255):length(pospal)])
      combinednegpal = c(negpalalpha, negpal[round(tFDR5L/tmax*255):length(negpal)])

        dir.create(paste0("fig_tmaps/single/",Mod,"/",Group), recursive = T)
        for (roi in 1:nrow(rois)) {
          svg(paste0("fig_tmaps/single/",Mod,"/",Group,"/",Mod,"-",rois$ROI_model[roi],".svg"), 
            height = 3, width = 3, bg = "transparent")
          sliceSeries(nrow = 1, ncol = 1, begin = rois$d2[roi], end = rois$d2[roi]) %>%
          anatomy(anatVol, low=anatVol_min+0.5, high=anatVol_max) %>%   
          overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
          contours(abs(get(paste0(Mod, "_stats1_", Group))), 
            levels=c(tFDR5L,tFDR01L), 
            col=c("black","yellow"), 
            lwd=0.9) %>%
          draw()
          dev.off()
        }
      }

      # Three axis slices
      if (tFDR01L %in% NA){
        print("non significant at 1% FDR")
      } else {

      # Generate the default colourmaps
      pospal = colorRampPalette(c("red", "yellow"), alpha=TRUE)(255)
      negpal = colorRampPalette(c("blue", "turquoise1"), alpha=TRUE)(255)

      # Find the crossover point in the map where the colourmap switches to "non transparent"
      # Need to include the alpha term here, but its always opaque
      breakpointpos = pospal[round(tFDR5L/tmax*255) - 1]
      breakpointneg = negpal[round(tFDR5L/tmax*255) - 1]

      # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
      pospalalpha = colorRampPalette(c("#FF000000", breakpointpos), alpha=TRUE)(round(tFDR5L/tmax*255) -1)
      negpalalpha = colorRampPalette(c("#0000FF00", breakpointneg), alpha=TRUE)(round(tFDR5L/tmax*255) - 1)

      # Concatenate the two maps together for a complete map
      combinedpospal = c(pospalalpha, pospal[round(tFDR5L/tmax*255):length(pospal)])
      combinednegpal = c(negpalalpha, negpal[round(tFDR5L/tmax*255):length(negpal)])

        dir.create(paste0("fig_tmaps/multiple/",Mod,"/",Group), recursive = T)
          svg(paste0("fig_tmaps/multiple/",Mod,"/",Group,"/",Mod,"-csa.svg"), 
            height = 3, width = 9, bg = "transparent")
          sliceSeries(ncol = 7, 
            begin = round(dim(anatVol)[2]*0.15), 
            end = round(dim(anatVol)[2]*0.75),
            dimension = 2) %>%
          anatomy(anatVol, 
            low=anatVol_min+0.5, high=anatVol_max) %>%   
          overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
          contours(abs(get(paste0(Mod, "_stats1_", Group))), 
            levels=c(tFDR5L,tFDR01L), 
            col=c("black","yellow"), 
            lwd=0.9) %>% # Sagittal
          sliceSeries(ncol = 7, 
            begin = round(dim(anatVol)[1]*0.2), 
            end = round(dim(anatVol)[1]*0.75),
            dimension = 1) %>%
          anatomy(anatVol, 
            low=anatVol_min+0.5, high=anatVol_max) %>%   
          overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
          contours(abs(get(paste0(Mod, "_stats1_", Group))), 
            levels=c(tFDR5L,tFDR01L), 
            col=c("black","yellow"), 
            lwd=0.9) %>% # Axial
          sliceSeries(ncol = 10, 
            begin = round(dim(anatVol)[3]*0.3), 
            end = round(dim(anatVol)[3]*0.75),
            dimension = 3) %>%
          anatomy(anatVol, 
            low=anatVol_min+0.5, high=anatVol_max) %>%   
          overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
          contours(abs(get(paste0(Mod, "_stats1_", Group))), 
            levels=c(tFDR5L,tFDR01L), 
            col=c("black","yellow"), 
            lwd=0.9) %>%
          draw(layout = "row")
          dev.off()
        
      }

    } else {
      print("No contrast for this group")
    }

    }
  }

  for (Mod in Mods_S) {

    for (Group in Groups) {

      rois=read_csv("Peaks/ROIs.csv") %>%
        filter(grepl(paste0("L",str_to_lower(Mod)),Model)) 
        if (nrow(rois) == 0) {
          print(paste("No ROIs found for", Mod, "and", Group))
          next
        }

        fdrMod=paste0("fdr",Mod)
        thresholds=attr(get(fdrMod), "thresholds")
        dimThr=dimnames(thresholds)[[2]][c(-1)]

        is_mod_age_or_session <- if (any(str_detect(dimThr, "Age"))) "Age" else if (any(str_detect(dimThr, "Session"))) "Session" else NA_character_

        if (paste0("tvalue-", is_mod_age_or_session, ":",Sex_name) %in% dimThr == TRUE) {
          column_name <- paste0("tvalue-", is_mod_age_or_session, ":",Sex_name)
        } else if (paste0("tvalue-", is_mod_age_or_session, ":Group", Group, ":",Sex_name) %in% dimThr == TRUE) {
          column_name <- paste0("tvalue-", is_mod_age_or_session, ":Group", Group, ":",Sex_name)
        }

        if (column_name %in% dimThr) {
        
          if (grepl("\\+", Group)) {
            filter_group <- gsub("\\+", "", Group)
          } else {
            filter_group <- Group
          }

          #rois <- rois %>%
          #  filter(grepl(paste0("_",filter_group,"$"), rois$Model))

          print(column_name)  
          assign(paste0(Mod, "_stats1_", Group), mincArray(get(Mod), column_name))

          tFDR01L <- Allthresholds[[Mod]]["0.01", column_name] %>% round(digits=2)
          tFDR5L <- Allthresholds[[Mod]]["0.05", column_name] %>% round(digits=2)
          tFDR1L <- Allthresholds[[Mod]]["0.1", column_name] %>% round(digits=2)
          tFDR2L <- Allthresholds[[Mod]]["0.2", column_name] %>% round(digits=2)
          tmax <- rois$value %>% max() + 1
          anatVol_min <- min(anatVol)
          anatVol_max <- max(anatVol)

        if (tFDR2L %in% NA){
          print("non significant at 20% FDR")
        } else {

          # Generate the default colourmaps
          pospal = colorRampPalette(c("red", "yellow"), alpha=TRUE)(255)
          negpal = colorRampPalette(c("blue", "turquoise1"), alpha=TRUE)(255)

          # Find the crossover point in the map where the colourmap switches to "non transparent"
          # Need to include the alpha term here, but its always opaque
          breakpointpos = pospal[round(tFDR2L/tmax*255) - 1]
          breakpointneg = negpal[round(tFDR2L/tmax*255) - 1]

          # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
          pospalalpha = colorRampPalette(c("#FF000000", breakpointpos), alpha=TRUE)(round(tFDR2L/tmax*255) -1)
          negpalalpha = colorRampPalette(c("#0000FF00", breakpointneg), alpha=TRUE)(round(tFDR2L/tmax*255) - 1)

          # Concatenate the two maps together for a complete map
          combinedpospal = c(pospalalpha, pospal[round(tFDR2L/tmax*255):length(pospal)])
          combinednegpal = c(negpalalpha, negpal[round(tFDR2L/tmax*255):length(negpal)])

          dir.create(paste0("fig_tmaps/single/",Mod,"/",Group), recursive = T)
          for (roi in 1:nrow(rois)) {
            svg(paste0("fig_tmaps/single/",Mod,"/",Group,"/",Mod,"-",rois$ROI_model[roi],".svg"), 
          height = 3, width = 3, bg = "transparent")
            sliceSeries(nrow = 1, ncol = 1, begin = rois$d2[roi], end = rois$d2[roi]) %>%
            anatomy(anatVol, low=anatVol_min+0.5, high=anatVol_max) %>%   
            overlay(get(paste0(Mod, "_stats1_", Group)),
          low=0, 
          high=tmax, 
          symmetric = T,
          col = combinedpospal,
          rCol = combinednegpal,
          alpha = 0.6) %>%
            draw()
            dev.off()
          }
        }

        if (tFDR5L %in% NA){
          print("non significant at 5% FDR")
        } else {

          # Generate the default colourmaps
          pospal = colorRampPalette(c("red", "yellow"), alpha=TRUE)(255)
          negpal = colorRampPalette(c("blue", "turquoise1"), alpha=TRUE)(255)

          # Find the crossover point in the map where the colourmap switches to "non transparent"
          # Need to include the alpha term here, but its always opaque
          breakpointpos = pospal[round(tFDR5L/tmax*255) - 1]
          breakpointneg = negpal[round(tFDR5L/tmax*255) - 1]

          # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
          pospalalpha = colorRampPalette(c("#FF000000", breakpointpos), alpha=TRUE)(round(tFDR5L/tmax*255) -1)
          negpalalpha = colorRampPalette(c("#0000FF00", breakpointneg), alpha=TRUE)(round(tFDR5L/tmax*255) - 1)

          # Concatenate the two maps together for a complete map
          combinedpospal = c(pospalalpha, pospal[round(tFDR5L/tmax*255):length(pospal)])
          combinednegpal = c(negpalalpha, negpal[round(tFDR5L/tmax*255):length(negpal)])

          dir.create(paste0("fig_tmaps/single/",Mod,"/",Group), recursive = T)
          for (roi in 1:nrow(rois)) {
            svg(paste0("fig_tmaps/single/",Mod,"/",Group,"/",Mod,"-",rois$ROI_model[roi],".svg"), 
          height = 3, width = 3, bg = "transparent")
            sliceSeries(nrow = 1, ncol = 1, begin = rois$d2[roi], end = rois$d2[roi]) %>%
            anatomy(anatVol, low=anatVol_min+0.5, high=anatVol_max) %>%   
            overlay(get(paste0(Mod, "_stats1_", Group)),
          low=0, 
          high=tmax, 
          symmetric = T,
          col = combinedpospal,
          rCol = combinednegpal,
          alpha = 0.6) %>%
            contours(abs(get(paste0(Mod, "_stats1_", Group))), 
          levels=tFDR5L, 
          col="black", 
          lwd=0.9) %>% 
            draw()
            dev.off()
          }
        }

        if (tFDR01L %in% NA){
          print("non significant at 1% FDR")
        } else {

          # Generate the default colourmaps
          pospal = colorRampPalette(c("red", "yellow"), alpha=TRUE)(255)
          negpal = colorRampPalette(c("blue", "turquoise1"), alpha=TRUE)(255)

          # Find the crossover point in the map where the colourmap switches to "non transparent"
          # Need to include the alpha term here, but its always opaque
          breakpointpos = pospal[round(tFDR5L/tmax*255) - 1]
          breakpointneg = negpal[round(tFDR5L/tmax*255) - 1]

          # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
          pospalalpha = colorRampPalette(c("#FF000000", breakpointpos), alpha=TRUE)(round(tFDR5L/tmax*255) -1)
          negpalalpha = colorRampPalette(c("#0000FF00", breakpointneg), alpha=TRUE)(round(tFDR5L/tmax*255) - 1)

          # Concatenate the two maps together for a complete map
          combinedpospal = c(pospalalpha, pospal[round(tFDR5L/tmax*255):length(pospal)])
          combinednegpal = c(negpalalpha, negpal[round(tFDR5L/tmax*255):length(negpal)])

          dir.create(paste0("fig_tmaps/single/",Mod,"/",Group), recursive = T)
          for (roi in 1:nrow(rois)) {
            svg(paste0("fig_tmaps/single/",Mod,"/",Group,"/",Mod,"-",rois$ROI_model[roi],".svg"), 
          height = 3, width = 3, bg = "transparent")
            sliceSeries(nrow = 1, ncol = 1, begin = rois$d2[roi], end = rois$d2[roi]) %>%
            anatomy(anatVol, low=anatVol_min+0.5, high=anatVol_max) %>%   
            overlay(get(paste0(Mod, "_stats1_", Group)),
          low=0, 
          high=tmax, 
          symmetric = T,
          col = combinedpospal,
          rCol = combinednegpal,
          alpha = 0.6) %>%
            contours(abs(get(paste0(Mod, "_stats1_", Group))), 
          levels=c(tFDR5L,tFDR01L), 
          col=c("black","yellow"), 
          lwd=0.9) %>%
            draw()
            dev.off()
            }
          }

# Three axis slices
      if (tFDR01L %in% NA){
        print("non significant at 1% FDR")
      } else {

          # Generate the default colourmaps
          pospal = colorRampPalette(c("red", "yellow"), alpha=TRUE)(255)
          negpal = colorRampPalette(c("blue", "turquoise1"), alpha=TRUE)(255)

          # Find the crossover point in the map where the colourmap switches to "non transparent"
          # Need to include the alpha term here, but its always opaque
          breakpointpos = pospal[round(tFDR5L/tmax*255) - 1]
          breakpointneg = negpal[round(tFDR5L/tmax*255) - 1]

          # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
          pospalalpha = colorRampPalette(c("#FF000000", breakpointpos), alpha=TRUE)(round(tFDR5L/tmax*255) -1)
          negpalalpha = colorRampPalette(c("#0000FF00", breakpointneg), alpha=TRUE)(round(tFDR5L/tmax*255) - 1)

          # Concatenate the two maps together for a complete map
          combinedpospal = c(pospalalpha, pospal[round(tFDR5L/tmax*255):length(pospal)])
          combinednegpal = c(negpalalpha, negpal[round(tFDR5L/tmax*255):length(negpal)])

        dir.create(paste0("fig_tmaps/multiple/",Mod,"/",Group), recursive = T)
          svg(paste0("fig_tmaps/multiple/",Mod,"/",Group,"/",Mod,"-csa.svg"), 
            height = 3, width = 9, bg = "transparent")
          sliceSeries(ncol = 7, 
            begin = round(dim(anatVol)[2]*0.15), 
            end = round(dim(anatVol)[2]*0.75),
            dimension = 2) %>%
          anatomy(anatVol, 
            low=anatVol_min+0.5, high=anatVol_max) %>%   
          overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
          contours(abs(get(paste0(Mod, "_stats1_", Group))), 
            levels=c(tFDR5L,tFDR01L), 
            col=c("black","yellow"), 
            lwd=0.9) %>% # Sagittal
          sliceSeries(ncol = 7, 
            begin = round(dim(anatVol)[1]*0.2), 
            end = round(dim(anatVol)[1]*0.75),
            dimension = 1) %>%
          anatomy(anatVol, 
            low=anatVol_min+0.5, high=anatVol_max) %>%   
          overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
          contours(abs(get(paste0(Mod, "_stats1_", Group))), 
            levels=c(tFDR5L,tFDR01L), 
            col=c("black","yellow"), 
            lwd=0.9) %>% # Axial
          sliceSeries(ncol = 10, 
            begin = round(dim(anatVol)[3]*0.3), 
            end = round(dim(anatVol)[3]*0.75),
            dimension = 3) %>%
          anatomy(anatVol, 
            low=anatVol_min+0.5, high=anatVol_max) %>%   
          overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
          contours(abs(get(paste0(Mod, "_stats1_", Group))), 
            levels=c(tFDR5L,tFDR01L), 
            col=c("black","yellow"), 
            lwd=0.9) %>%
          draw(layout = "row")
          dev.off()
        
      }

          } else {
        print("No contrast for this group")
          }
    }
  }

  for (Mod in Mods_onlyS) {

    for (Group in Groups) {

      rois=read_csv("Peaks/ROIs.csv") %>%
        filter(grepl(paste0("L",str_to_lower(Mod)),Model)) 
        if (nrow(rois) == 0) {
          print(paste("No ROIs found for", Mod, "and", Group))
          next
        }

        fdrMod=paste0("fdr",Mod)
        thresholds=attr(get(fdrMod), "thresholds")
        dimThr=dimnames(thresholds)[[2]][c(-1)]

        is_mod_age_or_session <- if (any(str_detect(dimThr, "Age"))) "Age" else if (any(str_detect(dimThr, "Session"))) "Session" else NA_character_

        column_name <- paste0("tvalue-", is_mod_age_or_session, ":",Sex_name)

        if (column_name %in% dimThr) {
        
          if (grepl("\\+", Group)) {
            filter_group <- gsub("\\+", "", Group)
          } else {
            filter_group <- Group
          }

          #rois <- rois %>%
          #  filter(grepl(paste0("_",filter_group,"$"), rois$Model))

          print(column_name)  
          assign(paste0(Mod, "_stats1_", Group), mincArray(get(Mod), column_name))

          tFDR01L <- Allthresholds[[Mod]]["0.01", column_name] %>% round(digits=2)
          tFDR5L <- Allthresholds[[Mod]]["0.05", column_name] %>% round(digits=2)
          tFDR1L <- Allthresholds[[Mod]]["0.1", column_name] %>% round(digits=2)
          tFDR2L <- Allthresholds[[Mod]]["0.2", column_name] %>% round(digits=2)
          tmax <- rois
          tmax <- rois$value %>% max() + 1
          anatVol_min <- min(anatVol)
          anatVol_max <- max(anatVol)
        
        if (tFDR2L %in% NA){  
          print("non significant at 20% FDR")
        } else {

          # Generate the default colourmaps
          pospal = colorRampPalette(c("red", "yellow"), alpha=TRUE)(255)
          negpal = colorRampPalette(c("blue", "turquoise1"), alpha=TRUE)(255)

          # Find the crossover point in the map where the colourmap switches to "non transparent"
          # Need to include the alpha term here, but its always opaque
          breakpointpos = pospal[round(tFDR2L/tmax*255) - 1]
          breakpointneg = negpal[round(tFDR2L/tmax*255) - 1]

          # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
          pospalalpha = colorRampPalette(c("#FF000000", breakpointpos), alpha=TRUE)(round(tFDR2L/tmax*255) -1)
          negpalalpha = colorRampPalette(c("#0000FF00", breakpointneg), alpha=TRUE)(round(tFDR2L/tmax*255) - 1)

          # Concatenate the two maps together for a complete map
          combinedpospal = c(pospalalpha, pospal[round(tFDR2L/tmax*255):length(pospal)])
          combinednegpal = c(negpalalpha, negpal[round(tFDR2L/tmax*255):length(negpal)])

          dir.create(paste0("fig_tmaps/single/",Mod,"/",Group), recursive = T)
          for (roi in 1:nrow(rois)) {
            svg(paste0("fig_tmaps/single/",Mod,"/",Group,"/",Mod,"-",rois$ROI_model[roi],".svg"), 
            height = 3, width = 3, bg = "transparent")
            sliceSeries(nrow = 1, ncol = 1, begin = rois$d2[roi], end = rois$d2[roi]) %>%
            anatomy(anatVol, low=anatVol_min+0.5, high=anatVol_max) %>%   
            overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
            draw()
            dev.off()
          }
        }

        if (tFDR5L %in% NA){
          print("non significant at 5% FDR")
        } else {

          # Generate the default colourmaps
          pospal = colorRampPalette(c("red", "yellow"), alpha=TRUE)(255)
          negpal = colorRampPalette(c("blue", "turquoise1"), alpha=TRUE)(255)

          # Find the crossover point in the map where the colourmap switches to "non transparent"
          # Need to include the alpha term here, but its always opaque
          breakpointpos = pospal[round(tFDR5L/tmax*255) - 1]
          breakpointneg = negpal[round(tFDR5L/tmax*255) - 1]

          # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
          pospalalpha = colorRampPalette(c("#FF000000", breakpointpos), alpha=TRUE)(round(tFDR5L/tmax*255) -1)
          negpalalpha = colorRampPalette(c("#0000FF00", breakpointneg), alpha=TRUE)(round(tFDR5L/tmax*255) - 1)

          # Concatenate the two maps together for a complete map
          combinedpospal = c(pospalalpha, pospal[round(tFDR5L/tmax*255):length(pospal)])
          combinednegpal = c(negpalalpha, negpal[round(tFDR5L/tmax*255):length(negpal)])

          dir.create(paste0("fig_tmaps/single/",Mod,"/",Group), recursive = T)
          for (roi in 1:nrow(rois)) {
            svg(paste0("fig_tmaps/single/",Mod,"/",Group,"/",Mod,"-",rois$ROI_model[roi],".svg"), 
            height = 3, width = 3, bg = "transparent")
            sliceSeries(nrow = 1, ncol = 1, begin = rois$d2[roi], end = rois$d2[roi]) %>%
            anatomy(anatVol, low=anatVol_min+0.5, high=anatVol_max) %>%   
            overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
            contours(abs(get(paste0(Mod, "_stats1_", Group))),
            levels=c(tFDR5L,tFDR01L),
            col=c("black","yellow"),
            lwd=0.9) %>%
            draw()
            dev.off()
          }
        }

        if (tFDR01L %in% NA){
          print("non significant at 1% FDR")
        } else {

          # Generate the default colourmaps
          pospal = colorRampPalette(c("red", "yellow"), alpha=TRUE)(255)
          negpal = colorRampPalette(c("blue", "turquoise1"), alpha=TRUE)(255)

          # Find the crossover point in the map where the colourmap switches to "non transparent"
          # Need to include the alpha term here, but its always opaque
          breakpointpos = pospal[round(tFDR5L/tmax*255) - 1]
          breakpointneg = negpal[round(tFDR5L/tmax*255) - 1]

          # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
          pospalalpha = colorRampPalette(c("#FF000000", breakpointpos), alpha=TRUE)(round(tFDR5L/tmax*255) -1)
          negpalalpha = colorRampPalette(c("#0000FF00", breakpointneg), alpha=TRUE)(round(tFDR5L/tmax*255) - 1)

          # Concatenate the two maps together for a complete map
          combinedpospal = c(pospalalpha, pospal[round(tFDR5L/tmax*255):length(pospal)])
          combinednegpal = c(negpalalpha, negpal[round(tFDR5L/tmax*255):length(negpal)])

          dir.create(paste0("fig_tmaps/single/",Mod,"/",Group), recursive = T)
          for (roi in 1:nrow(rois)) {
            svg(paste0("fig_tmaps/single/",Mod,"/",Group,"/",Mod,"-",rois$ROI_model[roi],".svg"), 
            height = 3, width = 3, bg = "transparent")
            sliceSeries(nrow = 1, ncol = 1, begin = rois$d2[roi], end = rois$d2[roi]) %>%
            anatomy(anatVol, low=anatVol_min+0.5, high=anatVol_max) %>%   
            overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
            contours(abs(get(paste0(Mod, "_stats1_", Group))),
            levels=c(tFDR5L,tFDR01L),
            col=c("black","yellow"),
            lwd=0.9) %>%
            draw()
            dev.off()
            }
          }
        }
# Three axis slices

      if (tFDR01L %in% NA){
        print("non significant at 1% FDR")
      } else {

          # Generate the default colourmaps
          pospal = colorRampPalette(c("red", "yellow"), alpha=TRUE)(255)
          negpal = colorRampPalette(c("blue", "turquoise1"), alpha=TRUE)(255)

          # Find the crossover point in the map where the colourmap switches to "non transparent"
          # Need to include the alpha term here, but its always opaque
          breakpointpos = pospal[round(tFDR5L/tmax*255) - 1]
          breakpointneg = negpal[round(tFDR5L/tmax*255) - 1]

          # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
          pospalalpha = colorRampPalette(c("#FF000000", breakpointpos), alpha=TRUE)(round(tFDR5L/tmax*255) -1)
          negpalalpha = colorRampPalette(c("#0000FF00", breakpointneg), alpha=TRUE)(round(tFDR5L/tmax*255) - 1)

          # Concatenate the two maps together for a complete map
          combinedpospal = c(pospalalpha, pospal[round(tFDR5L/tmax*255):length(pospal)])
          combinednegpal = c(negpalalpha, negpal[round(tFDR5L/tmax*255):length(negpal)])

        dir.create(paste0("fig_tmaps/multiple/",Mod,"/",Group), recursive = T)
          svg(paste0("fig_tmaps/multiple/",Mod,"/",Group,"/",Mod,"-csa.svg"), 
            height = 3, width = 9, bg = "transparent")
          sliceSeries(ncol = 7, 
            begin = round(dim(anatVol)[2]*0.15), 
            end = round(dim(anatVol)[2]*0.75),
            dimension = 2) %>%
          anatomy(anatVol, 
            low=anatVol_min+0.5, high=anatVol_max) %>%   
          overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
          contours(abs(get(paste0(Mod, "_stats1_", Group))),
            levels=c(tFDR5L,tFDR01L), 
            col=c("black","yellow"), 
            lwd=0.9) %>% # Sagittal
          sliceSeries(ncol = 7,
            begin = round(dim(anatVol)[1]*0.2), 
            end = round(dim(anatVol)[1]*0.75),
            dimension = 1) %>%
          anatomy(anatVol,
            low=anatVol_min+0.5, high=anatVol_max) %>%
          overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
          contours(abs(get(paste0(Mod, "_stats1_", Group))),
            levels=c(tFDR5L,tFDR01L), 
            col=c("black","yellow"), 
            lwd=0.9) %>% # Axial
          sliceSeries(ncol = 10,
            begin = round(dim(anatVol)[3]*0.3), 
            end = round(dim(anatVol)[3]*0.75),
            dimension = 3) %>%
          anatomy(anatVol,
            low=anatVol_min+0.5, high=anatVol_max) %>%
          overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
          contours(abs(get(paste0(Mod, "_stats1_", Group))),
            levels=c(tFDR5L,tFDR01L), 
            col=c("black","yellow"), 
            lwd=0.9) %>%
          draw(layout = "row")
          dev.off()
        }
      }
  }

# Poly --------------------------------------------------------------------
} else {

  for (poly in c(1,2)) {

    setwd(paste0(path,"/DBM/smooth_",smooth,"/fig_tmaps/"))
    dir.create(paste0("poly_",poly), recursive = T)
    setwd(paste0("poly_",poly))

    ## For models without sex
    for (Mod in Mods_wS) {

      for (Group in Groups) {

        if (poly == 1) {
          rois=read_csv(paste0(path,"/DBM/smooth_",smooth,"/Peaks/ROIs.csv")) %>%
            filter(grepl(paste0("L",str_to_lower(Mod)),Model))
        } else if (poly == 2) {
          rois=read_csv(paste0(path,"/DBM/smooth_",smooth,"/Peaks/ROIs.csv")) %>%
            filter(grepl(paste0("P",str_to_lower(Mod)),Model))
        }

        if (nrow(rois) == 0) {
          print(paste("No ROIs found for", Mod, "and", Group))
          next
        }

        fdrMod=paste0("fdr",Mod)
        thresholds=attr(get(fdrMod), "thresholds")
        dimThr=dimnames(thresholds)[[2]][c(-1)]

      is_mod_age_or_session <- if (any(str_detect(dimThr, "Age"))) "Age" else if (any(str_detect(dimThr, "Session"))) "Session" else NA_character_

      if (paste0("tvalue-poly(Age, 2)",poly,":Group",Group) %in% dimThr == TRUE) {
        column_name <- paste0("tvalue-poly(Age, 2)",poly,":Group",Group)
      } else if (paste0("tvalue-poly(Age, 2)",poly,Group) %in% dimThr == TRUE) {
        column_name <- paste0("tvalue-poly(Age, 2)",poly,Group)
      }

      if (column_name %in% dimThr) {
      
        if (grepl("\\+", Group)) {
          filter_group <- gsub("\\+", "", Group)
        } else {
          filter_group <- Group
        }

        #rois <- rois %>%
        #  filter(grepl(paste0("_",filter_group,"$"), rois$Model))

        print(column_name)  
        assign(paste0(Mod, "_stats1_", Group), mincArray(get(Mod), column_name))

        tFDR01L <- Allthresholds[[Mod]]["0.01", column_name] %>% round(digits=2)
        tFDR5L <- Allthresholds[[Mod]]["0.05", column_name] %>% round(digits=2)
        tFDR1L <- Allthresholds[[Mod]]["0.1", column_name] %>% round(digits=2)
        tFDR15L <- Allthresholds[[Mod]]["0.15", column_name] %>% round(digits=2)
        tFDR2L <- Allthresholds[[Mod]]["0.2", column_name] %>% round(digits=2)
        tmax <- rois$value %>% max()
        anatVol_min <- min(anatVol)
        anatVol_max <- max(anatVol)

      if (poly == 1) {
        # Generate the default colourmaps
        pospal = colorRampPalette(c(pos_poly1_1, pos_poly1_2), alpha=TRUE)(255)
        negpal = colorRampPalette(c(neg_poly1_1, neg_poly1_2), alpha=TRUE)(255)
        pos_poly = pos_poly1_1
        neg_poly = neg_poly1_1
      } else if (poly == 2) {
        # Generate the default colourmaps
        pospal = colorRampPalette(c(pos_poly2_1,pos_poly2_2), alpha=TRUE)(255)
        negpal = colorRampPalette(c(neg_poly2_1,neg_poly2_2), alpha=TRUE)(255)
        pos_poly = pos_poly2_1
        neg_poly = neg_poly2_1
      }

        if (tFDR2L %in% NA){
          print("non significant at 20% FDR")
        } else {

        # Find the crossover point in the map where the colourmap switches to "non transparent"
        # Need to include the alpha term here, but its always opaque
        breakpointpos = pospal[round(tFDR2L/tmax*255)]
        breakpointneg = negpal[round(tFDR2L/tmax*255)]

        # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
        pospalalpha = colorRampPalette(c(paste0(pos_poly,"00"), breakpointpos), alpha=TRUE)(round(tFDR2L/tmax*255))
        negpalalpha = colorRampPalette(c(paste0(neg_poly,"00"), breakpointneg), alpha=TRUE)(round(tFDR2L/tmax*255))

        # Concatenate the two maps together for a complete map
        combinedpospal = c(pospalalpha, pospal[round(tFDR2L/tmax*255):length(pospal)])
        combinednegpal = c(negpalalpha, negpal[round(tFDR2L/tmax*255):length(negpal)])

          dir.create(paste0("fig_tmaps/single/",Mod,"/",Group), recursive = T)
          for (roi in 1:nrow(rois)) {
            svg(paste0("fig_tmaps/single/",Mod,"/",Group,"/",Mod,"-",rois$ROI_model[roi],".svg"), 
              height = 3, width = 3, bg = "transparent")
            sliceSeries(nrow = 1, ncol = 1, begin = rois$d2[roi], end = rois$d2[roi]) %>%
            anatomy(anatVol, low=anatVol_min+0.5, high=anatVol_max) %>%   
            overlay(get(paste0(Mod, "_stats1_", Group)),
              low=0, 
              high=tmax, 
              symmetric = T,
              col = combinedpospal,
              rCol = combinednegpal,
            alpha = 0.6) %>%
            draw()
            dev.off()
          }
        }

        if (tFDR1L %in% NA){
          print("non significant at 5% FDR")
        } else {

        # Find the crossover point in the map where the colourmap switches to "non transparent"
        # Need to include the alpha term here, but its always opaque
        breakpointpos = pospal[round(tFDR1L/tmax*255)]
        breakpointneg = negpal[round(tFDR1L/tmax*255)]

        # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
        pospalalpha = colorRampPalette(c(paste0(pos_poly,"00"), breakpointpos), alpha=TRUE)(round(tFDR1L/tmax*255))
        negpalalpha = colorRampPalette(c(paste0(neg_poly,"00"), breakpointneg), alpha=TRUE)(round(tFDR1L/tmax*255))

        # Concatenate the two maps together for a complete map
        combinedpospal = c(pospalalpha, pospal[round(tFDR1L/tmax*255):length(pospal)])
        combinednegpal = c(negpalalpha, negpal[round(tFDR1L/tmax*255):length(negpal)])

          dir.create(paste0("fig_tmaps/single/",Mod,"/",Group), recursive = T)
          for (roi in 1:nrow(rois)) {
            svg(paste0("fig_tmaps/single/",Mod,"/",Group,"/",Mod,"-",rois$ROI_model[roi],".svg"), 
              height = 3, width = 3, bg = "transparent")
            sliceSeries(nrow = 1, ncol = 1, begin = rois$d2[roi], end = rois$d2[roi]) %>%
            anatomy(anatVol, low=anatVol_min+0.5, high=anatVol_max) %>%   
            overlay(get(paste0(Mod, "_stats1_", Group)),
              low=0, 
              high=tmax, 
              symmetric = T,
              col = combinedpospal,
              rCol = combinednegpal,
            alpha = 0.6) %>%
            contours(abs(get(paste0(Mod, "_stats1_", Group))), 
              levels=c(tFDR15L,tFDR1L), 
              col=c("black","yellow"), 
              lwd=0.9) %>% 
            draw()
            dev.off()
          }
        }

        if (tFDR5L %in% NA){
          print("non significant at 5% FDR")
        } else {

        # Find the crossover point in the map where the colourmap switches to "non transparent"
        # Need to include the alpha term here, but its always opaque
        breakpointpos = pospal[round(tFDR5L/tmax*255)]
        breakpointneg = negpal[round(tFDR5L/tmax*255)]

        # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
        pospalalpha = colorRampPalette(c(paste0(pos_poly,"00"), breakpointpos), alpha=TRUE)(round(tFDR5L/tmax*255))
        negpalalpha = colorRampPalette(c(paste0(neg_poly,"00"), breakpointneg), alpha=TRUE)(round(tFDR5L/tmax*255))

        # Concatenate the two maps together for a complete map
        combinedpospal = c(pospalalpha, pospal[round(tFDR5L/tmax*255):length(pospal)])
        combinednegpal = c(negpalalpha, negpal[round(tFDR5L/tmax*255):length(negpal)])

          dir.create(paste0("fig_tmaps/single/",Mod,"/",Group), recursive = T)
          for (roi in 1:nrow(rois)) {
            svg(paste0("fig_tmaps/single/",Mod,"/",Group,"/",Mod,"-",rois$ROI_model[roi],".svg"), 
              height = 3, width = 3, bg = "transparent")
            sliceSeries(nrow = 1, ncol = 1, begin = rois$d2[roi], end = rois$d2[roi]) %>%
            anatomy(anatVol, low=anatVol_min+0.5, high=anatVol_max) %>%   
            overlay(get(paste0(Mod, "_stats1_", Group)),
              low=0, 
              high=tmax, 
              symmetric = T,
              col = combinedpospal,
              rCol = combinednegpal,
            alpha = 0.6) %>%
            contours(abs(get(paste0(Mod, "_stats1_", Group))), 
              levels=tFDR5L, 
              col="black", 
              lwd=0.9) %>% 
            draw()
            dev.off()
          }
        }

        if (tFDR01L %in% NA){
          print("non significant at 1% FDR")
        } else {

        # Find the crossover point in the map where the colourmap switches to "non transparent"
        # Need to include the alpha term here, but its always opaque
        breakpointpos = pospal[round(tFDR5L/tmax*255)]
        breakpointneg = negpal[round(tFDR5L/tmax*255)]

        # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
        pospalalpha = colorRampPalette(c(paste0(pos_poly,"00"), breakpointpos), alpha=TRUE)(round(tFDR5L/tmax*255))
        negpalalpha = colorRampPalette(c(paste0(neg_poly,"00"), breakpointneg), alpha=TRUE)(round(tFDR5L/tmax*255))

        # Concatenate the two maps together for a complete map
        combinedpospal = c(pospalalpha, pospal[round(tFDR5L/tmax*255):length(pospal)])
        combinednegpal = c(negpalalpha, negpal[round(tFDR5L/tmax*255):length(negpal)])

          dir.create(paste0("fig_tmaps/single/",Mod,"/",Group), recursive = T)
          for (roi in 1:nrow(rois)) {
            svg(paste0("fig_tmaps/single/",Mod,"/",Group,"/",Mod,"-",rois$ROI_model[roi],".svg"), 
              height = 3, width = 3, bg = "transparent")
            sliceSeries(nrow = 1, ncol = 1, begin = rois$d2[roi], end = rois$d2[roi]) %>%
            anatomy(anatVol, low=anatVol_min+0.5, high=anatVol_max) %>%   
            overlay(get(paste0(Mod, "_stats1_", Group)),
              low=0, 
              high=tmax, 
              symmetric = T,
              col = combinedpospal,
              rCol = combinednegpal,
            alpha = 0.6) %>%
            contours(abs(get(paste0(Mod, "_stats1_", Group))), 
              levels=c(tFDR5L,tFDR01L), 
              col=c("black","yellow"), 
              lwd=0.9) %>%
            draw()
            dev.off()
          }
        }

# Three axis slices
      if (tFDR5L %in% NA){
        print("non significant at 1% FDR")
      } else {

        # Find the crossover point in the map where the colourmap switches to "non transparent"
        # Need to include the alpha term here, but its always opaque
        breakpointpos = pospal[round(tFDR5L/tmax*255)]
        breakpointneg = negpal[round(tFDR5L/tmax*255)]

        # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
        pospalalpha = colorRampPalette(c(paste0(pos_poly,"00"), breakpointpos), alpha=TRUE)(round(tFDR5L/tmax*255))
        negpalalpha = colorRampPalette(c(paste0(neg_poly,"00"), breakpointneg), alpha=TRUE)(round(tFDR5L/tmax*255))

        # Concatenate the two maps together for a complete map
        combinedpospal = c(pospalalpha, pospal[round(tFDR5L/tmax*255):length(pospal)])
        combinednegpal = c(negpalalpha, negpal[round(tFDR5L/tmax*255):length(negpal)])

        dir.create(paste0("fig_tmaps/multiple/",Mod,"/",Group), recursive = T)
          svg(paste0("fig_tmaps/multiple/",Mod,"/",Group,"/",Mod,"-csa.svg"), 
            height = 3, width = 9, bg = "transparent")
          sliceSeries(ncol = 7, 
            begin = round(dim(anatVol)[2]*0.15), 
            end = round(dim(anatVol)[2]*0.75),
            dimension = 2) %>%
          anatomy(anatVol, 
            low=anatVol_min+0.5, high=anatVol_max) %>%   
          overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
          contours(abs(get(paste0(Mod, "_stats1_", Group))), 
            levels=c(tFDR5L), 
            col=c("black"), 
            lwd=0.9) %>% # Sagittal
          sliceSeries(ncol = 7, 
            begin = round(dim(anatVol)[1]*0.2), 
            end = round(dim(anatVol)[1]*0.75),
            dimension = 1) %>%
          anatomy(anatVol, 
            low=anatVol_min+0.5, high=anatVol_max) %>%   
          overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
          contours(abs(get(paste0(Mod, "_stats1_", Group))), 
            levels=c(tFDR5L), 
            col=c("black"), 
            lwd=0.9) %>% # Axial
          sliceSeries(ncol = 10, 
            begin = round(dim(anatVol)[3]*0.3), 
            end = round(dim(anatVol)[3]*0.75),
            dimension = 3) %>%
          anatomy(anatVol, 
            low=anatVol_min+0.5, high=anatVol_max) %>%   
          overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
          contours(abs(get(paste0(Mod, "_stats1_", Group))), 
            levels=c(tFDR5L), 
            col=c("black"), 
            lwd=0.9) %>%
          draw(layout = "row")
          dev.off()
        
      }

      } else {
        print("No contrast for this group")
      }

      }

    for (Mod in Mods_S){

      for (Group in Groups) {

        if (poly == 1) {
          rois=read_csv(paste0(path,"/DBM/smooth_",smooth,"/Peaks/ROIs.csv")) %>%
            filter(grepl(paste0("L",str_to_lower(Mod)),Model))
        } else if (poly == 2) {
          rois=read_csv(paste0(path,"/DBM/smooth_",smooth,"/Peaks/ROIs.csv")) %>%
            filter(grepl(paste0("P",str_to_lower(Mod)),Model))
        }

        if (nrow(rois) == 0) {
          print(paste("No ROIs found for", Mod, "and", Group))
          next
        }

        fdrMod=paste0("fdr",Mod)
        thresholds=attr(get(fdrMod), "thresholds")
        dimThr=dimnames(thresholds)[[2]][c(-1)]

      is_mod_age_or_session <- if (any(str_detect(dimThr, "Age"))) "Age" else if (any(str_detect(dimThr, "Session"))) "Session" else NA_character_

      if (paste0("tvalue-poly(Age, 2)", poly, ":",Sex_name) %in% dimThr == TRUE) {
        column_name <- paste0("tvalue-poly(Age, 2)", poly, ":",Sex_name)
      } else if (paste0("tvalue-poly(Age, 2)", poly, ":Group", Group, ":",Sex_name) %in% dimThr == TRUE) {
        column_name <- paste0("tvalue-poly(Age, 2)", poly, ":Group", Group, ":",Sex_name)
      }

      if (column_name %in% dimThr) {
      
        if (grepl("\\+", Group)) {
          filter_group <- gsub("\\+", "", Group)
        } else {
          filter_group <- Group
        }

        #rois <- rois %>%
        #  filter(grepl(paste0("_",filter_group,"$"), rois$Model))

        print(column_name)  
        assign(paste0(Mod, "_stats1_", Group), mincArray(get(Mod), column_name))

        tFDR01L <- Allthresholds[[Mod]]["0.01", column_name] %>% round(digits=2)
        tFDR5L <- Allthresholds[[Mod]]["0.05", column_name] %>% round(digits=2)
        tFDR1L <- Allthresholds[[Mod]]["0.1", column_name] %>% round(digits=2)
        tFDR2L <- Allthresholds[[Mod]]["0.2", column_name] %>% round(digits=2)
        tmax <- rois$value %>% max() + 1
        anatVol_min <- min(anatVol)
        anatVol_max <- max(anatVol)

      if (poly == 1) {
        # Generate the default colourmaps
        pospal = colorRampPalette(c(pos_poly1_1, pos_poly1_2), alpha=TRUE)(255)
        negpal = colorRampPalette(c(neg_poly1_1, neg_poly1_2), alpha=TRUE)(255)
        pos_poly = pos_poly1_1
        neg_poly = neg_poly1_1
      } else if (poly == 2) {
        # Generate the default colourmaps
        pospal = colorRampPalette(c(pos_poly2_1,pos_poly2_2), alpha=TRUE)(255)
        negpal = colorRampPalette(c(neg_poly2_1,neg_poly2_2), alpha=TRUE)(255)
        pos_poly = pos_poly2_1
        neg_poly = neg_poly2_1
      }

        if (tFDR2L %in% NA){
          print("non significant at 20% FDR")
        } else {

        # Find the crossover point in the map where the colourmap switches to "non transparent"
        # Need to include the alpha term here, but its always opaque
        breakpointpos = pospal[round(tFDR2L/tmax*255) - 20]
        breakpointneg = negpal[round(tFDR2L/tmax*255) - 1]

        # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
        pospalalpha = colorRampPalette(c(paste0(pos_poly,"00"), breakpointpos), alpha=TRUE)(round(tFDR2L/tmax*255) -1)
        negpalalpha = colorRampPalette(c(paste0(neg_poly,"00"), breakpointneg), alpha=TRUE)(round(tFDR2L/tmax*255) - 1)

        # Concatenate the two maps together for a complete map
        combinedpospal = c(pospalalpha, pospal[round(tFDR2L/tmax*255):length(pospal)])
        combinednegpal = c(negpalalpha, negpal[round(tFDR2L/tmax*255):length(negpal)])

          dir.create(paste0("fig_tmaps/single/",Mod,"/",Group), recursive = T)
          for (roi in 1:nrow(rois)) {
            svg(paste0("fig_tmaps/single/",Mod,"/",Group,"/",Mod,"-",rois$ROI_model[roi],".svg"), 
              height = 3, width = 3, bg = "transparent")
            sliceSeries(nrow = 1, ncol = 1, begin = rois$d2[roi], end = rois$d2[roi]) %>%
            anatomy(anatVol, low=anatVol_min+0.5, high=anatVol_max) %>%   
            overlay(get(paste0(Mod, "_stats1_", Group)),
              low=0, 
              high=tmax, 
              symmetric = T,
              col = combinedpospal,
              rCol = combinednegpal,
            alpha = 0.6) %>%
            draw()
            dev.off()
          }
        }

        if (tFDR5L %in% NA){
          print("non significant at 5% FDR")
        } else {

        # Find the crossover point in the map where the colourmap switches to "non transparent"
        # Need to include the alpha term here, but its always opaque
        breakpointpos = pospal[round(tFDR5L/tmax*255) - 20]
        breakpointneg = negpal[round(tFDR5L/tmax*255) - 1]

        # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
        pospalalpha = colorRampPalette(c(paste0(pos_poly,"00"), breakpointpos), alpha=TRUE)(round(tFDR5L/tmax*255) -1)
        negpalalpha = colorRampPalette(c(paste0(neg_poly,"00"), breakpointneg), alpha=TRUE)(round(tFDR5L/tmax*255) - 1)

        # Concatenate the two maps together for a complete map
        combinedpospal = c(pospalalpha, pospal[round(tFDR5L/tmax*255):length(pospal)])
        combinednegpal = c(negpalalpha, negpal[round(tFDR5L/tmax*255):length(negpal)])

          dir.create(paste0("fig_tmaps/single/",Mod,"/",Group), recursive = T)
          for (roi in 1:nrow(rois)) {
            svg(paste0("fig_tmaps/single/",Mod,"/",Group,"/",Mod,"-",rois$ROI_model[roi],".svg"), 
              height = 3, width = 3, bg = "transparent")
            sliceSeries(nrow = 1, ncol = 1, begin = rois$d2[roi], end = rois$d2[roi]) %>%
            anatomy(anatVol, low=anatVol_min+0.5, high=anatVol_max) %>%   
            overlay(get(paste0(Mod, "_stats1_", Group)),
              low=0, 
              high=tmax, 
              symmetric = T,
              col = combinedpospal,
              rCol = combinednegpal,
            alpha = 0.6) %>%
            contours(abs(get(paste0(Mod, "_stats1_", Group))), 
              levels=tFDR5L, 
              col="black", 
              lwd=0.9) %>% 
            draw()
            dev.off()
          }
        }

        if (tFDR01L %in% NA){
          print("non significant at 1% FDR")
        } else {

        # Find the crossover point in the map where the colourmap switches to "non transparent"
        # Need to include the alpha term here, but its always opaque
        breakpointpos = pospal[round(tFDR5L/tmax*255) - 20]
        breakpointneg = negpal[round(tFDR5L/tmax*255) - 1]

        # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
        pospalalpha = colorRampPalette(c(paste0(pos_poly,"00"), breakpointpos), alpha=TRUE)(round(tFDR5L/tmax*255) -1)
        negpalalpha = colorRampPalette(c(paste0(neg_poly,"00"), breakpointneg), alpha=TRUE)(round(tFDR5L/tmax*255) - 1)

        # Concatenate the two maps together for a complete map
        combinedpospal = c(pospalalpha, pospal[round(tFDR5L/tmax*255):length(pospal)])
        combinednegpal = c(negpalalpha, negpal[round(tFDR5L/tmax*255):length(negpal)])

          dir.create(paste0("fig_tmaps/single/",Mod,"/",Group), recursive = T)
          for (roi in 1:nrow(rois)) {
            svg(paste0("fig_tmaps/single/",Mod,"/",Group,"/",Mod,"-",rois$ROI_model[roi],".svg"), 
              height = 3, width = 3, bg = "transparent")
            sliceSeries(nrow = 1, ncol = 1, begin = rois$d2[roi], end = rois$d2[roi]) %>%
            anatomy(anatVol, low=anatVol_min+0.5, high=anatVol_max) %>%   
            overlay(get(paste0(Mod, "_stats1_", Group)),
              low=0, 
              high=tmax, 
              symmetric = T,
              col = combinedpospal,
              rCol = combinednegpal,
            alpha = 0.6) %>%
            contours(abs(get(paste0(Mod, "_stats1_", Group))), 
              levels=c(tFDR5L,tFDR01L), 
              col=c("black","yellow"), 
              lwd=0.9) %>%
            draw()
            dev.off()
          }
        }

# Three axis slices
      if (tFDR5L %in% NA){
        print("non significant at 1% FDR")
      } else {

        # Generate the default colourmaps
        pospal = colorRampPalette(c("#f40752", "#f9ab8f"), alpha=TRUE)(255)
        negpal = colorRampPalette(c("#3d8bff", "#ffcb6b"), alpha=TRUE)(255)

        # Find the crossover point in the map where the colourmap switches to "non transparent"
        # Need to include the alpha term here, but its always opaque
        breakpointpos = pospal[round(tFDR5L/tmax*255) - 20]
        breakpointneg = negpal[round(tFDR5L/tmax*255) - 1]

        # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
        pospalalpha = colorRampPalette(c(paste0(pos_poly,"00"), breakpointpos), alpha=TRUE)(round(tFDR5L/tmax*255) -1)
        negpalalpha = colorRampPalette(c(paste0(neg_poly,"00"), breakpointneg), alpha=TRUE)(round(tFDR5L/tmax*255) - 1)

        # Concatenate the two maps together for a complete map
        combinedpospal = c(pospalalpha, pospal[round(tFDR5L/tmax*255):length(pospal)])
        combinednegpal = c(negpalalpha, negpal[round(tFDR5L/tmax*255):length(negpal)])

        dir.create(paste0("fig_tmaps/multiple/",Mod,"/",Group), recursive = T)
          svg(paste0("fig_tmaps/multiple/",Mod,"/",Group,"/",Mod,"-csa.svg"), 
            height = 3, width = 9, bg = "transparent")
          sliceSeries(ncol = 7, 
            begin = round(dim(anatVol)[2]*0.15), 
            end = round(dim(anatVol)[2]*0.75),
            dimension = 2) %>%
          anatomy(anatVol, 
            low=anatVol_min+0.5, high=anatVol_max) %>%   
          overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
          contours(abs(get(paste0(Mod, "_stats1_", Group))), 
            levels=c(tFDR5L), 
            col=c("black"), 
            lwd=0.9) %>% # Sagittal
          sliceSeries(ncol = 7, 
            begin = round(dim(anatVol)[1]*0.2), 
            end = round(dim(anatVol)[1]*0.75),
            dimension = 1) %>%
          anatomy(anatVol, 
            low=anatVol_min+0.5, high=anatVol_max) %>%   
          overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
          contours(abs(get(paste0(Mod, "_stats1_", Group))), 
            levels=c(tFDR5L), 
            col=c("black"), 
            lwd=0.9) %>% # Axial
          sliceSeries(ncol = 10, 
            begin = round(dim(anatVol)[3]*0.3), 
            end = round(dim(anatVol)[3]*0.75),
            dimension = 3) %>%
          anatomy(anatVol, 
            low=anatVol_min+0.5, high=anatVol_max) %>%   
          overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
          contours(abs(get(paste0(Mod, "_stats1_", Group))), 
            levels=c(tFDR5L), 
            col=c("black"), 
            lwd=0.9) %>%
          draw(layout = "row")
          dev.off()
        
      }

      } else {
        print("No contrast for this group")
      }

      }

    }

    for (Mod in Mods_onlyS) {
      for (Group in Groups) {

        if (poly == 1) {
          rois=read_csv(paste0(path,"/DBM/smooth_",smooth,"/Peaks/ROIs.csv")) %>%
            filter(grepl(paste0("L",str_to_lower(Mod)),Model))
        } else if (poly == 2) {
          rois=read_csv(paste0(path,"/DBM/smooth_",smooth,"/Peaks/ROIs.csv")) %>%
            filter(grepl(paste0("P",str_to_lower(Mod)),Model))
        }

        if (nrow(rois) == 0) {
          print(paste("No ROIs found for", Mod, "and", Group))
          next
        }

        fdrMod=paste0("fdr",Mod)
        thresholds=attr(get(fdrMod), "thresholds")
        dimThr=dimnames(thresholds)[[2]][c(-1)]

      is_mod_age_or_session <- if (any(str_detect(dimThr, "Age"))) "Age" else if (any(str_detect(dimThr, "Session"))) "Session" else NA_character_

      column_name <- paste0("tvalue-poly(Age, 2)", poly, ":",Sex_name)

      if (column_name %in% dimThr) {
      
        if (grepl("\\+", Group)) {
          filter_group <- gsub("\\+", "", Group)
        } else {
          filter_group <- Group
        }

        #rois <- rois %>%
        #  filter(grepl(paste0("_",filter_group,"$"), rois$Model))

        print(column_name)  
        assign(paste0(Mod, "_stats1_", Group), mincArray(get(Mod), column_name))

        tFDR01L <- Allthresholds[[Mod]]["0.01", column_name] %>% round(digits=2)
        tFDR5L <- Allthresholds[[Mod]]["0.05", column_name] %>% round(digits=2)
        tFDR1L <- Allthresholds[[Mod]]["0.1", column_name] %>% round(digits=2)
        tFDR2L <- Allthresholds[[Mod]]["0.2", column_name] %>% round(digits=2)
        tmax <- rois$value %>% max() + 1
        anatVol_min <- min(anatVol)
        anatVol_max <- max(anatVol)

      if (poly == 1) {
        # Generate the default colourmaps
        pospal = colorRampPalette(c(pos_poly1_1, pos_poly1_2), alpha=TRUE)(255)
        negpal = colorRampPalette(c(neg_poly1_1, neg_poly1_2), alpha=TRUE)(255)
        pos_poly = pos_poly1_1
        neg_poly = neg_poly1_1
      } else if (poly == 2) {
        # Generate the default colourmaps
        pospal = colorRampPalette(c(pos_poly2_1,pos_poly2_2), alpha=TRUE)(255)
        negpal = colorRampPalette(c(neg_poly2_1,neg_poly2_2), alpha=TRUE)(255)
        pos_poly = pos_poly2_1
        neg_poly = neg_poly2_1
      }

        if (tFDR2L %in% NA){
          print("non significant at 20% FDR")
        } else {

        # Find the crossover point in the map where the colourmap switches to "non transparent"
        # Need to include the alpha term here, but its always opaque
        breakpointpos = pospal[round(tFDR2L/tmax*255) - 20]
        breakpointneg = negpal[round(tFDR2L/tmax*255) - 1]

        # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
        pospalalpha = colorRampPalette(c(paste0(pos_poly,"00"), breakpointpos), alpha=TRUE)(round(tFDR2L/tmax*255) -1)
        negpalalpha = colorRampPalette(c(paste0(neg_poly,"00"), breakpointneg), alpha=TRUE)(round(tFDR2L/tmax*255) - 1)

        # Concatenate the two maps together for a complete map
        combinedpospal = c(pospalalpha, pospal[round(tFDR2L/tmax*255):length(pospal)])
        combinednegpal = c(negpalalpha, negpal[round(tFDR2L/tmax*255):length(negpal)])

          dir.create(paste0("fig_tmaps/single/",Mod,"/",Group), recursive = T)
          for (roi in 1:nrow(rois)) {
            svg(paste0("fig_tmaps/single/",Mod,"/",Group,"/",Mod,"-",rois$ROI_model[roi],".svg"), 
              height = 3, width = 3, bg = "transparent")
            sliceSeries(nrow = 1, ncol = 1, begin = rois$d2[roi], end = rois$d2[roi]) %>%
            anatomy(anatVol, low=anatVol_min+0.5, high=anatVol_max) %>%   
            overlay(get(paste0(Mod, "_stats1_", Group)),
              low=0, 
              high=tmax, 
              symmetric = T,
              col = combinedpospal,
              rCol = combinednegpal,
            alpha = 0.6) %>%
            draw()
            dev.off()
          }
        }

        if (tFDR5L %in% NA){
          print("non significant at 5% FDR")
        } else {

        # Generate the default colourmaps
        pospal = colorRampPalette(c("#f40752", "#f9ab8f"), alpha=TRUE)(255)
        negpal = colorRampPalette(c("#3d8bff", "#ffcb6b"), alpha=TRUE)(255)

        # Find the crossover point in the map where the colourmap switches to "non transparent"
        # Need to include the alpha term here, but its always opaque
        breakpointpos = pospal[round(tFDR5L/tmax*255) - 20]
        breakpointneg = negpal[round(tFDR5L/tmax*255) - 1]

        # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
        pospalalpha = colorRampPalette(c(paste0(pos_poly,"00"), breakpointpos), alpha=TRUE)(round(tFDR5L/tmax*255) -1)
        negpalalpha = colorRampPalette(c(paste0(neg_poly,"00"), breakpointneg), alpha=TRUE)(round(tFDR5L/tmax*255) - 1)

        # Concatenate the two maps together for a complete map
        combinedpospal = c(pospalalpha, pospal[round(tFDR5L/tmax*255):length(pospal)])
        combinednegpal = c(negpalalpha, negpal[round(tFDR5L/tmax*255):length(negpal)])

          dir.create(paste0("fig_tmaps/single/",Mod,"/",Group), recursive = T)
          for (roi in 1:nrow(rois)) {
            svg(paste0("fig_tmaps/single/",Mod,"/",Group,"/",Mod,"-",rois$ROI_model[roi],".svg"), 
              height = 3, width = 3, bg = "transparent")
            sliceSeries(nrow = 1, ncol = 1, begin = rois$d2[roi], end = rois$d2[roi]) %>%
            anatomy(anatVol, low=anatVol_min+0.5, high=anatVol_max) %>%   
            overlay(get(paste0(Mod, "_stats1_", Group)),
              low=0, 
              high=tmax, 
              symmetric = T,
              col = combinedpospal,
              rCol = combinednegpal,
            alpha = 0.6) %>%
            contours(abs(get(paste0(Mod, "_stats1_", Group))), 
              levels=tFDR5L, 
              col="black", 
              lwd=0.9) %>% 
            draw()
            dev.off()
          }
        }

        if (tFDR01L %in% NA){
          print("non significant at 1% FDR")
        } else {

        # Find the crossover point in the map where the colourmap switches to "non transparent"
        # Need to include the alpha term here, but its always opaque
        breakpointpos = pospal[round(tFDR5L/tmax*255) - 20]
        breakpointneg = negpal[round(tFDR5L/tmax*255) - 1]

        # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
        pospalalpha = colorRampPalette(c(paste0(pos_poly,"00"), breakpointpos), alpha=TRUE)(round(tFDR5L/tmax*255) -1)
        negpalalpha = colorRampPalette(c(paste0(neg_poly,"00"), breakpointneg), alpha=TRUE)(round(tFDR5L/tmax*255) - 1)

        # Concatenate the two maps together for a complete map
        combinedpospal = c(pospalalpha, pospal[round(tFDR5L/tmax*255):length(pospal)])
        combinednegpal = c(negpalalpha, negpal[round(tFDR5L/tmax*255):length(negpal)])

          dir.create(paste0("fig_tmaps/single/",Mod,"/",Group), recursive = T)
          for (roi in 1:nrow(rois)) {
            svg(paste0("fig_tmaps/single/",Mod,"/",Group,"/",Mod,"-",rois$ROI_model[roi],".svg"), 
              height = 3, width = 3, bg = "transparent")
            sliceSeries(nrow = 1, ncol = 1, begin = rois$d2[roi], end = rois$d2[roi]) %>%
            anatomy(anatVol, low=anatVol_min+0.5, high=anatVol_max) %>%   
            overlay(get(paste0(Mod, "_stats1_", Group)),
              low=0, 
              high=tmax, 
              symmetric = T,
              col = combinedpospal,
              rCol = combinednegpal,
            alpha = 0.6) %>%
            contours(abs(get(paste0(Mod, "_stats1_", Group))), 
              levels=c(tFDR5L,tFDR01L), 
              col=c("black","yellow"), 
              lwd=0.9) %>%
            draw()
            dev.off()
          }
        }

# Three axis slices
      if (tFDR5L %in% NA){
        print("non significant at 1% FDR")
      } else {

        # Find the crossover point in the map where the colourmap switches to "non transparent"
        # Need to include the alpha term here, but its always opaque
        breakpointpos = pospal[round(tFDR5L/tmax*255) - 20]
        breakpointneg = negpal[round(tFDR5L/tmax*255) - 1]

        # Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
        pospalalpha = colorRampPalette(c(paste0(pos_poly,"00"), breakpointpos), alpha=TRUE)(round(tFDR5L/tmax*255) -1)
        negpalalpha = colorRampPalette(c(paste0(neg_poly,"00"), breakpointneg), alpha=TRUE)(round(tFDR5L/tmax*255) - 1)

        # Concatenate the two maps together for a complete map
        combinedpospal = c(pospalalpha, pospal[round(tFDR5L/tmax*255):length(pospal)])
        combinednegpal = c(negpalalpha, negpal[round(tFDR5L/tmax*255):length(negpal)])

        dir.create(paste0("fig_tmaps/multiple/",Mod,"/",Group), recursive = T)
          svg(paste0("fig_tmaps/multiple/",Mod,"/",Group,"/",Mod,"-csa.svg"), 
            height = 3, width = 9, bg = "transparent")
          sliceSeries(ncol = 7, 
            begin = round(dim(anatVol)[2]*0.15), 
            end = round(dim(anatVol)[2]*0.75),
            dimension = 2) %>%
          anatomy(anatVol, 
            low=anatVol_min+0.5, high=anatVol_max) %>%   
          overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
          contours(abs(get(paste0(Mod, "_stats1_", Group))), 
            levels=c(tFDR5L), 
            col=c("black"), 
            lwd=0.9) %>% # Sagittal
          sliceSeries(ncol = 7, 
            begin = round(dim(anatVol)[1]*0.2), 
            end = round(dim(anatVol)[1]*0.75),
            dimension = 1) %>%
          anatomy(anatVol, 
            low=anatVol_min+0.5, high=anatVol_max) %>%   
          overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
          contours(abs(get(paste0(Mod, "_stats1_", Group))), 
            levels=c(tFDR5L), 
            col=c("black"), 
            lwd=0.9) %>% # Axial
          sliceSeries(ncol = 10, 
            begin = round(dim(anatVol)[3]*0.3), 
            end = round(dim(anatVol)[3]*0.75),
            dimension = 3) %>%
          anatomy(anatVol, 
            low=anatVol_min+0.5, high=anatVol_max) %>%   
          overlay(get(paste0(Mod, "_stats1_", Group)),
            low=0, 
            high=tmax, 
            symmetric = T,
            col = combinedpospal,
            rCol = combinednegpal,
            alpha = 0.6) %>%
          contours(abs(get(paste0(Mod, "_stats1_", Group))), 
            levels=c(tFDR5L), 
            col=c("black"), 
            lwd=0.9) %>%
          draw(layout = "row")
          dev.off()
        
      }

      } else {
        print("No contrast for this group")
      }

      }
    }

  }
  }
}
