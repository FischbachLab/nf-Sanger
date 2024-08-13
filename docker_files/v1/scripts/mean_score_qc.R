# Loading
library(tidyverse)
library(readxl)
library(dplyr)

args <- commandArgs(trailingOnly = TRUE)
# set output paths
input_qcfile  <- args[1]

# xls files
qc_data <- read_csv(input_qcfile,
col_names = c("Sample", "Primer", "LOR","Q40", "Q20","Score", "QC Notes"))  #, skip = 1
#)

head(qc_data)

filtered_qc <- filter(qc_data,  LOR >= 0, Score >= 0 )

# split the sample name
#qc = separate(filtered_qc, col = "Sample", into = c("Sample","Primer"),  sep = "_")

# covert string to numeric number
#qc$Score <- as.numeric(as.character(qc$Score))

#head (summarise(qc , mean_score = max(Score)))
#write_csv(qc, "qc_full.csv", col_names=0)


filtered_qc %>%
  group_by(Sample) %>%
  #summarize(n()) %>%
  summarize(Mean_Score = mean(Score, na.rm = TRUE)) %>%
# write the summary file
write_csv("qc_mean_score.csv", col_names = FALSE)

#warning()
