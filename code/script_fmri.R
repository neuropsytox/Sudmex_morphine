
# Prepare environment -----------------------------------------------------

addTaskCallback(function(...) {set.seed(42);TRUE})
setwd("G:/Other computers/My Laptop/PhD/Psilantro/sudmexmor/fmri")

# Make sure to install pacman before we begin
if (!require("pacman")) {
  install.packages("pacman")
}

# Load required packages  
pacman::p_load(tidyverse,devtools,ggpubr,janitor,magrittr,readxl,lme4,rstatix,
               emmeans,cowplot,scales,effects,ggeffects,viridis,patchwork,hrbrthemes,
               circlize,chorddiag,reshape2,paletteer)

# Settings color and theme

pal_group <- c(alpha("#737373",1),alpha("#83458E",1))
theme_settings <- theme(text = element_text(size=20),
                        axis.text.x = element_text(size=17),
                        axis.text.y = element_text(size=17),
                        legend.title=element_blank())

# Load data ---------------------------------------------------------------

files_path <- list.files(getwd(), pattern = ".csv", full.names = FALSE, recursive = FALSE) 

#remove the extension

files_load <- files_path %>% map(read_csv) %>% set_names(files_path)

net_atls_left <- files_load %>% map(~ .x %>% clean_names() %>% mutate(from = "cc") %>% 
  mutate(to = gsub("([a-zA-Z])[^ ]* ?", "\\1", region_of_interest)) %>% 
  mutate(to = case_when(region_of_interest == "Striatum" ~ "Str", TRUE ~ to)) %>% 
  select(left_hemisphere_label,system,to) %>% 
  filter(left_hemisphere_label != "none") %>% 
  mutate(to = paste0("r",to)) )

net_atls_right <- files_load %>% map(~ .x %>% clean_names() %>% mutate(from = "cc") %>% 
  mutate(to = gsub("([a-zA-Z])[^ ]* ?", "\\1", region_of_interest)) %>% 
  mutate(to = case_when(region_of_interest == "Striatum" ~ "Str", TRUE ~ to)) %>% 
  select(right_hemisphere_label,system,to) %>% 
  filter(right_hemisphere_label != "none") %>% 
  mutate(to = paste0("l",to)) )

net_atls <- files_path %>% map(~ net_atls_left[[.x]] %>% rename(effect = left_hemisphere_label) %>% 
  rbind(net_atls_right[[.x]] %>% rename(effect = right_hemisphere_label)) %>% 
  mutate(from = "cc", 
         system = gsub(" System", "", system), 
         system = gsub(" Fomation", "", system)) ) %>% set_names(files_path)

net_atls_system <- net_atls %>% map(~ .x %>% filter(effect != "both") %>% rbind(
  rbind(.x %>% filter(effect == "both") %>% mutate(effect = "increased"),
        .x %>% filter(effect == "both") %>% mutate(effect = "decreased"))) %>% 
  select(effect,system,to) %>% 
  mutate(system = case_when(system == "Inter Hemispheric Commisures" ~ "Inter Hem. Commisure", TRUE ~ system)))

net_atls_to <- net_atls %>% map(~ .x %>% filter(effect != "both") %>% rbind(
  rbind(.x %>% filter(effect == "both") %>% mutate(effect = "increased"),
        .x %>% filter(effect == "both") %>% mutate(effect = "decreased"))) %>% 
    select(effect,to) %>% unique())

# chord diagram -----------------------------------------------------

# color palette
mycolors <- c("#B24745","#00A1D5",paletteer_d("ggthemes::stata_s2color",14),paletteer_dynamic("cartography::multi.pal", 5)) 


for (net in net_atls_system %>% names()) {
  
  mycolor <- mycolors[1:(length(unique(net_atls_system[[net]]$system))+2)]
  
  png(paste0(net %>% str_replace(".csv",""),".png"), width = 8, height = 8, units = "in", 
      res = 300,bg = "transparent")
  # parameters
  circos.clear()
  circos.par(start.degree = 300, gap.degree = 1, cell.padding = c(0, 0, 0, 0), 
              track.margin = c(-0.44, 0.45), points.overflow.warning = FALSE)
  par(mar = c(0, 0, 0, 0))
  
  chordDiagram(
    x = net_atls_system[[net]],
    transparency = 0.4,
    directional = 1, 
    direction.type = c("arrows", "diffHeight"), 
    diffHeight  = 0.025,
    annotationTrack = "grid", 
    annotationTrackHeight = c(0.05, 0.1),
    link.arr.type = "big.arrow", 
    link.sort = TRUE, 
    link.largest.ontop = TRUE,
    grid.col = mycolor)
  
  circos.track(track.index = 1, panel.fun = function(x, y) {
    if (!CELL_META$sector.index %in% c("increased", "decreased")) {
      circos.text(CELL_META$xcenter, CELL_META$ylim[1]+1.5, CELL_META$sector.index,
                  facing = "clockwise", niceFacing = TRUE, adj = c(0, 0.5),
                  cex = 1.5)  # Increase text size
    }
  }, bg.border = TRUE)
  dev.off()
  
}
  
##

