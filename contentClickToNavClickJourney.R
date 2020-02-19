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


## Read in next episode information and format more usefully
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


## Join click before to after i.e the origin of the content to the destination from the content
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

#create df for names
nextEpClass <- data.frame("nextEpClass" = c("0 0 0","1 0 1","1 0 0","1 1 1","1 1 0"),
                          "clickDestination" = c("New Brand",
                                                 "Same Brand, Diff Series, Next Ep", 
                                                 "Same Brand, Diff Series, Diff Ep",
                                                 "Same Brand & Series, Next Ep",
                                                 "Same Brand & Series, Diff Ep"))
#Join in click destination names to binary to make ti easier to read
originToDestinationSummary<- left_join(originToDestinationSummary, nextEpClass, by = "nextEpClass")

#set factor levels for stacked bar graph
originToDestinationSummary$nextEpClass<- factor(originToDestinationSummary$nextEpClass, 
                                                levels= c("0 0 0","1 0 1","1 0 0","1 1 1","1 1 0"))
originToDestinationSummary$clickDestination<- factor(originToDestinationSummary$clickDestination, 
                                                levels=  c("New Brand",
                                                           "Same Brand, Diff Series, Next Ep", 
                                                           "Same Brand, Diff Series, Diff Ep",
                                                           "Same Brand & Series, Next Ep",
                                                           "Same Brand & Series, Diff Ep"))
#Create summary table for each origin
originTotalPerc<- originToDestination %>%
  group_by(content_click_placement)%>%
  summarise(numEachMenu = n()) %>%
  mutate(perc = numEachMenu/sum(numEachMenu)) %>%
  arrange(desc(perc)) %>% select(-numEachMenu) %>%
  mutate(clickDestination = "Same Brand & Series, Diff Ep")

######## Stacked Bar chart with lots of labels #########
ggplot(originToDestinationSummary, aes(x = content_click_placement, y = perc, fill = clickDestination))+
  geom_bar(stat= "identity", position = "fill", width=1, color="black")+
  #scale_y_continuous(labels=percent_format())+
  scale_y_continuous(limits = c(0,1.1), breaks = c(0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8, 0.9, 1.0), 
                     labels = percent_format())+
  geom_text(data=subset(originToDestinationSummary, perc > 0.06),
            aes(label=paste0(sprintf("%1.f", 100*perc),"%"),
                group = nextEpClass),
            position = position_stack(vjust = 0.5),
            colour="black")+
  geom_label(data = originTotalPerc, 
            aes(label=paste0(sprintf("%1.f", 100*perc),"%"),
                fill = NULL,
                y = 1.05))+
  geom_label(data = originTotalPerc%>%filter(content_click_placement == 'homepage'),
             aes(label="                                        Proportion of Clicks from Each Origin",
                 fill = NULL,
                 y = 1.1,
                 x = 1
                 ))+
  ylab("Percentage of Journeys")+
  ggtitle(" Percentage of Content Clicks from Each Origin to Each Destination \n PS_IPLAYER - Big Screen - 2020-01-15 to 2020-01-29")+
  scale_fill_manual(name = "Click Destination", values=rev(wes_palette(n=5, name="Zissou1")))+
  scale_x_discrete(name = "Content Origin")+
  theme(legend.position="right", legend.box = "vertical")+
  guides(fill = guide_legend(override.aes = aes(label = "")))#removed the 'a' from the legend


######### The above done as separate charts #######
#create new df for ease and re-set factor levels
originToDestinationSummary2<-originToDestinationSummary
originToDestinationSummary2$nextEpClass<- factor(originToDestinationSummary2$nextEpClass, 
                                                levels= c("1 1 0","1 1 1","1 0 0","1 0 1","0 0 0"))
originToDestinationSummary2$clickDestination<- factor(originToDestinationSummary2$clickDestination, 
                                                     levels=  c("Same Brand & Series, Diff Ep",
                                                                "Same Brand & Series, Next Ep",
                                                                "Same Brand, Diff Series, Diff Ep",
                                                                "Same Brand, Diff Series, Next Ep",
                                                                "New Brand"))
originToDestinationSummary2$content_click_placement<- factor(originToDestinationSummary2$content_click_placement,
                                                             levels = c('episode',
                                                                        'homepage',
                                                                        'channels',
                                                                        'categories',
                                                                        'tleo',
                                                                        'deeplink',
                                                                        'search',
                                                                        'other'))
