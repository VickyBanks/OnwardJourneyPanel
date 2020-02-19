library(ggplot2)
library(ggridges)
library(dplyr)
library(ggrepel)
library(tidyverse)
library(RColorBrewer)
library(wesanderson)
library(scales)

theme_set(theme_classic())

# Read in file for all click origins over the period
allClickOrigins<- read.csv("allContentClickOrigins.csv", header = TRUE)
allClickOrigins$placement<- recode(allClickOrigins$placement, 
                                                 'categories_page_kids' = 'categories',
                                                 'categories_page_not_kids' = 'categories',
                                                 'tleo_page' = 'tleo',
                                                 'channel_page' = 'channels',
                                                 'search_page' = 'search',
                                                 'other_page' = 'other',
                                                 'episode_page' = 'episode')

allClickOrigins$placement<- factor(allClickOrigins$placement, 
                                                 levels =c('homepage', 'tleo', 'episode', 'channels', 'categories', 'deeplink', 'search', 'other') )

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


#nextEpInfo <- nextEpInfo %>% rename(clickTime_sec = time_since_content_start_sec)

###### How does the route to content differ for those where the nav was clicked?
navClickPlacement <- navClickOrigins %>% 
  group_by(content_click_placement) %>%
  summarise(numEvents = n()) %>%
  arrange(desc(numEvents)) %>%
  mutate(perc = round(100*numEvents/sum(numEvents),1))
navClickPlacement$placement<- navClickPlacement$content_click_placement 
navClickPlacement <- navClickPlacement %>% select(placement, numEvents,perc)

navClickPlacement

ggplot(navClickPlacement, aes(x = placement, y = numEvents)) +
  geom_bar(stat = "identity", fill = "blue")+
  scale_y_continuous(limits = c(0,2100000), breaks = c(0,250000, 500000,750000, 1000000, 1250000, 1500000, 1750000, 2000000), 
                     labels = c(0,0.25,0.50, 0.75,1.00, 1.25, 1.50, 1.75, 2.00))+
  ylab("Number Onward Nav Clicks (millions)")+
  xlab("Content Origin Page")+
  ggtitle("Routes to Content Where the Onward Journey Nav was Clicked \n PS_IPLAYER - Big Screen - 2020-01-15 to 2020-01-29")+
  geom_label(data=subset(navClickPlacement, perc > 8),
             aes(label=paste0(sprintf("%1.0f", perc),"%"),),
             position = position_stack(vjust = 0.5),
             colour="black")+
  geom_label(data=subset(navClickPlacement, perc>=2 & perc< 8),
             aes(label=paste0(sprintf("%1.0f", perc),"%"),),
             position = position_stack(vjust = 1.6),
             colour="black") +
  geom_label(data=subset(navClickPlacement, perc < 2),
             aes(label=paste0(sprintf("%1.0f", perc),"%"),),
             position = position_stack(vjust = 4.0),
             colour="black")

##### For all clicks to content
allClickPlacement <- allClickOrigins %>% 
  group_by(placement) %>%
  summarise(numEvents = sum(num_content_clicks)) %>%
  arrange(desc(numEvents)) %>%
  mutate(perc = round(100*numEvents/sum(numEvents),1))

allClickPlacement

ggplot(allClickPlacement, aes(x = placement, y = numEvents)) +
  geom_bar(stat = "identity", fill = "blue")+
  scale_y_continuous(limits = c(0,60000000), breaks = c(0,10000000,20000000,30000000,40000000,50000000,60000000), 
                     labels = c(0, 10,20,30,40,50,60))+
  ylab("Number Onward Nav Clicks (millions)")+
  xlab("Content Origin Page")+
  ggtitle("Routes to Content \n PS_IPLAYER - Big Screen - 2020-01-15 to 2020-01-29")+
  geom_label(data=subset(allClickPlacement, perc > 9),
             aes(label=paste0(sprintf("%1.0f", perc),"%"),),
             position = position_stack(vjust = 0.5),
             colour="black")+
  geom_label(data=subset(allClickPlacement, perc>=2 & perc< 8),
             aes(label=paste0(sprintf("%1.0f", perc),"%"),),
             position = position_stack(vjust = 1.6),
             colour="black") +
  geom_label(data=subset(allClickPlacement, perc < 2),
             aes(label=paste0(sprintf("%1.0f", perc),"%"),),
             position = position_stack(vjust = 5.0),
             colour="black")

###### Join for comparison
clickPlacementComparison <- bind_rows(
  allClickPlacement %>% mutate(clickGroup = 'All Content'),
  navClickPlacement %>% mutate(clickGroup = 'Nav Click'))

