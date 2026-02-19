
# Prepare environment -----------------------------------------------------

addTaskCallback(function(...) {set.seed(42);TRUE})
setwd("G:/Other computers/My Laptop/PhD/Psilantro/sudmexmor/")

# Make sure to install pacman before we begin
if (!require("pacman")) {
  install.packages("pacman")
}

# Load required packages  
pacman::p_load(tidyverse,devtools,ggpubr,janitor,magrittr,readxl,lme4,rstatix,
               emmeans,cowplot,scales,effects,ggeffects,ggdist,patchwork)

# Settings color and theme

pal_group <- c(alpha("#737373",1),alpha("#83458E",1))
theme_settings <- theme(text = element_text(size=20),
                        axis.text.x = element_text(size=17),
                        axis.text.y = element_text(size=17),
                        legend.title=element_blank())

# Load data ---------------------------------------------------------------

# Define settings
color_left <- "black"
color_right <- "#BD4885"
LV <- 1

# P-values
permres_pvals <- read_csv("PLS/outputs_5000/permres_pvals.csv",col_names = FALSE)
varexp <- read_csv("PLS/outputs_5000/varexp.csv",col_names = FALSE)
p_var <- tibble(permres_pvals,varexp,1:nrow(permres_pvals), .name_repair = "minimal") %>% 
  set_colnames(c("pvals","var","x"))

# Split-half
splitres_u_vcorr <- read_csv("PLS/outputs_5000/splitres/splitres_u-vcorr.csv",col_names = FALSE) %>%
  set_colnames(c("U","V"))
splitres_vcorr_lo_uplim <- read_csv("PLS/outputs_5000/splitres/splitres_vcorr_lo-uplim.csv",col_names = FALSE) %>%
  set_colnames(c("lower","upper"))
splitres_ucorr_lo_uplim <- read_csv("PLS/outputs_5000/splitres/splitres_ucorr_lo-uplim.csv",col_names = FALSE) %>%
  set_colnames(c("lower","upper"))
splitres_u_vcorr_pvals <- read_csv("PLS/outputs_5000/splitres/splitres_u-vcorr_pvals.csv",col_names = FALSE) %>%
  set_colnames(c("U","V"))

Split_half_Uvals <- splitres_u_vcorr %>% select(U) %>% 
  add_column(splitres_ucorr_lo_uplim, LV = paste0("LV",1:nrow(permres_pvals)), pval = splitres_u_vcorr_pvals$U) %>% 
  mutate(LV = factor(LV, levels = c(paste0("LV",1:nrow(permres_pvals)))))
Split_half_Vvals <- splitres_u_vcorr %>% select(V) %>% 
  add_column(splitres_vcorr_lo_uplim, LV = paste0("LV",1:nrow(permres_pvals)), pval = splitres_u_vcorr_pvals$V) %>% 
  mutate(LV = factor(LV, levels = c(paste0("LV",1:nrow(permres_pvals)))))

# LVs Behavior
y_loadings <- read_csv("PLS/outputs_5000/y_loadings.csv",col_names = FALSE) %>%
  set_colnames(paste0("LV",1:nrow(permres_pvals)))
bootres_y_loadings_ci_behaviour <- read_csv(paste0("PLS/outputs_5000/y_loadings_ci/bootres_y_loadings_ci_behaviour_",LV-1,".csv"),col_names = FALSE) %>%
  set_colnames(c("lower","upper"))

Behavior_metrics4pls <- read_csv("Behavior/PLS/4pls/Behavior_metrics4pls_1.csv")
Behavior_names <- Behavior_metrics4pls %>% select(-c(RID,Group)) %>% colnames() 

# Initial mayus to all sentence
Behavior_names <- gsub("_"," ",Behavior_names) %>% str_to_sentence()

lv <- bootres_y_loadings_ci_behaviour %>% add_column(loadings = y_loadings[[LV]]) %>%
  add_column(names = Behavior_names) %>% 
  mutate(lower = abs(lower-loadings), upper = abs(upper-loadings))

# Scores
x_scores_file <- read_csv("PLS/outputs_5000/x_scores.csv",col_names = FALSE)
x_scores <- x_scores_file %>% set_colnames(paste0("LV",1:ncol(x_scores_file)))

y_scores_file <- read_csv("PLS/outputs_5000/y_scores.csv",col_names = FALSE)
y_scores <- y_scores_file %>% set_colnames(paste0("LV",1:ncol(y_scores_file)))

