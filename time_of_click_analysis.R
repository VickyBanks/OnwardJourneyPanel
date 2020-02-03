library(ggplot2)
library(ggridges)
library(dplyr)
library(ggrepel)

clickTime<- read.csv("time_to_click.csv", header = TRUE)
clickTime <- clickTime %>% rename(clickTime_sec = time_since_content_start_sec)
clickTime <- clickTime %>% rename(menuType = menu_type)
clickTime<- na.omit(clickTime)
clickTime %>% filter(is.na(clickTime_sec))

clickTime %>% filter(clickTime_sec<0)
summary(clickTime)

## Look at data in groups of first 1 minute, first 5, etc
clickTimeGroups<- clickTime %>% 
  mutate(timeRange_sec = cut(clickTime_sec, 
                             breaks = c(-1, 60, 300, 600, 900, 1200, Inf),
                             labels = c("0-1", "1-5", "5-10", "10-15", "15-20", "20+"))) %>% 
  group_by(timeRange_sec) %>% 
  summarize(numInRange=n())


ggplot(data = clickTimeGroups, aes(x=timeRange_sec, y=numInRange))+
  geom_bar(stat = "identity")+
  scale_y_continuous(limits = c(0,5000000), breaks = c(0, 1000000,2000000,3000000,4000000,5000000), labels = c(0, 1,2,3,4,5))+
  ylab("Number of Visits with Click in Time Range (millions)")+
  xlab("Time Range (mins)")
  theme_classic()

 ### Look at data by minute
  clickTimeMinutes<- clickTime %>% 
    mutate(timeRange_sec = cut(clickTime_sec, 
                               breaks = c(-1, 60,120,180,240, 300,360,420,480,540, 600,Inf),
                               labels = c("0-1", "1-2", "2-3", "3-4", "4-5", "5-6", "6-7", "7-8", "8-9", "9-10", "10+"))) %>% 
    group_by(timeRange_sec) %>% 
    summarize(numInRange=n()) %>%
    mutate(perc = round(100*numInRange/sum(numInRange),1))
  
  ggplot(data = clickTimeMinutes, aes(x=timeRange_sec, y=numInRange))+
    geom_bar(stat = "identity", fill = "blue")+
    scale_y_continuous(limits = c(0,5000000), breaks = c(0,250000, 1000000,2000000,3000000,4000000,5000000), labels = c(0,0.25, 1,2,3,4,5))+
    ylab("Number of Visits with Click in Time Range (millions)")+
    xlab("Time Range (mins)")+
    geom_hline(yintercept = 250000)+
    geom_label(data=subset(clickTimeMinutes, perc > 6),
              aes(label=paste0(sprintf("%1.0f", perc),"%"),),
              position = position_stack(vjust = 0.5),
              colour="black")+
    geom_label(data=subset(clickTimeMinutes, perc >= 5 & perc < 6),
               aes(label=paste0(sprintf("%1.0f", perc),"%"),),
               position = position_stack(vjust = 1.6),
               colour="black")+
    ggtitle("Number of Clicks to the Onward Journey Panel 'x' Minutes After Content Start \n PS_IPLAYER - Big Screen - 2019-11-01 to 2019-11-14" )+
  theme_classic() 

  
## Look at data depending on which menu the click was from 
  clickTimeMinsMenu<- clickTime %>% 
    mutate(timeRange_sec = cut(clickTime_sec, 
                               breaks = c(-1, 60,120,180,240, 300,360,420,480,540, 600,Inf),
                               labels = c("0-1", "1-2", "2-3", "3-4", "4-5", "5-6", "6-7", "7-8", "8-9", "9-10", "10+"))) %>% 
    group_by(menuType, timeRange_sec) %>% 
    summarize(numInRange=n()) %>%
    mutate(perc = round(100*numInRange/sum(numInRange),1)) 
  
  
  ggplot(data = clickTimeMinsMenu, aes(x=timeRange_sec, y=numInRange/1000000, fill = menuType))+
    geom_bar(stat = "identity")+
    #scale_y_continuous(limits = c(0,5000000), breaks = c(0,250000, 1000000,2000000,3000000,4000000,5000000), labels = c(0,0.25, 1,2,3,4,5))+
    ylab("Number of Visits with Click in Time Range (millions)")+
    xlab("Time Range (mins)")+
    #geom_hline(yintercept = 250000)+
    geom_label(data=subset(clickTimeMinsMenu, perc >= 10),
               aes(label=paste0(sprintf("%1.0f", perc),"%"),),
               position = position_stack(vjust = 0.5),
               colour="black",
               fill = "white")+
    geom_label(data=subset(clickTimeMinsMenu, perc >= 5 & perc < 9),
               aes(label=paste0(sprintf("%1.0f", perc),"%"),),
               position = position_stack(vjust = 1.6),
               colour="black", 
               fill = "white")+
    geom_label(data=subset(clickTimeMinsMenu, perc >= 9 & perc < 10),
               aes(label=paste0(sprintf("%1.0f", perc),"%"),),
               position = position_stack(vjust = 1.3),
               colour="black", 
               fill = "white")+
    ggtitle("Number of Clicks to the Onward Journey Panel 'x' Minutes After Content Start \n PS_IPLAYER - Big Screen - 2019-11-01 to 2019-11-14" )+
    theme_classic() +
    facet_wrap(~ menuType, nrow = 1, scales = "free")+
    theme(legend.position = "none")
  

  
