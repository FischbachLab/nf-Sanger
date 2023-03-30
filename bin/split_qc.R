#!/usr/bin/env Rscript

# Loading
library(tidyverse)
library(readxl)
library(dplyr)

args <- commandArgs(trailingOnly = TRUE)
# set output paths
input_qcfile  <- args[1]

# xls files
qc_data <- read_excel(input_qcfile,  #"/home/ec2-user/efs/docker/Xmeng/16S/Sanger/QB_RAW_DATA/713642/713642_autoqc.xls",
col_names = c("Sample", "LOR","Q40", "Q20","Score", "QC Notes"), skip = 1
#.name_repair = "universal"
)
qc_data$LOR <- as.numeric(as.character(qc_data$LOR))
qc_data$Score <- as.numeric(as.character(qc_data$Score))
head(qc_data)

filtered_qc <- filter(qc_data,  LOR >= 0, Score >= 25 )


# split the sample name
qc = separate(filtered_qc, col = "Sample", into = c("Sample","Primer"),  sep = "_")

# covert string to numeric number
qc$Score <- as.numeric(as.character(qc$Score))

#head (summarise(qc , mean_score = max(Score)))
write_csv(qc, "qc_full.csv", col_names = FALSE)


qc %>%
  group_by(Sample) %>%
  #summarize(n()) %>%
  summarize(Mean_Score = mean(Score, na.rm = TRUE)) %>%
# write the summary file
write_csv("qc_mean_score.csv", col_names = FALSE)

#warning()
