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

smooth="1mm"
path <- "/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/smri/DBM_invivo"
atlas=paste0(path,"/DBM/tomodel/atlas_labels_registered.mnc")
mask=paste0(path,"/jacobians/output/secondlevel/final/average/mask_shapeupdate.mnc")
anatVol=mincArray(mincGetVolume(paste0(path,"/DBM/tomodel/template_sharpen_shapeupdate_brain.mnc")))
setwd(paste0(path,"/DBM/smooth_",smooth))
dir.create("data", recursive = T)

# Load data ---------------------------------------------------------------

load("DBM_data.RData")

# Obtaining tmaps figures ------------------------------------------------

# lowerthreshold is the 5% FDR
# upperthreshold is the 1% FDR, but could be MAX t-stat instead
lowerthreshold = 2.5
upperthreshold = 6
dim1_begin = 30
dim1_end = 60
dim2_begin = 70
dim2_end = 110
dim3_begin = 40
dim3_end = 70
model = mincArray(Model_ses, "tvalue-Sessionses-T2:GroupMor")
contour1 = 2.5
contour2 = 3.1

# Generate the default colourmaps
pospal = colorRampPalette(c("red", "yellow"), alpha=TRUE)(255)
negpal = colorRampPalette(c("blue", "turquoise1"), alpha=TRUE)(255)

# Find the crossover point in the map where the colourmap switches to "non transparent"
# Need to include the alpha term here, but its always opaque
breakpointpos = pospal[round(lowerthreshold/upperthreshold*255) - 1]
breakpointneg = negpal[round(lowerthreshold/upperthreshold*255) - 1]

# Generate a subset of the colourmap now which ramps from the same starting point and ends at breakpoint, with full opacity
pospalalpha = colorRampPalette(c("#FF000000", breakpointpos), alpha=TRUE)(round(lowerthreshold/upperthreshold*255) + 20)
negpalalpha = colorRampPalette(c("#0000FF00", breakpointneg), alpha=TRUE)(round(lowerthreshold/upperthreshold*255) + 20)

# Concatenate the two maps together for a complete map
combinedpospal = c(pospalalpha, pospal[round(lowerthreshold/upperthreshold*255):length(pospal)])
combinednegpal = c(negpalalpha, negpal[round(lowerthreshold/upperthreshold*255):length(negpal)])

# Do a sliceseries with overlay starting at 0 and ending at upperthreshold
svg(paste0("fig_tmaps/Brain_thresh_rows.svg"), height = 3, width = 7, bg = "transparent")
sliceSeries( ncol= 5, begin = dim2_begin, end = dim2_end, dimension = 2) %>%
  anatomy(anatVol, low=1, high=4) %>%
  addtitle("Coronal") %>%
  overlay(model,
          low = 0,
          high = upperthreshold,
          col = combinedpospal,
          rCol = combinednegpal,
          symmetric = T) %>%
  contours(abs(mincArray(model, predictor)), levels=c(contour1,contour2), lwd=0.8, col=c("black","yellow")) %>%
  sliceSeries(ncol= 5, begin = dim1_begin, end = dim1_end, dimension = 1) %>%
  anatomy(anatVol, low=1, high=4) %>%
  addtitle("Sagittal") %>%
  overlay(model,
          low = 0,
          high = upperthreshold,
          col = combinedpospal,
          rCol = combinednegpal,
          symmetric = T) %>%
  contours(abs(mincArray(model, predictor)), levels=c(contour1,contour2), lwd=0.8, col=c("black","yellow")) %>%
  sliceSeries(ncol= 5, begin = 30, end = 70, dimension = 3) %>%
  anatomy(anatVol, low=1, high=4) %>%
  addtitle("Axial") %>%
  overlay(model,
          low = 0,
          high = upperthreshold,
          col = combinedpospal,
          rCol = combinednegpal,
          symmetric = T) %>%
  legend("Linear Age Component") %>%
  contours(abs(mincArray(model, predictor)), levels=c(contour1,contour2), lwd=0.7, col=c("black","yellow")) %>%
  legend("FDR 5%") %>%
  draw(layout = "row")
dev.off()

