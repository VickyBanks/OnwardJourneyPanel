library(ggplot2)
library(ggridges)
library(dplyr)
library(ggrepel)

library(tidyverse)
library(RColorBrewer)
library(wesanderson)
library(scales)

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


## Read in next episode information
nextEpInfo<- read.csv("next_ep_type_Jan2020.csv", header = TRUE)
nextEpInfo <- nextEpInfo %>% rename(clickTime_sec = time_since_content_start_sec)
nextEpInfo <- nextEpInfo %>% rename(menuType = menu_type)
nextEpInfo <- nextEpInfo %>% rename(uv = unique_visitor_cookie_id)
nextEpInfo <- nextEpInfo %>% rename(nav_click_event_position = nav_select_event_position)
nextEpInfo %>% filter(is.na(clickTime_sec))
nextEpInfo<- na.omit(nextEpInfo)
nextEpInfo$visit_id <-as.character(nextEpInfo$visit_id)
nextEpInfo<- nextEpInfo %>% mutate(nextEpClass = paste(same_brand,same_brand_series,next_ep))
nextEpInfo<- nextEpInfo%>% arrange(desc(dt,uv,visit_id))

nextEpInfo %>% summary()

# Read in click origins for content where the nav was then clicked
navClickOrigins<- read.csv("navContentClickOrigins.csv", header = TRUE)
navClickOrigins$content_click_placement<- recode(navClickOrigins$content_click_placement, 
                                                 'categories_page_kids' = 'categories',
                                                 'categories_page_not_kids' = 'categories',
                                                 'tleo_page' = 'tleo',
                                                 'channel_page' = 'channels',
                                                 'search_page' = 'search',
                                                 'other_page' = 'other',
                                                 'episode_page' = 'episode')

navClickOrigins$content_click_placement<- factor(navClickOrigins$content_click_placement, 
                                                 levels =c('homepage', 'tleo', 'episode', 'channels', 'categories', 'deeplink', 'search', 'other') )

navClickOrigins<- navClickOrigins %>% rename(uv = unique_visitor_cookie_id)
navClickOrigins$visit_id <-as.character(navClickOrigins$visit_id)
navClickOrigins<- navClickOrigins %>% arrange(desc(dt,uv,visit_id))


## Join click before to after
originToDestination<- 
  left_join(nextEpInfo %>% select(dt, uv, visit_id,nav_click_event_position, menuType, clickTime_sec, nextEpClass),
            navClickOrigins%>% select(dt, uv, visit_id,nav_click_event_position, content_click_placement),
            by =c("dt", "uv", "visit_id", "nav_click_event_position")) %>% arrange(desc(dt,uv,visit_id))
originToDestination<- na.omit(originToDestination) 

originToDestinationSummary<- originToDestination %>%
group_by(content_click_placement, nextEpClass)%>%
  summarise(numEachMenu = n()) %>%
  mutate(perc = numEachMenu/sum(numEachMenu)) %>%
  arrange(desc(perc))

ggplot(originToDestinationSummary, aes(x = content_click_placement, y = perc, fill = nextEpClass))+
  geom_bar(stat= "identity", position = "fill", width=1, color="black")+
  scale_y_continuous(labels=percent_format())+
  geom_text(data=subset(originToDestinationSummary, perc > 0.05),
            aes(label=paste0(sprintf("%1.f", 100*perc,"%")),
                group = nextEpClass),
            position = position_stack(vjust = 0.5),
            colour="black")+
  ylab("Percentage of Content CLicks from Each Origin to Each Destination")+
  
  
  ############### HERE ######
  scale_x_discrete(name = "Click Group", labels= c("All Content", "Nav Click Content"))+
  ggtitle("Type of Click Taking Users From One Episode Page to Another  \n PS_IPLAYER - Big Screen - 2020-01-15 to 2020-01-29")+
  scale_fill_manual(values =c( "#037301","#043570"))+
  #scale_fill_brewer(name = "Container",
  #                 palette = "Blues", direction = -1)+
  theme(legend.position="bottom", legend.box = "horizontal")+
  #guides(fill = "none") #this removed the legend for scale_fill_manual

originToDestination %>% filter(visit_id == '4653')
navClickOrigins%>% filter(visit_id == '4653')
nextEpInfo%>% filter(visit_id == '4653')