clickPlacementComparison %>% arrange(perc)


ggplot(clickPlacementComparison, aes(x = clickGroup, y = perc, fill = clickGroup)) +
  geom_bar(stat = "Identity", position = position_dodge(width = 1) )+
  scale_y_continuous(limits = c(0,50), breaks = c(0,5,10,15,20,25,30,35,40,45,50), 
                     labels = c(0,5,10,15,20,25,30,35,40,45,50))+
  scale_fill_manual(values = c("#043570", "#c41408"), name = "Click Group", labels = c("All Content", "Nav Click Content"))+
  ylab("Percentage of Content CLicks from Each Origin")+
  xlab("Content Origin Page")+
  ggtitle("Routes to Content Comparison \n PS_IPLAYER - Big Screen - 2020-01-15 to 2020-01-29")+
  #scale_fill_discrete(name = "Click Group", labels = c("All Content", "Nav Click Content"))+
  geom_hline(yintercept = 5, linetype = "dashed")+
  geom_text(data=subset(clickPlacementComparison, perc > 20),
             aes(label=paste0(sprintf("%1.0f", perc),"%"),),
             position = position_dodge(width = 1),
             vjust = -0.5,
             colour="black")+
  facet_wrap(~ placement, nrow = 1, strip.position = "bottom")+
  theme(axis.text.x=element_blank(),
        axis.ticks.x=element_blank())

clickPlacementComparison$placement2<- factor(clickPlacementComparison$placement, 
                                             levels = c('other','search','deeplink','categories', 'channels','tleo', 'homepage', 'episode' ))
clickPlacementComparison
ggplot(data = clickPlacementComparison, aes(x = clickGroup, y = perc, fill = placement2)) +
  geom_bar(stat= "identity", position = "fill", width=1, color="black")+
  scale_y_continuous(labels=percent_format())+
  geom_text(data=subset(clickPlacementComparison, perc > 5),
            aes(label=paste0(sprintf("%1.0f", perc,"%")),
                group = placement2),
            position = position_stack(vjust = 0.5),
            colour="black")+
  coord_cartesian(ylim = c(0, 1))+
  ylab("Percentage of Content CLicks from Each Origin")+
  xlab("Content Origin Page")+
  ggtitle("Routes to Content Comparison \n PS_IPLAYER - Big Screen - 2020-01-15 to 2020-01-29")+
  scale_fill_brewer(name = "Placement",
                    palette = "Set2", direction = -1)+
  theme(legend.position="bottom", legend.box = "horizontal")



### How are users from an episode page getting to the next content
episodeOrigins<- left_join(
navClickOrigins %>% filter(content_click_placement== 'episode') %>%
  group_by(content_click_container) %>%
  summarise(numEvents = n()) %>%
  mutate(navPerc = round(numEvents/sum(numEvents),3))%>% 
  select(-numEvents),
allClickOrigins %>% filter(placement == 'episode') %>%
  group_by(simple_container_name) %>%
  summarise(numEvents = sum(num_content_clicks)) %>%
  mutate(allPerc = round(numEvents/sum(numEvents),3))%>%
  select(-numEvents), by= c("content_click_container"="simple_container_name"))

episodeOrigins<- episodeOrigins%>%rename(container = content_click_container)

episodeOrigins<- gather(data= episodeOrigins, key = "clickGroup", value = "perc", navPerc, allPerc)
episodeOrigins$container<-factor(episodeOrigins$container, 
                                 levels = c("page-section-rec",
                                            "onward-journey-autoplay-next-rec",
                                            "page-section-related",
                                            "onward-journey-autoplay-next-episode"))

episodeOrigins$container<- recode(episodeOrigins$container, 
                                  "page-section-rec" = 'Nav Click - Rec',
                                    "onward-journey-autoplay-next-rec" = 'Autoplay - Rec',
                                    "page-section-related" = 'Nav Click - Related',
                                    "onward-journey-autoplay-next-episode" = 'Autoplay - Related')
                                  
episodeOrigins


ggplot(data = episodeOrigins, aes(x = clickGroup, y = perc, fill = clickGroup)) +
  geom_bar(stat= "identity", position = "fill", width=1, color="black", aes(alpha=container))+
  scale_alpha_manual(values=c(0.25,0.5,0.75,1.0), name = "Click Type Colour Scale")+
  scale_y_continuous(labels=percent_format())+
  geom_text(data=subset(episodeOrigins, perc > 0.05),
            aes(label=paste0(sprintf("%1.f", 100*perc,"%")),
                group = container),
            position = position_stack(vjust = 0.5),
            colour="black")+