ggplot(data = originToDestinationSummary2, 
       aes(x=clickDestination, y=perc, fill = clickDestination))+
  geom_bar(stat = "identity")+
  scale_y_continuous(limits = c(0,1), breaks = c(0,0.1,0.2,0.3,0.4,0.5,0.6,0.7), 
                     labels = percent_format())+
  geom_label(data = originTotalPerc,
             aes(label = paste0("                ","Origin for ",round(100*perc,0), "% of clicks"),
             fill = NULL,
             y = 0.8,
             x = 1))+
  geom_text(data=subset(originToDestinationSummary2, perc > 0.095),
           aes(label=paste0(sprintf("%1.f", 100*perc),"%"),
               group = nextEpClass),
           position = position_stack(vjust = 0.5),
           colour="black")+
  ylab("Percentage of Journeys")+
  ggtitle(" Percentage of Content Clicks from Each Origin to Each Destination \n PS_IPLAYER - Big Screen - 2020-01-15 to 2020-01-29")+
  scale_fill_manual(name = "Click Destination", values=(wes_palette(n=5, name="Zissou1")))+
  xlab("")+
  theme_classic() +
  facet_wrap(~ content_click_placement, ncol = 2, nrow = 4, scales = "fixed") +
  theme(legend.position = "bottom",
        legend.box = "horizontal", 
        axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank()) +
  guides(fill = guide_legend(override.aes = aes(label = ""), nrow = 3,byrow = TRUE ))


#################################### Sankey - Complete values ################################################################################################

allToOrigin<- originToDestination %>%
  group_by(content_click_placement)%>%
  summarise(total = n())

allToOrigin$content_click_placement<- factor(allToOrigin$content_click_placement, levels = c('episode','homepage', 'channels','categories','tleo', 'deeplink','search','other'))
allToOrigin<- allToOrigin %>% arrange(content_click_placement) %>% 
  mutate(startNode = 0,endNode = c(1,2,3,4,5,6,7,8))%>%
  select(-content_click_placement)

originNums<- data.frame("content_click_placement" = factor(c('episode','homepage', 'channels','categories','tleo','deeplink','search','other')),
                        "startNode" = c(1,2,3,4,5,6,7,8))

destinationNums<- data.frame("clickDestination" = factor(c("New Brand",
                                                           "Same Brand & Series, Next Ep",
                                                           "Same Brand & Series, Diff Ep",
                                                           "Same Brand, Diff Series, Next Ep", 
                                                           "Same Brand, Diff Series, Diff Ep")),
                        "endNode" = c(9,10,11,12,13))

sankeyFullJourneyDF<- originToDestinationSummary %>% left_join(originNums) %>% left_join(destinationNums)
sankeyValues<- sankeyFullJourneyDF %>% group_by(startNode, endNode) %>% summarise(total = sum(numEachMenu)) %>%
  bind_rows(allToOrigin)%>%arrange(startNode)
sankeyValues%>%arrange(startNode)

nodes = data.frame("name" = factor(c('all clicks',
                                     'episode - 32%',
                                     'homepage - 31%',
                                     'channels - 16%',
                                     'categories - 9%',
                                     'tleo - 8%',
                                     'deeplink - 3%',
                                     'search - 1%',
                                     'other - 0.3',
                                     "New Brand - 9%",
                                     "Same Brand & Series, Next Ep - 23%",
                                     "Same Brand & Series, Diff Ep - 51%",
                                     "Same Brand, Diff Series, Next Ep - 0.3%", 
                                     "Same Brand, Diff Series, Diff Ep - 16%")),
                   "group" = as.character(c(0,1,2,3,4,5,6,7,8,9,10,11,12,13)))


links <- data.frame(source =c(0,	0,	0,	0,	0,	0,	0,	0,	1,	1,	1,	1,	1,	2,	2,	2,	2,	2,	3,	3,	3,	3,	3,	4,	4,	4,	4,	4,	5,	5,	5,	5,	5,	6,	6,	6,	6,	6,	7,	7,	7,	7,	7,	8,	8,	8,	8,	8),
                    target = c(1,	2,	3,	4,	5,	6,	7,	8,	9,	10,	11,	12,	13,	9,	10,	11,	12,	13,	9,	10,	11,	12,	13,	9,	10,	11,	12,	13,	9,	10,	11,	12,	13,	9,	10,	11,	12,	13,	9,	10,	11,	12,	13,	9,	10,	11,	12,	13),
                    value = c(2061061,	1972029,	1013925,	562396,	524383,	164281,	19950,	32381,	341084,	423609,	957353,	10483,	328532,	107022,	541730,	1014535,	8593,	300149,	39424,	171071,	658042,	223,	145165,	27577,	130202,	294270,	144,	110203,	63868,	150186,	207838,	1884,	100607,	14723,	36503,	84867,	246,	27942,	2779,	2177,	9003,	73,	5918,	2412,	7385,	16400,	36,	6148))

# links<- matrix(byrow = T, ncol = 3,
#                           sankeyValues)
# links<-data.frame(links)
names(links) <- c("source","target","value")
nodes$group<-as.factor(c("a","b","c","d","e","f","g","h","i","j","k","l","m","n"))

