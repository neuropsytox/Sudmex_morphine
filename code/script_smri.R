
# Prepare environment -----------------------------------------------------

addTaskCallback(function(...) {set.seed(42);TRUE})
setwd("/Other computers/My Laptop/PhD/Psilantro/sudmexmor/smri/")

# Make sure to install pacman before we begin
if (!require("pacman")) {
  install.packages("pacman")
}

# Load required packages  
pacman::p_load(tidyverse,devtools,ggpubr,janitor,magrittr,readxl,lme4,rstatix,
               emmeans,cowplot,scales,effects,ggeffects)

# Settings color and theme

pal_group <- c(alpha("#737373",1),alpha("#83458E",1))
theme_settings <- theme(text = element_text(size=20),
                        axis.text.x = element_text(size=17),
                        axis.text.y = element_text(size=17),
                        legend.title=element_blank())

# Load data ---------------------------------------------------------------
smooth="1mm"
load(paste0("DBM/smooth_",smooth,"/DBM_data.RData"))
Jdata_jacobians <- read_csv(paste0("DBM/smooth_",smooth,"/Trayectories/Jdata_jacobians.csv")) %>% 
  mutate(Group = factor(Group, levels = c("Sham", "Mor")))


# linear mixed models -----------------------------------------------------

# Run lmm

names_Lmod1 <- str_subset(colnames(Jdata_jacobians),pattern = "Lmod1")

suppressMessages(invisible(capture.output(
  Lmod1 <- names_Lmod1 %>% map(~ lmer(eval(paste0(.x," ~ Age*Group + Batch + (1 |RID)")), data = Jdata_jacobians) ) %>% set_names(names_Lmod1)
)))
Residuals_Lmod1 <- Lmod1 %>% map_dfc(~ .x %>% residuals())

suppressMessages(invisible(capture.output(
  Contrast_Lmod1 <- Lmod1 %>%
    map(~ contrast(emmeans(.x,~ Group), method = "pairwise", adjust = "fdr")) %>% set_names(names_Lmod1)
)))

suppressMessages(invisible(capture.output(
  Eff_size_Lmod1 <- names_Lmod1 %>%
    map(~ eff_size(Contrast_Lmod1[[.x]], sigma = sigma(Lmod1[[.x]]),edf = df.residual(Lmod1[[.x]]) ) ) %>% set_names(names_Lmod1) 
)))

Contrast_Lmod1 %>% map(~ .x %>% as_tibble()) %>% compact(1)

Jdata_jacobians_Lresiduals <- bind_cols(Jdata_jacobians[1:7],Residuals_Lmod1)

# Plot local volume trajectories

plots_volume_Lmod1 <- NULL
for (i in 1:length(names_Lmod1)) {
  ROI <- names_Lmod1 %>% .[i]
  plots_volume_Lmod1[[ROI]] <- ggscatter(Jdata_jacobians,
                                         x = "Age", y = ROI, group = "Group",
                                         color = "Group", linewidth =2,
                                         palette = pal_group,
                                         add.params = list(size = 2, alpha = 0.5),
                                         plot_type ="b",
                                         xlab = "Age (days)",
                                         ylab = "Local volume") +
    geom_line(data = as_tibble(Effect(c("Age", "Group"),
                                      lmer(get(ROI) ~ Age*Group + Batch + (1 |RID), data = Jdata_jacobians),
                                      xlevels=list(Age=seq(min(Jdata_jacobians$Age),
                                                           max(Jdata_jacobians$Age),1)))),
              aes(y=fit, color = Group), linewidth=2)  +
    geom_ribbon(data = as_tibble(Effect(c("Age", "Group"),
                                        lmer(get(ROI) ~ Age*Group + Batch + (1 |RID), data = Jdata_jacobians),
                                        xlevels=list(Age=seq(min(Jdata_jacobians$Age),
                                                             max(Jdata_jacobians$Age),1)))),
                aes(y=fit, ymin=lower, ymax=upper, fill = Group), alpha=0.1) +
    theme_pubr() +
    theme(legend.position = "none",
          plot.title = element_blank()) + 
    theme_settings 
}

plots_volume_Lmod1 %>% names() %>% map(~ ggsave(plot = plots_volume_Lmod1[[.x]], dpi=300,height = 3.5, width = 5.5,bg="white",
                                          filename = paste0("Figures/Exploratory/Trayectories_dbm/linear_",.x,".png")) )

# Polynomial (2) mixed models ----------------------------------------------

# Run poly lmm

names_Pmod1 <- str_subset(colnames(Jdata_jacobians),pattern = "Pmod1")

