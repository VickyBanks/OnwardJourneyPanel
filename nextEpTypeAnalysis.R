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

#Find the number of visits in each group
# Brand Series NextEp
# 0 = no, 1 = yes

nextEpInfo %>% group_by(menuType) %>%
  mutate(nextEpClass = paste(same_brand,same_brand_series,next_ep)) %>%
  group_by(nextEpClass) %>%
  summarise(numVisits = n()) 

path01 <- nextEpInfo %>% filter(same_brand == 0) %>%summarise(path01 = n()) #different brand
path02 <- nextEpInfo %>% filter(same_brand == 1) %>%summarise(path02 = n()) #same brand
path23 <- nextEpInfo %>% filter(same_brand == 1 & same_brand_series == 1) %>%summarise(path23 = n()) #same brand same series
path24 <- nextEpInfo %>% filter(same_brand == 1 & same_brand_series == 0) %>%summarise(path24 = n()) #same brand different series
path35 <- nextEpInfo %>% filter(same_brand == 1 & same_brand_series == 1 & next_ep == 1 ) %>%summarise(path35 = n()) #same brand same series next ep
path36 <- nextEpInfo %>% filter(same_brand == 1 & same_brand_series == 1 & next_ep == 0 ) %>%summarise(path36 = n()) #same brand same series not next ep
path47 <- nextEpInfo %>% filter(same_brand == 1 & same_brand_series == 0 & next_ep == 1 ) %>%summarise(path47 = n()) #same brand not same series next ep
path48 <- nextEpInfo %>% filter(same_brand == 1 & same_brand_series == 0 & next_ep == 0 ) %>%summarise(path48 = n()) #same brand not same series not next ep




######## Sankey Diagram for all clicks 
#"All Clicks","Diff Brand - 9%","Same Brand - 91%","Diff Series - 13%","Next Ep - 36%","Other Ep - 64%","Next Ep - 2%","Other Ep - 98%"
nodes = data.frame("name" = factor(c("All Clicks",
                                     "Diff Brand - 9%",
                                     "Same Brand - 91%",
                                     "Same Series - 80%",
                                     "Diff Series - 12%",
                                     "Next Ep - 29%",
                                     "Other Ep - 51%",
                                     "Next Ep - 0.2%",
                                     "Other Ep - 11%")),
                   "group" = as.character(c(1, 2, 2, 3, 3, 4, 4, 5, 5)))
nodes
links <- as.data.frame(matrix(byrow = T, ncol = 3, 
                              c(0, 1, 719071,
                                0, 2, 7320318,
                                2, 3, 6393271,
                                2, 4, 927047,
                                3, 5, 2324600,
                                3, 6, 4068671,
                                4, 7, 16959,
                                4, 8, 911088)))
names(links) <- c("source","target","value")
links

allClicksSankey <- sankeyNetwork(Links = links, Nodes = nodes, Source = "source", 
              Target = "target", Value = "value", NodeID = "name", 
              NodeGroup = "group", fontSize = 12)
allClicksSankey
x