
# Prepare environment -----------------------------------------------------

addTaskCallback(function(...) {set.seed(42);TRUE})
setwd("G:/Other computers/My Laptop/PhD/Psilantro/sudmexmor/Behavior/")

# Make sure to install pacman before we begin
if (!require("pacman")) {
  install.packages("pacman")
}

# Load required packages  
pacman::p_load(tidyverse,devtools,ggpubr,janitor,magrittr,readxl,lme4,rstatix,
               emmeans,cowplot,scales,effects,ggeffects,ggcorrplot)

# Settings color and theme

pal_group <- c(alpha("#737373",1),alpha("#83458E",1))
theme_settings <- theme(text = element_text(size=20),
                        axis.text.x = element_text(size=17),
                        axis.text.y = element_text(size=17),
                        legend.title=element_blank())

# Load data ---------------------------------------------------------------
behavior_files <- list.files(getwd(), pattern = "csv", recursive = FALSE) %>% map(~ .x %>% read_csv() %>% 
                                                clean_names() %>%
                                                select(-contains("NA"))) %>% 
    set_names(list.files(getwd(), pattern = "csv", recursive = FALSE) %>% str_remove(".csv"))

behavior_files$EPM <- behavior_files$EPM %>% 
  rename(phase = ifelse("fase" %in% colnames(.), "fase", "phase")) %>% 
  filter(phase == "T2") %>% select(-phase)

behavior_files$OF <- behavior_files$OF %>% 
  rename(phase = ifelse("fase" %in% colnames(.), "fase", "phase")) %>% 
  filter(phase == "T2") %>% select(-phase)


# linear mixed models -----------------------------------------------------

# Run lmm for all metrics inside each element of the list

# remove Infusiones from the elements from the list
lm_behaviors <- behavior_files %>% names() %>% .[-which(. %in% c("Infusiones"))] %>% 
  map(~ behavior_files[[.x]] %>% select(-c("rid","group")) %>% colnames() %>% 
        map(function(y) lm(eval(paste0(y," ~ group")), data = behavior_files[[.x]])) %>% 
        set_names(behavior_files[[.x]] %>% select(-c("rid","group")) %>% colnames())) %>% 
  set_names(behavior_files %>% names() %>% .[-which(. %in% c("Infusiones"))] )


# Extract residuals

residuals_behaviors <- lm_behaviors %>% map(~ .x %>% map_df(~ .x %>% residuals()) %>% set_colnames(names(.x) ))

# Run contrasts

contrast_behaviors <- lm_behaviors %>% map(~ .x %>% map(~ contrast(emmeans(.x,~ group), method = "pairwise", adjust = "none")) %>% 
                                           set_names(names(.x)) ) %>% 
  set_names(behavior_files %>% names() %>% .[-which(. %in% c("Infusiones"))] ) %>% 
  map(~ .x %>% set_names(names(.x)) )

# Run effect size

emm_behaviors <- lm_behaviors %>% map(~ .x %>% map(~ emmeans(.x, "group") ) )

eff_size_behaviors <- emm_behaviors %>% names() %>% 
    map(function(y) emm_behaviors[[y]] %>% names() %>% map(~ eff_size(emm_behaviors[[y]][[.x]], 
                                                  sigma = sigma(lm_behaviors[[y]][[.x]]), 
                                                  edf = df.residual(lm_behaviors[[y]][[.x]])) ) %>% 
  set_names(emm_behaviors[[y]] %>% names() )) %>%
  set_names(emm_behaviors %>% names())

# Filter only the significant contrasts

contrast_behaviors_reduced <- contrast_behaviors %>% names() %>% map(function(y) contrast_behaviors[[y]] %>% map(~ .x %>% as_tibble()) %>% compact(1) %>% 
  map(~ .x %>% filter(p.value < 0.05)) %>% 
  compact(1) ) %>% set_names(contrast_behaviors %>% names())


# Stats hypothesis testing ------------------------------------------------

# Shapiro-Wilk test
behavior.shapiro <- behavior_files %>% names() %>% .[-which(. %in% c("Infusiones"))] %>% 
  map(function(y) behavior_files[[y]] %>% select(-rid,-group) %>% 
    map(~ shapiro.test(.x) %>% broom::tidy() %>% select(p.value) %>% pull() ) ) %>% 
  set_names(behavior_files %>% names() %>% .[-which(. %in% c("Infusiones"))] )

# wilcoxon test

wilcox_behaviors <- behavior_files %>% names() %>% .[-which(. %in% c("Infusiones"))] %>% 
  map(~ behavior_files[[.x]] %>% select(-c("rid","group")) %>% colnames() %>% 
        map(function(y) wilcox_test(as.formula(paste0(y," ~ group")), data = behavior_files[[.x]])) %>% 
        set_names(behavior_files[[.x]] %>% select(-c("rid","group")) %>% colnames()) %>% 
        map(~ .x %>% filter(p < 0.05) )) %>%
  set_names(behavior_files %>% names() %>% .[-which(. %in% c("Infusiones"))] ) %>% compact(1)


# Plot ---------------------------------------------------------------------

library(ggdist)

# boxplots 

