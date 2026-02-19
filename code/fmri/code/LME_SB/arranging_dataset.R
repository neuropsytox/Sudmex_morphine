library(tidyverse)

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

# Input data
data_dir <- file.path(getwd())

# Cleaning the DBM_dataset to match the FC_dataset
temp_df <- read.csv(file.path(data_dir,"DBM_dataset.csv")) %>% filter(IN == "yes") %>% 
  select(-c(Subject,IN))  %>% rename("Ses" =	"Session") 

path <- "/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/fmri"
setwd(path)
dir.create(paste0("code/LME_SB/datasets/"), recursive=T)

fc_csv <- temp_df

if (!file.exists("Atlas/ROIs/rois_seed_combined.txt")) {
  stop("File 'Atlas/ROIs/rois_seed_combined.txt' does not exist.")
}

rois <- read_table("Atlas/ROIs/rois_seed_combined.txt",  col_names = FALSE) %>%
  mutate(rois = str_replace(X1, ".*?/", "")) %>%
  mutate(rois = str_replace(rois, "_peaks.*", "")) %>% select(rois) %>% pull()

# Create directories
c(1,2,3) %>% map(~ dir.create(paste0("Seed_based/ses-T",.x), recursive=T) )

for(roi in rois){
 # Arranging
 full_path=list.files(path = paste0(path,"/Seed_based"), pattern=roi, recursive=T, full.names=T) %>% as_tibble()

 detect_files <- full_path %>% mutate(file = value %>% basename(),
   RID = file %>% str_split(pattern="_") %>% map(~ .x %>% .[1]) %>% reduce(rbind),
   Ses = file %>% str_split(pattern="_") %>% map(~ .x %>% .[2]) %>% reduce(rbind), .before=1 ) %>%
   rename("InputFile" =	"value") %>% select(-(file))

 fc_input <- left_join(fc_csv,detect_files,by=c("RID","Ses")) %>% rename("Subj" = "RID") %>% drop_na()

 write.table(x = fc_input, file = paste0("code/LME_SB/datasets/fc_dataset_",roi,".txt"), sep = " ", 
  row.names=FALSE, quote=FALSE)
}