colours <- 'd3.scaleOrdinal() .domain(["a","b","c","d","e","f","g","h","i","j","k","l","m"]) 
.range(["#043570","#043570","#043570","#043570","#043570","#043570","#043570","#043570","#043570",
"#F21A00","#3B9AB2", "#78B7C5","#E1AF00","#EBCC2A"])'

#lengths should be the same
length(unique(c(links$source, links$target)))
length(nodes$group)

sankeyJourney<- sankeyNetwork(
  Links = links, 
  Nodes = nodes, 
  Source = "source", 
  Target = "target", 
  Value = "value", 
  NodeID = "name",
  NodeGroup = "group", 
  colourScale = colours, 
  fontSize = 12,
  iterations = 0)#this puts the order as in the nodes dataframe
sankeyJourney

onRender(sankeyJourney,
         '
function(el, x) {
    var sankey = this.sankey;
    var path = sankey.link();
    var nodes = d3.selectAll(".node");
    var link = d3.selectAll(".link")
    var width = el.getBoundingClientRect().width - 40;
    var height = el.getBoundingClientRect().height - 40;

    window.dragmove = function(d) {
      d3.select(this).attr("transform", 
        "translate(" + (
           d.x = Math.max(0, Math.min(width - d.dx, d3.event.x))
            ) + "," + (
            d.y = Math.max(0, Math.min(height - d.dy, d3.event.y))
          ) + ")");
      sankey.relayout();
      link.attr("d", path);
    };

    nodes.call(d3.drag()
      .subject(function(d) { return d; })
      .on("start", function() { this.parentNode.appendChild(this); })
      .on("drag", dragmove));
  }
  '
)


#################################### Sankey - Simple Values ################################################################################################


simpleSankeyValues<-sankeyValues %>% ungroup %>%
  filter(startNode != 0 & startNode >=1 & startNode <=6) %>%
  mutate(startNode2 = startNode-1,
         endNode2 = endNode-3) %>%
  select(-endNode, -startNode) %>%
  rename(startNode = startNode2, endNode = endNode2)

nodes = data.frame("name" = factor(c(
                                     'episode - 32%',
                                     'homepage - 31%',
                                     'channels - 16%',
                                     'categories - 9%',
                                     'tleo - 8%',
                                     'deeplink - 3%',
                                     
                                     "New Brand - 9%",
                                     "Same Brand & Series, Next Ep - 23%",
                                     "Same Brand & Series, Diff Ep - 51%",
                                     "Same Brand, Diff Series, Next Ep - 0.3%", 
                                     "Same Brand, Diff Series, Diff Ep - 16%")),
                   "group" = as.character(c(0,1,2,3,4,5,6,7,8,9,10)))

links <- data.frame(source =c(0,	0,	0,	0,	0,	1,	1,	1,	1,	1,	2,	2,	2,	2,	2,	3,	3,	3,	3,	3,	4,	4,	4,	4,	4,	5,	5,	5,	5,	5),
                    target = c(6,	7,	8,	9,	10,	6,	7,	8,	9,	10,	6,	7,	8,	9,	10,	6,	7,	8,	9,	10,	6,	7,	8,	9,	10,	6,	7,	8,	9,	10),
                    value = c(341084,	423609,	957353,	10483,	328532,	107022,	541730,	1014535,	8593,	300149,	39424,	171071,	658042,	223,	145165,	27577,	130202,	294270,	144,	110203,	63868,	150186,	207838,	1884,	100607,	14723,	36503,	84867,	246,	27942))
#lengths should be the same
length(unique(c(links$source, links$target)))
length(nodes$group)

nodes$group<-as.factor(c("a","b","c","d","e","f","g","h","i","j","k"))

colours <- 'd3.scaleOrdinal() .domain(["a","b","c","d","e","f","g","h","i","j","k"]) 
.range(["#043570","#043570","#043570","#043570","#043570","#043570",
"#F21A00","#3B9AB2", "#78B7C5","#E1AF00","#EBCC2A"])'
sankeyJourney<- sankeyNetwork(
  Links = links, 
  Nodes = nodes, 
  Source = "source", 
  Target = "target", 
  Value = "value", 
  NodeID = "name",
  NodeGroup = "group", 
  colourScale = colours, 
  fontSize = 12,
  iterations = 0)#this puts the order as in the nodes dataframe
sankeyJourney

#################################### Time to Click Depending on Origin ################################################################################################

timeToClickByOrigin <- originToDestination %>%
mutate(timeRange_sec = cut(clickTime_sec, 
                           breaks = c(-1, 60,120,180,240, 300,360,420,480,540, 600,Inf),
                           labels = c("0-1", "1-2", "2-3", "3-4", "4-5", "5-6", "6-7", "7-8", "8-9", "9-10", "10+"))) %>% 
  group_by(content_click_placement, timeRange_sec) %>% 
  summarize(numInRange=n()) %>%
  mutate(perc = round(100*numInRange/sum(numInRange),1)) 