scores <- Behavior_metrics4pls %>% select(Group) %>% 
  add_column(x_scores = x_scores[[LV]],y_scores = y_scores[[LV]])

# Visualization -----------------------------------------------------------

# P-values
p_value_plot <- p_var %>% 
  ggplot(x = x) +
  geom_point(aes(x = x, y = var), color = color_left, size = 2) +
  geom_line(aes(x = x, y = var), color = color_left, linewidth = 1) +
  geom_point(aes(x = x, y = pvals), color = color_right, size = 3) +  
  geom_line(aes(x = x, y = pvals), color = color_right, linewidth = 1) +
  scale_y_continuous(
    name = "Variance Explained",
    sec.axis = sec_axis(~ . * 1 , name = "p-value")  # Inverse of scaling
  ) +
  labs(x = "Latent Variables") +
  theme_ggdist(base_size = 15) +
  theme_settings +
  theme(
    axis.title.y.left = element_text(color = color_left),
    axis.title.y.right = element_text(color = color_right),
    panel.grid.major = element_blank(),  
    panel.grid.minor = element_blank()
  ) + 
  geom_hline(yintercept = 0.05, linetype = "dashed", color = "gray", size = 1.1)

# Split-half
plot_splithalf_Corr_U <- ggplot(Split_half_Uvals, aes(x = LV, y = U)) +
  geom_col(fill = ifelse(Split_half_Uvals$pval < 0.05, 
                            "#BD4885", "#a0a3a6"), size = 3) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.2, color = "gray") +
  geom_hline(yintercept = 0, color = 1, lwd = 0.5) +
  #   # geom_text(aes(label = names, # Text with groups
  #   #               hjust = ifelse(scores < 0, 1.5, -1),
  #   #               vjust = 0.5), size = 2.5) +
  coord_flip() +
  labs(y = "Brain-Correlation", x = "Latent Variables") +
  theme_ggdist() +
  theme_settings +
  theme(axis.line.x = element_line(colour = "black"),
        axis.title.y = element_blank(),  
        panel.grid.minor.x = element_blank(),  
        panel.grid.major.x = element_blank(), 
        panel.grid.minor.y = element_blank(), 
        panel.grid.major.y = element_blank())

plot_splithalf_Corr_V <- ggplot(Split_half_Vvals, aes(x = LV, y = V)) +
  geom_col(fill = ifelse(Split_half_Vvals$pval < 0.05, 
                            "#BD4885", "#a0a3a6"), size = 3) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.2, color = "gray") +
  geom_hline(yintercept = 0, color = 1, lwd = 0.5) +
  #   # geom_text(aes(label = names, # Text with groups
  #   #               hjust = ifelse(scores < 0, 1.5, -1),
  #   #               vjust = 0.5), size = 2.5) +
  coord_flip() +
  labs(y = "Behavior-Correlation", x = "Latent Variables") +
  theme_ggdist() +
  theme_settings +
  theme(axis.line.x = element_line(colour = "black"),
        axis.title.y = element_blank(),  
        panel.grid.minor.x = element_blank(),  
        panel.grid.major.x = element_blank(), 
        panel.grid.minor.y = element_blank(), 
        panel.grid.major.y = element_blank())

# LV Behavior
color <- lv %>% mutate(color = ifelse(lv$loadings < 0, "#4089d1", "#d14040"),
                       color = ifelse(loadings-lower < 0 & loadings+upper > 0, "#a0a3a6", color)) %>% 
  select(color) %>% pull()

plot_LV_behavior <- ggplot(lv, aes(x = reorder(names,loadings), y = loadings)) +
  geom_bar(stat = "identity",
           show.legend = FALSE,
           fill = color,     
           color = "black") +
  geom_errorbar(aes(ymin = loadings-lower, ymax = loadings+upper), width = 0.2, color = "black") +
  geom_hline(yintercept = 0, color = 1, lwd = 0.5) +
  # geom_text(aes(label = names, # Text with groups
  #               hjust = ifelse(loadings < 0, 1.5, -1),
  #               vjust = 0.5), size = 2.5) +
  ylab("BSR") +
  coord_flip() +
  theme_ggdist(base_size = 15) +
  theme_settings +
  theme(axis.line.x = element_line(colour = "black"),
        axis.title.y = element_blank(),  
        panel.grid.minor.x = element_blank(),  
        panel.grid.major.x = element_blank(), 
        panel.grid.minor.y = element_blank(), 
        panel.grid.major.y = element_blank()) # Remove horizontal grid

