library(ggplot2)
library(ggridges)
library(dplyr)
library(ggrepel)

library(tidyverse)
library(plotly)
library(tidygraph)
library(igraph)
library(htmlwidgets)
library(networkD3)
options(scipen = 999) # so that numbers don't display with the exponent
options(dplyr.width = Inf) # to print all selected variables
theme_set(theme_classic()) # sets the ggplot theme for the session
theme_update(plot.caption = element_text(size=6)) # updates the theme so that caption size is smaller



nextEpInfo<- read.csv("next_ep_type.csv", header = TRUE)
nextEpInfo <- nextEpInfo %>% rename(clickTime_sec = time_since_content_start_sec)
nextEpInfo <- nextEpInfo %>% rename(menuType = menu_type)
nextEpInfo <- nextEpInfo %>% rename(uv = unique_visitor_cookie_id)
nextEpInfo %>% filter(is.na(clickTime_sec))
nextEpInfo<- na.omit(nextEpInfo)
nextEpInfo$visit_id <-as.character(nextEpInfo$visit_id)

nextEpInfo %>% summary()

#For all visits how many went to same brand, same brand same series, next episode, what % is this of all click
nextEpInfoSummary <-nextEpInfo %>% 
  group_by(menuType) %>%
  summarise(totalFromMenu = n(),
         sameBrandCount = sum(same_brand),
         sameBrandSeriesCount = sum(same_brand_series),
         nextEpCount = sum(next_ep)
         )

nextEpInfo %>% 
  group_by(menuType) %>%
  summarise(totalFromMenu = n(),
            sameBrandCount = sum(same_brand),
            sameBrandSeriesCount = sum(same_brand_series),
            nextEpCount = sum(next_ep)
  )

nextEpInfo %>% group_by(menuType) %>%
  mutate(test = paste(same_brand,same_brand_series,next_ep)) %>%
  group_by(test)
  
  group_by(menuType,same_brand, same_brand_series, next_ep) %>%
  summarise(test = n())
########
nodes = data.frame("name" = factor(
  c(
    "g1_orange",
    "g2_aubergine",
    "g3_aubergine",
    "g4_blue",
    "g5_blue",
    "g6_green",
    "g7_green",
    "g8_yellow",
    "g9_yellow"
  )
),
"group" = as.character(c(1, 2, 2, 3, 3, 4, 4, 5, 5)))

nodes

links <- as.data.frame(matrix(byrow = T, ncol = 3, 
                              c(
                                0, 1, 1400,
                                0, 2, 1860,
                                1, 3, 400,
                                1, 4, 1000,
                                3, 5, 100,
                                3, 6, 150,
                                4, 7, 100,
                                4, 8, 50)))

names(links) <- c("source","target","value")

links

sankeyNetwork(Links = links, Nodes = nodes, Source = "source", 
              Target = "target", Value = "value", NodeID = "name", 
              NodeGroup = "group", fontSize = 12)

