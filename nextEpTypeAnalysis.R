library(ggplot2)
library(ggridges)
library(dplyr)
library(ggrepel)

nextEpInfo<- read.csv("next_ep_type.csv", header = TRUE)
nextEpInfo <- nextEpInfo %>% rename(clickTime_sec = time_since_content_start_sec)
nextEpInfo <- nextEpInfo %>% rename(menuType = menu_type)
nextEpInfo <- nextEpInfo %>% rename(uv = unique_visitor_cookie_id)
nextEpInfo %>% filter(is.na(clickTime_sec))
nextEpInfo<- na.omit(nextEpInfo)
nextEpInfo$visit_id <-as.character(nextEpInfo$visit_id)

nextEpInfo %>% summary()

#For all visits how many went to same brand, same brand same series, next episode, what % is this of all click
nextEpInfo %>% 
  group_by(menuType) %>%
  summarise(totalFromMenu = n(),
         sameBrandCount = sum(same_brand),
         sameBrandSeriesCount = sum(same_brand_series),
         nextEpCount = sum(next_ep)
         )
