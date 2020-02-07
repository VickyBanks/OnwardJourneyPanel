library(ggplot2)
library(ggridges)
library(dplyr)
library(ggrepel)
library(tidyverse)


allClickOrigins<- read.csv("allContentClickOrigin.csv", header = TRUE)
nextEpInfo <- nextEpInfo %>% rename(clickTime_sec = time_since_content_start_sec)