## Look at data depending on where their click took them
nextEpInfo<- read.csv("next_ep_type.csv", header = TRUE)
nextEpInfo <- nextEpInfo %>% rename(clickTime_sec = time_since_content_start_sec)
nextEpInfo <- nextEpInfo %>% rename(menuType = menu_type)
nextEpInfo <- nextEpInfo %>% rename(uv = unique_visitor_cookie_id)
nextEpInfo %>% filter(is.na(clickTime_sec))
nextEpInfo<- na.omit(nextEpInfo)
nextEpInfo$visit_id <-as.character(nextEpInfo$visit_id)  
nextEpInfo<-nextEpInfo %>% mutate(nextEpClass = paste(same_brand,same_brand_series,next_ep))


#turn binary into labels
nextEpClass<- data.frame("nextEpClass" = c("1 1 1","1 1 0","1 0 1","1 0 0","0 0 0"),
               "clickDestination" = c("Same Brand & Series, Next Ep", "Same Brand & Series, Diff Ep", "Same Brand, Diff Series, Next Ep","Same Brand, Diff Series, Diff Ep","New Brand"))

nextEpInfo<- left_join(nextEpInfo, nextEpClass, by = "nextEpClass")
nextEpInfo$nextEpClass <- factor(nextEpInfo$nextEpClass, levels=c("1 1 1","1 1 0","1 0 1","1 0 0","0 0 0"))
nextEpInfo$clickDestination <- factor(nextEpInfo$clickDestination, levels=c("Same Brand & Series, Next Ep", "Same Brand & Series, Diff Ep", "Same Brand, Diff Series, Next Ep","Same Brand, Diff Series, Diff Ep","New Brand"))

#split into minutes
nextEpInfoMins<- nextEpInfo %>% 
  mutate(timeRange_sec = cut(clickTime_sec, 
                             breaks = c(-1, 60,120,180,240, 300,360,420,480,540, 600,Inf),
                             labels = c("0-1", "1-2", "2-3", "3-4", "4-5", "5-6", "6-7", "7-8", "8-9", "9-10", "10+"))) %>% 
  group_by(nextEpClass,clickDestination, timeRange_sec) %>% 
  summarize(numInRange=n()) %>%
  mutate(perc = round(100*numInRange/sum(numInRange),1)) 




ggplot(data = nextEpInfoMins, aes(x=timeRange_sec, y=numInRange/1000000, fill = clickDestination))+
  geom_bar(stat = "identity")+
  #scale_y_continuous(limits = c(0,5000000), breaks = c(0,250000, 1000000,2000000,3000000,4000000,5000000), labels = c(0,0.25, 1,2,3,4,5))+
  ylab("Number of Visits with Click in Time Range (millions)")+
  xlab("Time Range (mins)")+
  geom_label(data=subset(nextEpInfoMins, perc >= 9),
             aes(label=paste0(sprintf("%1.0f", perc),"%"),),
             position = position_stack(vjust = 0.5),
             colour="black", 
             fill = "white")+
  ggtitle("Number of Clicks to the Onward Journey Panel 'x' Minutes After Content Start \n PS_IPLAYER - Big Screen - 2019-11-01 to 2019-11-14" )+
  scale_fill_manual(name = "Click Destination", values=wes_palette(n=5, name="Zissou1"))+
  theme_classic() +
  facet_wrap(~ clickDestination, ncol = 2, nrow = 3, scales = "free") +
 theme(legend.position = "none")

  