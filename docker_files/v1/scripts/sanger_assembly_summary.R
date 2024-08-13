library(tidyverse)

silva_df <- read_csv("16S_silva_summary.csv") #, col_names = FALSE)
ncbi_df <- read_csv("16S_ncbi_summary.csv") #, col_names = FALSE)

silva_df <- select(silva_df, "Sample_ID", "Filtered_Annotation", "Filtered_Identity(%)", "Completeness(%)", "Adjusted_Qcov(%)", "Status")
#head (silva_df)
ncbi_df <-  select(ncbi_df, "Filtered_Annotation", "Filtered_Identity(%)",  "Completeness(%)", "Adjusted_Qcov(%)", "Length",  "num_primer_reads", "mean_coverage", "sd_coverage", "mean_qc_score",  "Status") 
#head (ncbi_df)
#bind two tables by selected columns
db2_df <- cbind(silva_df, ncbi_df)

#colnames(db2_df) <- c("Sample_ID", "Observed_Top_Annotation", "Top_Identity(%)", "Length", "Top_Qcov(%)", "Filtered_Annotation", "Filtered_Identity(%)", "Filtered_Qcov(%)", "Completeness(%)", "Adjusted_Qcov(%)", "num_primer_reads", "mean_coverage", "sd_coverage", "mean_qc_score", "Sample_ID", "NCBI_Observed_Top_Annotation", "NCBI_Top_Identity(%)", "NCBI_Length", "NCBI_Top_Qcov(%)", "NCBI_Filtered_Annotation", "NCBI_Filtered_Identity(%)", "NCBI_Filtered_Qcov(%)", "NCBI_Completeness(%)", "NCBI_Adjusted_Qcov(%)", "NCBI_num_primer_reads", "NCBI_mean_coverage", "NCBI_sd_coverage", "NCBI_mean_qc_score") 

colnames(db2_df) <- c("Sample_ID", "Silva_Filtered_Annotation", "Silva_Filtered_Identity(%)", "Silva_Completeness(%)", "Silva_Adjusted_Qcov(%)", "Silva_Status", "NCBI_Filtered_Annotation", "NCBI_Filtered_Identity(%)", "NCBI_Completeness(%)", "NCBI_Adjusted_Qcov(%)","Length", "num_primer_reads", "mean_coverage", "sd_coverage", "mean_qc_score", "NCBI_Status") 

primer_df = read_tsv("all_samples_primer_counts.tsv", col_names = FALSE)
# Add headers
colnames(primer_df ) <- c("Sample_ID", "Primer", "Counts")
primer_df <- spread(primer_df, Primer, Counts) 
#primer_df[is.na(primer_df)] = 0

#colnames(silva_df)
#colnames(ncbi_df)
#primer_df <- mutate(primer_df, Status = ifelse(  primer_df[,2] >=1 & primer_df[,3]  >=1 & primer_df[,4] >=1 & primer_df[,5]  >=1, "PASS", "FAIL" ) ) 
#write_csv(primer_df, "primer_summary.csv")

#Add each primer count into the table
db2_df <- merge(db2_df, primer_df, by.x = 1) 
#order the columns
col_order <- c("Sample_ID", "Silva_Filtered_Annotation", "Silva_Filtered_Identity(%)", "Silva_Completeness(%)", "Silva_Adjusted_Qcov(%)", "NCBI_Filtered_Annotation", "NCBI_Filtered_Identity(%)", "NCBI_Completeness(%)", "NCBI_Adjusted_Qcov(%)","Length", "num_primer_reads", "28F", "789F", "907R", "1492R", "mean_coverage", "sd_coverage", "mean_qc_score", "Silva_Status", "NCBI_Status")

# reads primers from a file: unlist a list of vector to combine a vector
v1 <- c("Sample_ID", "Silva_Filtered_Annotation", "Silva_Filtered_Identity(%)", "Silva_Completeness(%)", "Silva_Adjusted_Qcov(%)", "NCBI_Filtered_Annotation", "NCBI_Filtered_Identity(%)", "NCBI_Completeness(%)", "NCBI_Adjusted_Qcov(%)","Length", "num_primer_reads")
v2 <- unlist(strsplit( readLines("/mnt/efs/scratch/Xmeng/data/16S/Sanger/sanger_scripts/4primers"),  " " ))
v3 <- c("mean_coverage", "sd_coverage", "mean_qc_score", "Silva_Status", "NCBI_Status")
col_order <- c(v1, v2, v3)


db2_df <- db2_df[, col_order]


db2_df <- mutate(db2_df, Silva_Status = case_when( db2_df[,12] ==0 | db2_df[,13] ==0  | db2_df[,14] ==0  | db2_df[,15] ==0 ~ "FAIL",
						     db2_df[,4] >=91 & db2_df[,5] >=97.3 &  Length >= 1430 ~ "PASS",
                                                     db2_df[,4] >=91 & db2_df[,5] >=94 & db2_df[,5] < 97.3 & Length >= 1430 ~ "REVIEW",
                                                     TRUE ~ "FAIL"))  

db2_df <- mutate(db2_df, NCBI_Status = case_when( db2_df[,12] ==0 | db2_df[,13] ==0  | db2_df[,14] ==0  | db2_df[,15] ==0 ~ "FAIL",
                                                     db2_df[,8] >=91 & db2_df[,9] >=96 &  Length >= 1430 ~ "PASS",
                                                     db2_df[,8] >=91 & db2_df[,9] >=93.5 & db2_df[,9] < 96 & Length >= 1430 ~ "REVIEW",
                                                     TRUE ~ "FAIL"))

# Add a column for assembled consensus 
cons_df <- read_csv("all.cons.csv", col_names = FALSE)
colnames(cons_df) <- c("Sample_ID", "Assembled_Sequence")

# left join
sum_df <- merge(db2_df, cons_df, by.x = 1, by.y = 1,  all.x = TRUE)

write_csv(sum_df, "sanger_assembly_summary.csv")
