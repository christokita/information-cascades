#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Feb 17 16:07:23 2020

@author: ChrisTokita

SCRIPT:
Theme for use in plotnine (ggplot equivalent)
"""
import plotnine as p9

def theme_ctokita():
    return (p9.theme_classic() + 
            p9.theme(axis_text       = element_text(size = 7, color = "black"),
                     axis_title      = element_text(size = 9, color = "black"),
                     axis_ticks      = element_line(size = 1, color = "black"),
                     axis_line       = element_line(size = 1, color = "black"),
                     legend_title    = element_text(size = 8, face = "bold", vjust = -1),
                     legend_text     = element_text(size = 7, color = "black"),
                     strip_text      = element_text(size = 8, color = "black"),
                     legend_key_size = 12,
                     aspect_ratio    = 1,
                     figure_size     = (5,5)))
