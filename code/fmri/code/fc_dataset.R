#!/usr/bin/env Rscript

# Clear workspace
rm(list = ls())
# Save original parameters
op <- par()
# Set working directory
dir.create("NBR/fc-matrices",recursive = T)
system("chmod 777 -R NBR/")
setwd("/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/fmri/NBR")

file.copy(from="/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/smri/DBM_invivo/DBM/data/DBM_dataset.csv", 
	  to=getwd(), 
          overwrite = TRUE, recursive = FALSE, 
          copy.mode = TRUE)

# Libraries
library(psych)
library(tidyverse)

# Input data
data_dir <- file.path(getwd())

# Cleaning the DBM_dataset to match the FC_dataset
temp_df <- read.csv(file.path(data_dir,"DBM_dataset.csv")) %>% filter(IN == "yes") %>% select(-c(Subject,IN))
temp_df %>% 
        write_csv(file.path(data_dir,"fc-matrices","RID_dataset.csv"))

# Read phenotypic data
p_df <- read.csv(file.path(data_dir,"fc-matrices","RID_dataset.csv"))
# Correct leftward zeros
p_df$IDses <- paste0(sapply(1:nrow(p_df), function(x) paste0("sub-",as.numeric(strsplit(p_df$RID[x],"sub-")[[1]][2]))),
                     "_",p_df$Ses)

# Read FC data
fc_ls <- list.files(path = file.path(data_dir,"fc-matrices"),
                    pattern = "FC_matrix.csv",
                    recursive = T,
                    full.names = T)
fc_n <- length(fc_ls)
# Extract features from file name
fc_df <- data.frame(RID = sapply(1:fc_n, function(x) strsplit(basename(fc_ls[x]), "_ses-")[[1]][1]),
                    Ses = basename(dirname(dirname(fc_ls))),
                    Group = basename(dirname(fc_ls)),
                    Intake = as.character(NA),
                    Batch = as.character(NA),
                    Sex = as.character(NA),
                    Age = as.numeric(NA),
                    stringsAsFactors = F)
# Concatenate ID and session as unique indetifier for subject/session
fc_df$IDses <- paste0(fc_df$RID,"_",fc_df$Ses)

# Match phenotypic data with FC data
mch_id <- match(fc_df$IDses,p_df$IDses)

# Refill phenotypic data session-wise
fc_df$Intake <- p_df$Intake[mch_id]
fc_df$Batch <- p_df$Batch[mch_id]
fc_df$Sex <- p_df$Sex[mch_id]
fc_df$Age <- p_df$Age[mch_id]

# Save FC matched data.frame
write.csv(x = fc_df[,-ncol(fc_df)],
          file = file.path(data_dir,"fc_dataset.csv"),
          row.names = F, quote = F)

# Read FC dimensions
fc_dim <- dim(as.matrix(read.csv(file = fc_ls[1], header = F, skip = 1)[,-1]))
fc_vol <- array(data = as.numeric(NA), dim = c(fc_dim,fc_n))
# Concatenate matrices
for(ii in 1:fc_n) fc_vol[,,ii] <- as.matrix(read.csv(file = fc_ls[ii], header = F, skip = 1)[,-1])
# Apply Fisher's r-to-z transform
fc_vol <- fisherz(fc_vol)
# Write volume into RDS file
saveRDS(object = fc_vol,
        file = file.path(data_dir,"fc_matrices.rds"))

# give permissions
system("chmod 777 -R *")
