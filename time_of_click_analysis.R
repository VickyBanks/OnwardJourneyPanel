library(ggplot2)
library(ggridges)
library(dplyr)

clickTime<- read.csv("time_to_click.csv", header = TRUE)
clickTime <- clickTime %>% rename(clickTime_sec = time_since_content_start_sec)
#clickTime$visit_id <- as.factor(clickTime$visit_id)
clickTime<- na.omit(clickTime)
clickTime %>% filter(is.na(clickTime_sec))

clickTime %>% filter(clickTime_sec<0)
summary(clickTime)

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

 ############## 
  clickTimeMinutes<- clickTime %>% 
    mutate(timeRange_sec = cut(clickTime_sec, 
                               breaks = c(-1, 60,120,180,240, 300,360,420,480,540, 600,Inf),
                               labels = c("0-1", "1-2", "2-3", "3-4", "4-5", "5-6", "6-7", "7-8", "8-9", "9-10", "10+"))) %>% 
    group_by(timeRange_sec) %>% 
    summarize(numInRange=n())
  
  ggplot(data = clickTimeMinutes, aes(x=timeRange_sec, y=numInRange))+
    geom_bar(stat = "identity")+
    scale_y_continuous(limits = c(0,5000000), breaks = c(0, 1000000,2000000,3000000,4000000,5000000), labels = c(0, 1,2,3,4,5))+
    ylab("Number of Visits with Click in Time Range (millions)")+
    xlab("Time Range (mins)")+
    geom_hline(yintercept = 250000)+
  theme_classic()