plots_behaviors_uncorrected_stats <- behavior_files %>% names() %>% .[-which(. %in% c("Infusiones"))] %>% 
  map(function(behav) {
    behavior_files[[behav]] %>% 
      select(-c("rid","group")) %>% 
      colnames() %>% 
      map(function(metric) {
        behavior_files[[behav]] %>%
          ggplot(aes(x = group, y = !!sym(metric), fill = group)) + 
          stat_halfeye(
            adjust = .8, width = .7, fill = "grey85",
            interval_colour = NA, 
            position = position_nudge(x = .01),
            aes(thickness = stat(f*n))) +
          gghalves::geom_half_point(aes(color = group),
                                    side = "l", 
                                    range_scale = .3, 
                                    alpha = .4, size = 2) +
          geom_boxplot(outlier.colour = NA, 
                       alpha = 0.8, 
                       size = 1, 
                       width = 0.5, aes(fill = group)) +
          scale_fill_manual(values = pal_group) +
          scale_color_manual(values = pal_group) +
          theme_pubr() +
          theme(strip.text = element_text(size = 16),
                strip.background = element_rect(fill = "white"),
                legend.position = "none") +
          # stat_compare_means(
          #   label.x = 1.5, label = "p.format", 
          #   size = 5, hide.ns = TRUE) +
          theme_settings
      }) %>% set_names(behavior_files[[behav]] %>% select(-c("rid","group")) %>% colnames())
  }) %>% set_names(behavior_files %>% names() %>% .[-which(. %in% c("Infusiones"))])
  
contrast_behaviors_reduced$EPM
contrast_behaviors_reduced$MWM_A
contrast_behaviors_reduced$OF  
contrast_behaviors_reduced$NOR


# Arranging ---------------------------------------------------------------

path_cluster <- "/data/chamal/projects/jalilr/pls/mice_data/relative_jacobians/nii/t3_pls/"
nifti_files_names <- list.files(paste0(getwd(),"/../smri/DBM/jacobians"), pattern = "gz") %>% 
  #keep only those who has "T3" in the name
  keep(~ grepl("T2", .)) %>%
  keep(~ grepl("nii.gz", .)) 

nifti_paths_names <- nifti_files_names %>%
  map(~ .x %>% str_split(pattern="_")  %>% map(~ .x[[1]])) %>% reduce(rbind) %>% as.data.frame() %>% 
  rename("rid" = "V1") %>% 
  add_column(relative_jacobian = nifti_files_names) %>% 
  mutate(relative_jacobian = paste0(path_cluster,relative_jacobian)) %>% unnest()


# ¿todas las medidas son importantes?
behavior_files$OPF %>% colnames()
behavior_files$MWM_A %>% colnames()
behavior_files$EPM %>%
  dplyr::select(-contains("percentage"),
                -contains("raw"),
                -contains("left"), 
                -contains("right"), 
                -contains("top"),
                -contains("bottom"),
                -bodycentre_total_time, nose_dip) %>% colnames()

# Select metrics for PLS --------------------------------------------------

behavior4pls_files <- list.files(paste0(getwd(),"/PLS"), pattern = "csv", recursive = FALSE, full.names = TRUE) %>% 
    map(~ .x %>% read_csv() %>% clean_names() ) %>% 
    set_names(list.files(paste0(getwd(),"/PLS"), pattern = "csv", recursive = FALSE, full.names = FALSE) %>% str_remove(".csv")) %>% 
    map(~ .x %>% mutate(rid = paste0("sub-0",rid)))

behavior4pls_files$MOTIVACION_zscore <- behavior4pls_files$MOTIVACION_zscore %>% 
  mutate(date = as.Date(date)) %>% filter(date == "0015-03-23" | date == "0013-07-23") %>% 
  select(rid,group,z_score) %>% rename("motivation" = "z_score")
behavior4pls_files$OFT_REARING <- behavior4pls_files$OFT_REARING %>% 
    filter(phase == "T2") %>% select(rid,group,vertical_episode_count,vertical_activity_count,vertical_movement_time)
behavior4pls_files$WHISHAW_ERROR_TYPE_SWIMMING <- behavior4pls_files$WHISHAW_ERROR_TYPE_SWIMMING %>% 
    select(rid,group,whishaws_error,type_of_swimming) %>% 
    mutate(type_of_swimming = case_when(type_of_swimming == "Random" ~ 1,
                                        type_of_swimming == "Spacial" ~ 2,
                                        type_of_swimming == "Serial" ~ 3))

# make a correlation among variables except for rid and group
behavior4pls_files %>% reduce(full_join) %>% drop_na() %>% 
  select(-rid,-group) %>% cor() %>% 
  ggcorrplot() + 
  theme_minimal() + 
  ggtitle("Correlation matrix") + 
  geom_text(aes(label = round(value, 2)), size = 3, color = "black") + 
  theme(plot.title = element_text(hjust = 0.5),
        legend.position = "none",
        axis.title.x = element_blank(), 
        axis.title.y = element_blank(),
        axis.text.x = element_text(angle = 45, hjust = 1))

# obtain the p-values of the correlation

ggcorrplot(behavior4pls_files %>% reduce(full_join) %>% drop_na() %>% 
             select(-rid,-group) %>% cor(),
  p.mat = behavior4pls_files %>% reduce(full_join) %>% drop_na() %>% 
    select(-rid,-group) %>% cor_pmat(), 
  hc.order = TRUE, type = "upper", insig = "blank") + 
  geom_text(aes(label = round(value, 2)), size = 3, color = "black")


# Join all databases into just one
behavior4pls_files %>% reduce(full_join) %>% drop_na() %>% 
  rename("RID" = "rid", "Group" = "group") %>% 
  write_csv("PLS/4pls/Behavior_metrics4pls_1.csv")



