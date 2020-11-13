##############################
#
# Custom theme for use in plots generated using ggplot2
#
##############################

library(ggplot2)

####################
# My preferred theme
####################
theme_ctokita <- function(base_font_size = 6, base_font_color = "black", base_font_family = "Helvetica") {
  theme_classic() +
    theme(
      # Axis settings
      axis.text       = element_text(size = base_font_size, color = base_font_color, family = base_font_family),
      axis.title      = element_text(size = base_font_size+1, color = base_font_color, family = base_font_family),
      axis.ticks      = element_line(size = 0.3, color = base_font_color),
      axis.line       = element_line(size = 0.3),
      # Legend settings
      legend.title    = element_text(size = base_font_size+1, family = base_font_family),
      legend.text     = element_text(size = base_font_size, color = base_font_color, family = base_font_family),
      legend.background = element_blank(),
      legend.text.align = 0,
      legend.key.size = unit(3, "mm"),
      legend.key.width = unit(2, "mm"),
      # Panel/strip settings
      strip.text      = element_text(size = base_font_size+1, color = base_font_color, family = base_font_family),
      strip.background = element_blank(),
      # General plot settings
      # plot.background = element_blank(),
      panel.background = element_blank(),
      aspect.ratio    = 1
      )
}

