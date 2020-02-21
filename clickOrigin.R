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

#### How many visits have more than one nav click? ####

multipleNavClicks<- navClickOrigins %>% group_by(dt,unique_visitor_cookie_id, visit_id) %>%
  summarise(numClicks = n()) %>%
  mutate(numClicks = ifelse(numClicks >=10, 10,numClicks))%>% 
  ungroup()%>%
  group_by(numClicks) %>%
  summarise(numUsers = n())%>%
  mutate(perc = round(100*numUsers/sum(numUsers),1))

multipleNavClicks$numClicks<- as.character(multipleNavClicks$numClicks) %>% recode("10"= "10+")
multipleNavClicks$numClicks<- factor(multipleNavClicks$numClicks, 
                                     levels = c("1","2","3","4","5","6","7", "8", "9", "10+"))
multipleNavClicks

##################### What level of checks were given to each content? ####################################
navClickOrigins %>% group_by(content_click_placement,check_type)%>%
  summarise(numClicks = n()) %>%
  mutate(perc = round(100*numClicks/sum(numClicks),1))%>%
  select(-numClicks)%>%
  spread(key = check_type, value = perc) %>%
  mutate_all(~replace(., is.na(.), 0))


######################## How does the route to content differ for those where the nav was clicked?##################
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

############################# For all clicks to content####################################
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

######################## Join for comparison ################################################
clickPlacementComparison <- bind_rows(
  allClickPlacement %>% mutate(clickGroup = 'All Content'),
  navClickPlacement %>% mutate(clickGroup = 'Nav Click'))

clickPlacementComparison %>% arrange(perc)