# Scores
Cor_Behavior_Brain <- scores %>% 
  ggscatter(
    x = "x_scores",
    y = "y_scores",
    color = "Group",
    fill = "Group",
    palette = pal_group,
    add = "reg.line",
    size = 2,
    alpha = 0.3,
    xlab = "Brain Scores",
    ylab = "Behavior Scores",
    cor.coef = FALSE,
    conf.int = TRUE) +
  theme_ggdist() +
  theme_settings +
  theme(legend.position = "bottom",
        axis.title.x = element_text(size = 24),
        axis.title.y = element_text(size = 24))

Test_Brain <- scores %>% select(x_scores, y_scores, Group) %>%
  ggplot(aes(x = Group, y = x_scores, fill = Group)) + 
  # gghalves::geom_half_point(aes(color = Group), side = "l", range_scale = .3, alpha = .4, size = 2) +
  geom_boxplot(width = .7) + 
  ylab(paste0("Brain Score LV",LV)) +
  scale_color_manual(values = pal_group) +
  scale_fill_manual(values = pal_group) + 
  theme_ggdist() +
  geom_pwc(hide.ns = TRUE,
           method = "t_test", label = "p.adj.signif",
           p.adjust.method = "fdr",
           step.increase = 0.2,
           label.size = 5,
           bracket.nudge.y = 0.2
  ) + coord_flip() +
  # ylim(-17, 10) +
  theme_settings +
  theme(text = element_text(size = 21), legend.position = "none",
        plot.subtitle = element_text(hjust = 1),
        strip.background = element_blank(),
        axis.title.x = element_blank(),
        axis.text.x = element_blank()) +
  theme(axis.line.x = element_blank(),
        axis.title.y = element_blank(),
        axis.line.y = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        axis.ticks.x = element_blank()) 

Test_Behavior <- scores %>% select(x_scores, y_scores, Group) %>%
  ggplot(aes(x = Group, y = y_scores, fill = Group)) + 
  # gghalves::geom_half_point(aes(color = Group), side = "l", range_scale = .3, alpha = .4, size = 2) +
  geom_boxplot(width = .7) + 
  ylab(paste0("Behavior Score LV",LV)) +
  scale_color_manual(values = pal_group) +
  scale_fill_manual(values = pal_group) + 
  theme_ggdist() +
  ggpubr::geom_pwc(hide.ns = TRUE,
                   method = "t_test", label = "p.adj.signif",
                   p.adjust.method = "fdr",
                   step.increase = 0.2,
                   label.size = 5,
                   bracket.nudge.y = 0.1
  ) +
  # ylim(-6.5, 8.5) +
  theme_settings +
  theme(text = element_text(size = 21), legend.position = "none",
        plot.subtitle = element_text(hjust = 1),
        strip.background = element_blank(),
        axis.title.x = element_blank(),
        axis.text.x = element_blank()) + 
  theme(axis.line.x = element_blank(),
        axis.line.y = element_blank(),
        axis.ticks.y = element_blank(),
        axis.title.y = element_blank(),
        axis.text.y = element_blank()) 


plot_scores_both <- wrap_elements(plot_spacer() + (Test_Brain) + plot_spacer() +
                                    plot_layout(widths = c(0.15,1,0.135))) +
  wrap_elements((Cor_Behavior_Brain +
                   theme(legend.position = "bottom") + Test_Behavior) +
                  plot_layout(widths = c(1,0.3),ncol = 2, nrow = 1)) + 
  plot_layout(ncol = 1, nrow = 2, heights = c(0.3,1.2))

# Saving ------------------------------------------------------------------

ggsave(plot = p_value_plot, filename="Figures/PLS/p_value_plot.png",width = 7.5, height = 4.5, dpi = 300)
ggsave(plot = plot_LV_behavior, filename="Figures/PLS/LV_behavior.png",width = 5, height = 5, dpi = 300)
ggsave(plot = wrap_elements(plot_scores_both), filename="Figures/PLS/Brain_behavior_scores_both.png",
       width = 8.5, height = 8.5, dpi = 300)
ggsave(plot = wrap_plots(plot_splithalf_Corr_U), filename = "Figures/PLS/Splithalf_Corr_U.png", width = 6, height = 7, dpi = 300)
ggsave(plot = wrap_plots(plot_splithalf_Corr_V), filename = "Figures/PLS/Splithalf_Corr_V.png", width = 6, height = 7, dpi = 300)
