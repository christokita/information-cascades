##############################
#
# Custom theme for use in plots generated using ggplot2
#
##############################

library(ggplot2)

####################
# My preferred theme
####################
theme_ctokita <- function() {
  theme_classic() +
    theme(axis.text       = element_text(size = 6, color = "black"),
          axis.title      = element_text(size = 7, color = "black"),
          axis.ticks      = element_line(size = 0.3, color = "black"),
          axis.line       = element_line(size = 0.3),
          legend.title    = element_text(size = 7, face = "bold", vjust = -1),
          legend.text     = element_text(size = 6, color = "black"),
          strip.text      = element_text(size = 7, color = "black"),
          legend.key.size = unit(3, "mm"),
          legend.key.width = unit(2, "mm"),
          aspect.ratio    = 1)
}