# geom_text(data=subset(episodeOrigins, perc > 0.05),
#           aes(label=container),
#           position = position_stack(vjust = 0.5),
#           colour="black")+
#   coord_cartesian(ylim = c(0, 1))+
  ylab("Percentage of Content CLicks from Each Origin")+
  scale_x_discrete(name = "Click Group", labels= c("All Content", "Nav Click Content"))+
  ggtitle("Type of Click Taking Users From One Episode Page to Another  \n PS_IPLAYER - Big Screen - 2020-01-15 to 2020-01-29")+
  scale_fill_manual(values =c( "#037301","#043570"))+
  #scale_fill_brewer(name = "Container",
   #                 palette = "Blues", direction = -1)+
  theme(legend.position="bottom", legend.box = "horizontal")+
  guides(fill = "none") #this removed the legend for scale_fill_manual



###### Homepage
allClickOrigins%>% filter(placement == 'homepage') %>% distinct(simple_container_name)
navClickOrigins %>% filter(content_click_placement == 'homepage') %>% distinct( content_click_container)

fancyContainerName<- read.csv("fancyContainerName.csv", header = TRUE)

homepageAllClicks<- allClickOrigins %>% filter(placement == 'homepage' & 
                                                 !str_detect(simple_container_name, "u16|u13")) %>%
  group_by(placement, simple_container_name) %>%
  summarise(numClicks = sum(num_content_clicks)) %>%
  mutate(perc = round(100*numClicks/sum(numClicks),2), clickGroup = "allClicks") %>%
  arrange(desc(perc))%>%
  rename(container = simple_container_name)

homepageNavClicks<- navClickOrigins %>% filter(content_click_placement == 'homepage' & 
                                                 !str_detect(content_click_container, "u16|u13")) %>%
  group_by(content_click_placement, content_click_container) %>%
  summarise(numClicks = n()) %>%
  mutate(perc = round(100*numClicks/sum(numClicks),2), clickGroup = "navClicks") %>%
  arrange(desc(perc))%>% 
  rename(container = content_click_container, placement = content_click_placement)

homepageComparison<- bind_rows(homepageNavClicks, homepageAllClicks)
homepageTable <- left_join(homepageComparison %>% 
                             filter(clickGroup == "navClicks")%>% 
                             top_n(n=10,wt = perc) %>% 
                             select(container),
                           homepageComparison %>% 
                             select(-numClicks, -placement)) %>% 
  spread(key = clickGroup, value = perc) %>%
  arrange(desc(allClicks))
homepageTable <- left_join(homepageTable, fancyContainerName, by = "container") %>% 
  select(placement,fancy_container_name,allClicks,navClicks)

homepageTable

ggplot(data = homepageComparison %>% filter(container == 'module-watching-continue-watching'|
                                             container == 'module-editorial-featured'|
                                             container == 'module-popular-most-popular'|
                                             container == 'module-recommendations-recommended-for-you'),
       aes(x = clickGroup, y = perc, fill = clickGroup)) +
  geom_bar(stat= "identity", position = "fill", width=1, color="black", aes(alpha=container))+
  scale_alpha_manual(values=c(0.2,0.4,0.6,0.8,1.0), name = "Click Type Colour Scale")+
  scale_y_continuous(labels=percent_format())+
  geom_text(data=subset(homepageComparison, perc > 0.05),
            aes(label=paste0(sprintf("%1.f", 100*perc,"%")),
                group = container),
            position = position_stack(vjust = 0.5),
            colour="black")+
  # geom_text(data=subset(episodeOrigins, perc > 0.05),
  #           aes(label=container),
  #           position = position_stack(vjust = 0.5),
  #           colour="black")+
  #   coord_cartesian(ylim = c(0, 1))+
  ylab("Percentage of Content CLicks from Each Origin")+
  scale_x_discrete(name = "Click Group", labels= c("All Content", "Nav Click Content"))+
  ggtitle("Type of Click Taking Users From One Episode Page to Another  \n PS_IPLAYER - Big Screen - 2020-01-15 to 2020-01-29")+
  scale_fill_manual(values =c( "#037301","#043570"))+
  #scale_fill_brewer(name = "Container",
  #                 palette = "Blues", direction = -1)+
  theme(legend.position="bottom", legend.box = "horizontal")+
  guides(fill = "none") #this removed the legend for scale_fill_manual
