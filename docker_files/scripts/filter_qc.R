# Loading
library(tidyverse)
library(readxl)


args <- commandArgs(trailingOnly = TRUE)
# set output paths
input_qcfile  <- args[1]

# xls files
qc_data <- read_excel(input_qcfile,  #"/home/ec2-user/efs/docker/Xmeng/16S/Sanger/QB_RAW_DATA/713642/713642_autoqc.xls",
col_names = c("Sample", "LOR","Q40", "Q20","Score", "QC Notes"), skip = 1
#.name_repair = "universal" 
)

head(qc_data)

filtered_qc <- filter(qc_data,  LOR > 200, Score >= 25 )

#head(filtered_qc)

# write the summary file
write_csv(filtered_qc, "filter_qc_table.csv")