#### Dodge bar chart comparing the two
ggplot(clickPlacementComparison, aes(x = clickGroup, y = perc, fill = clickGroup)) +
  geom_bar(stat = "Identity", position = position_dodge(width = 1) )+
  scale_y_continuous(limits = c(0,50), breaks = c(0,5,10,15,20,25,30,35,40,45,50), 
                     labels = c(0,5,10,15,20,25,30,35,40,45,50))+
  scale_fill_manual(values = c("#043570", "#c41408"), name = "Click Group", labels = c("All Content", "Nav Click Content"))+
  ylab("Percentage of Content CLicks from Each Origin")+
  xlab("Content Origin Page")+
  ggtitle("Routes to Content Comparison \n PS_IPLAYER - Big Screen - 2020-01-15 to 2020-01-29")+
  #scale_fill_discrete(name = "Click Group", labels = c("All Content", "Nav Click Content"))+
  #geom_hline(yintercept = 5, linetype = "dashed")+
  geom_text(data=subset(clickPlacementComparison, perc > 1),
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

## Stacked bar chart comparing % from different placements (e.g homepage, deep link)
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




##################### How are users from an episode page getting to the next content  ##############################
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

### Stacked Bar graph to show how people move from one episode page to another
ggplot(data = episodeOrigins, aes(x = clickGroup, y = perc, fill = clickGroup)) +
  geom_bar(stat= "identity", position = "fill", width=1, color="black", aes(alpha=container))+
  scale_alpha_manual(values=c(0.25,0.5,0.75,1.0), name = "Click Type Colour Scale")+
  scale_y_continuous(labels=percent_format())+
  geom_text(data=subset(episodeOrigins, perc > 0.05),
            aes(label=paste0(sprintf("%1.f", 100*perc,"%")),
                group = container),
            position = position_stack(vjust = 0.5),
            colour="black")+
  ylab("Percentage of Content CLicks from Each Origin")+
  scale_x_discrete(name = "Click Group", labels= c("All Content", "Nav Click Content"))+
  ggtitle("Type of Click Taking Users From One Episode Page to Another  \n PS_IPLAYER - Big Screen - 2020-01-15 to 2020-01-29")+
  scale_fill_manual(values =c( "#037301","#043570"))+
  theme(legend.position="bottom", legend.box = "horizontal")+
  guides(fill = "none") #this removed the legend for scale_fill_manual


####Dodge bar chart
#reset levels
episodeOrigins$container<-factor(episodeOrigins$container, levels = c( "Autoplay - Related","Autoplay - Rec","Nav Click - Related","Nav Click - Rec"))

ggplot(episodeOrigins, aes(x = clickGroup, y = perc, fill = clickGroup)) +
  geom_bar(stat = "Identity", position = position_dodge(width = 1) )+
  scale_y_continuous(limits = c(0,0.80), breaks = c(0,0.05,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8), 
                     labels = c(0,5,10,20,30,40,50,60,70,80))+
  scale_fill_manual(values = c("#037301","#043570"), name = "Click Group", labels = c("All Content", "Nav Click Content"))+
  ylab("Percentage of Content Clicks from Each Origin")+
  xlab("Route From One Episode to the Next")+
  ggtitle("Routes From One Episode to Another \n PS_IPLAYER - Big Screen - 2020-01-15 to 2020-01-29")+
  #scale_fill_discrete(name = "Click Group", labels = c("All Content", "Nav Click Content"))+
  geom_hline(yintercept = 0.05, linetype = "dashed")+
  geom_text(data=subset(episodeOrigins, perc > 0.05),
            aes(label=paste0(sprintf("%1.0f", 100*perc),"%"),),
            position = position_dodge(width = 1),
            vjust = -0.5,
            colour="black")+
  facet_wrap(~ container, nrow = 1, strip.position = "bottom")+
  theme(axis.text.x=element_blank(),
        axis.ticks.x=element_blank())



####################################      Homepage             ########################
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





#######################

head(allClickOrigins)
head(navClickOrigins)

percContentWithClicks<-
left_join(navClickOrigins %>% 
  group_by(content_click_placement) %>%
  summarise(numNavClicks = n()) %>%
  rename(placement=content_click_placement),
allClickOrigins %>%
  group_by(placement) %>%
  summarise(numAllClicks = sum(num_content_clicks)), 
by = "placement") %>%
  mutate(noNavClicks = numAllClicks - numNavClicks)%>%
  mutate(navClickPerc = round(numNavClicks/numAllClicks,3),
         noNavClickPerc = round(noNavClicks/numAllClicks,3)
         ) %>%
  select(placement,navClickPerc, noNavClickPerc)%>%
  gather(key = clickGroup, value = perc, navClickPerc, noNavClickPerc)

percContentWithClicks


### Stacked Bar graph to show how people move from one episode page to another
ggplot(data = percContentWithClicks, aes(x = placement, y = perc, fill = clickGroup)) +
  geom_bar(stat= "identity", position = "fill", width=1, color="black")+
  scale_y_continuous(limits = c(0,1), labels=percent_format(),
                     breaks = c(0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.95,1.0))+
  geom_hline(yintercept = 0.95, linetype = "dashed", color = "white")+
  geom_label(data=subset(percContentWithClicks, perc > 0.5),
            aes(label=paste0(sprintf("%1.f", 100*perc),"%"),
                fill = NULL),
            position = position_stack(vjust = 0.5),
            colour="black")+
  ylab("Percentage of Content Clicks")+
  scale_x_discrete(name = "Origin")+
  ggtitle("Proportion of Content Views with a Navigation Click \n PS_IPLAYER - Big Screen - 2020-01-15 to 2020-01-29")+
  scale_fill_manual(values =c("#043570","#037301"))+
  theme(legend.position="bottom", legend.box = "horizontal")+
  guides(fill = "none") #this removed the legend for scale_fill_manual



##### Just for home page
fancyContainerName<- read.csv("fancyContainerName.csv", header = TRUE)

percContentWithClicks_homepage<-
left_join( navClickOrigins %>% filter(content_click_placement == 'homepage' & 
                                        !str_detect(content_click_container, "u16|u13"))%>%
             group_by(content_click_placement,content_click_container) %>%
             summarise(numNavClicks = n()) %>%
             rename( "placement"=content_click_placement)%>%
             rename("container" = content_click_container),
           allClickOrigins %>% filter(placement == 'homepage' & 
                                        !str_detect(simple_container_name, "u16|u13"))%>%
             group_by(placement,simple_container_name) %>%
             summarise(numAllClicks = sum(num_content_clicks))%>%
             rename("container" = simple_container_name)%>%
             ungroup()%>%
             select(-placement),
           by = "container")%>%
  arrange(desc(numAllClicks))%>%
  filter(container != 'module-event-01-the-fa-cup')%>%
    top_n(n=5,wt = numAllClicks) %>%
  left_join(fancyContainerName) %>%
  select(-container)%>%
  rename("container" = fancy_container_name)%>%
  mutate(noNavClicks = numAllClicks - numNavClicks)%>%
  mutate(navClickPerc = round(numNavClicks/numAllClicks,3),
         noNavClickPerc = round(noNavClicks/numAllClicks,3)) %>%
  select(placement,container,navClickPerc, noNavClickPerc)%>%
  gather(key = clickGroup, value = perc, navClickPerc, noNavClickPerc)

homepagePerc<-
allClickOrigins %>% filter(placement == 'homepage' & 
                             !str_detect(simple_container_name, "u16|u13"))%>%
  group_by(placement,simple_container_name) %>%
  summarise(numAllClicks = sum(num_content_clicks))%>%
  mutate(percFromHomepage = round(numAllClicks/sum(numAllClicks),4))%>%
  rename("container" = simple_container_name)%>%
  filter(container != 'module-event-01-the-fa-cup')%>%
  top_n(n=5,wt = numAllClicks) %>%
  left_join(fancyContainerName) %>%
  select(-container)%>%
  rename("container" = fancy_container_name)%>%
  select(-numAllClicks)%>%
  mutate(perc = 1, clickGroup = "navClickGroup")

percContentWithClicks_homepage$container<-factor(percContentWithClicks_homepage$container, 
                                                 levels = c('continue watching',
                                                            'editorial featured',
                                                            'most popular',
                                                            'if you liked',
                                                            'recommended for you') )

ggplot(data = percContentWithClicks_homepage, aes(x = container, y = perc, fill = clickGroup)) +
  geom_bar(stat= "identity", position = "fill", width=1, color="black")+
  scale_y_continuous(limits = c(0,1.1), labels=percent_format(),
                     breaks = c(0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.95,1.0))+
  geom_hline(yintercept = 0.95, linetype = "dashed", color = "white")+
  geom_label(data=subset(percContentWithClicks_homepage, perc > 0.5),
             aes(label=paste0(sprintf("%1.f", 100*perc),"%"),
                 fill = NULL),
             position = position_stack(vjust = 0.5),
             colour="black")+
  geom_label(data=homepagePerc,
             aes(label=paste0(sprintf("%1.f", 100*percFromHomepage),"%"),
                 fill = NULL,
                 group = container),
             position = position_stack(vjust = 1.05),
             colour="black")+
  geom_label(aes(label= "Proportion of Homepage Clicks from Origin",
                 fill = NULL),
             y = 1.1, x =1.1 ,
             colour="black")+
  ylab("Percentage of Content Clicks")+
  scale_x_discrete(name = "Origin Within Homepage")+
  ggtitle("Proportion of Content Views with a Navigation Click - Homepage \n PS_IPLAYER - Big Screen - 2020-01-15 to 2020-01-29")+
  scale_fill_manual(name = "Click Group", labels = c("Nav Clicks","No Nav Click"),values =c("#043570","#037301"))+
  theme(legend.position="bottom", legend.box = "horizontal")+
  facet_wrap(~ placement, nrow = 1, strip.position = "top")+
  guides(fill = guide_legend(override.aes = aes(label = "")))#removed the 'a' from the legend