suppressMessages(invisible(capture.output(
  Pmod1 <- names_Pmod1 %>% map(~ lmer(eval(paste0(.x," ~ poly(Age,2)*Group + Batch + (1 |RID)")), data = Jdata_jacobians) ) %>% set_names(names_Pmod1)
)))
Residuals_Pmod1 <- Pmod1 %>% map_dfc(~ .x %>% residuals())

suppressMessages(invisible(capture.output(
  Contrast_Pmod1 <- Pmod1 %>%
    map(~ contrast(emmeans(.x,~ Group), method = "pairwise", adjust = "fdr")) %>% set_names(names_Pmod1)
)))

suppressMessages(invisible(capture.output(
  Eff_size_Pmod1 <- names_Pmod1 %>%
    map(~ eff_size(Contrast_Pmod1[[.x]], sigma = sigma(Pmod1[[.x]]),edf = df.residual(Pmod1[[.x]]) ) ) %>% set_names(names_Pmod1) 
)))

Contrast_Pmod1 %>% map(~ .x %>% as_tibble()) %>% compact(1)

Jdata_jacobians_Presiduals <- bind_cols(Jdata_jacobians[1:7],Residuals_Pmod1)

# Plot local volume trajectories

plots_volume_Pmod1 <- NULL
for (i in 1:length(names_Pmod1)) {
  ROI <- names_Pmod1 %>% .[i]
  plots_volume_Pmod1[[ROI]] <- ggscatter(Jdata_jacobians,
                                         x = "Age", y = ROI, group = "Group",
                                         color = "Group", linewidth =2,
                                         palette = pal_group,
                                         add.params = list(size = 2, alpha = 0.5),
                                         plot_type ="b",
                                         xlab = "Age (days)",
                                         ylab = "Local volume") +
    geom_line(data = as_tibble(Effect(c("Age", "Group"),
                                      lmer(get(ROI) ~ poly(Age,2)*Group + Batch + (1 |RID), data = Jdata_jacobians),
                                      xlevels=list(Age=seq(min(Jdata_jacobians$Age),
                                                           max(Jdata_jacobians$Age),1)))),
              aes(y=fit, color = Group), linewidth=2)  +
    geom_ribbon(data = as_tibble(Effect(c("Age", "Group"),
                                        lmer(get(ROI) ~ poly(Age,2)*Group + Batch + (1 |RID), data = Jdata_jacobians),
                                        xlevels=list(Age=seq(min(Jdata_jacobians$Age),
                                                             max(Jdata_jacobians$Age),1)))),
                aes(y=fit, ymin=lower, ymax=upper, fill = Group), alpha=0.1) +
    theme_pubr() +
    theme(legend.position = "none",
          plot.title = element_blank()) + 
    theme_settings 
}

plots_volume_Pmod1 %>% names() %>% map(~ ggsave(plot = plots_volume_Pmod1[[.x]], dpi=300,height = 3.5, width = 5.5,bg="white",
                                                filename = paste0("Figures/Exploratory/Trayectories_dbm/poly_",.x,".png")) )


plot_only_legend <- ggscatter(Jdata_jacobians_Presiduals,
             x = "Age", y = "right_striatum_Pmod1_peaks", group = "Group",
             color = "Group", linewidth =2,
             palette = pal_group,
             add.params = list(size = 2, alpha = 0.5),
             plot_type ="b",
             xlab = "Age (days)",
             ylab = "Local volume") +
  geom_line(data = as_tibble(Effect(c("Age", "Group"),
                                    lmer(right_striatum_Pmod1_peaks ~ poly(Age,2)*Group + Batch + (1 |RID), data = Jdata_jacobians),
                                    xlevels=list(Age=seq(min(Jdata_jacobians$Age),
                                                         max(Jdata_jacobians$Age),1)))),
            aes(y=fit, color = Group), linewidth=2)  +
  geom_ribbon(data = as_tibble(Effect(c("Age", "Group"),
                                      lmer(right_striatum_Pmod1_peaks ~ poly(Age,2)*Group + Batch + (1 |RID), data = Jdata_jacobians),
                                      xlevels=list(Age=seq(min(Jdata_jacobians$Age),
                                                           max(Jdata_jacobians$Age),1)))),
              aes(y=fit, ymin=lower, ymax=upper, fill = Group), alpha=0.1) +
  theme_pubr() +
  theme_settings +
  # add title to legend
  theme(legend.title = element_text(size = 20, face = "bold", color = "black", angle = 0, hjust = 0, vjust = 0))

# Save legend

# Extract only the legend as figure
legend <- cowplot::get_plot_component(plot_only_legend, 'guide-box-top', return_all = TRUE)
ggsave(plot = cowplot::ggdraw(legend), filename = "Figures/Exploratory/legend.png", dpi = 300, height = 0.7, width = 3, bg = "white")

