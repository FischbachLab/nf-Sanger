#install.packages("tidyverse")

library(tidyverse)


#strain_df = read_tsv("/home/ec2-user/efs/docker/Xmeng/16S/Sanger/PM013_2/genus.list", col_names = FALSE)
top3_df <- read_tsv("all_samples_top3.tsv", col_names = FALSE)
filtered3_df <- read_tsv("all_samples_filtered3.tsv", col_names = FALSE)
cov_df <- read_csv("samples.cov_stats.csv", col_names = FALSE)
score_df <- read_csv("qc_mean_score.csv", col_names = FALSE)

#head (strain_df)
#head (top3_df)
#summary_df <- merge(top3_df, filtered3_df, by.x = 1, by.y = 1) #,  all= TRUE)
#summary_df <- bind_cols(tibble(top3_df = 1:4), tibble( filtered3_df= 2:3))
summary_df <- bind_cols(top3_df, filtered3_df)
#head (summary_df)
summary_df2 <- merge(summary_df, cov_df, by.x = 1, by.y = 1,) # all.x = TRUE) #, all.y = TRUE)
#head (summary_df2)

summary_df3 <- merge(summary_df2, score_df, by.x = 1, by.y = 1) #, all.x = TRUE) #, all.y = TRUE)
#head (summary_df3)

# Add headers
colnames(summary_df3 ) <- c("Sample_ID", "Observed_Top_Annotation", "Top_Identity(%)", "Length", "Top_Qcov(%)", "ID", "Filtered_Annotation", "Filtered_Identity(%)", "Filtered_Qcov(%)", "Completeness(%)", "Adjusted_Qcov(%)", "num_primer_reads", "mean_coverage", "sd_coverage", "mean_qc_score" ) 

# by position my_data2 <- my_data[, c(5, 4, 1, 2, 3)]
col_order <- c("Sample_ID", "Observed_Top_Annotation", "Top_Identity(%)", "Top_Qcov(%)", "Filtered_Annotation", "Filtered_Identity(%)", "Completeness(%)", "Adjusted_Qcov(%)", "Length", "num_primer_reads", "mean_coverage", "sd_coverage", "mean_qc_score" )
my_summary <- summary_df3[, col_order]

# From Melhem's requests
# Minimum length required 1430 bp for both silva and ncbi analysis
# Minimum Completeness% 91% for both silva and ncbi analysis
# Silva
#  -97.3%  and above: pass
#  -94.0-<97.3: to be reviewed
#  -<94.0: Fail

#my_summary <- mutate(my_summary, Status = ifelse( my_summary[,7] >=91 & my_summary[,8] >=97.3 & Length >= 1430, "Pass", "Fail"))
my_summary <- mutate(my_summary, Status = case_when( my_summary[,7] >=91 & my_summary[,8] >=97.3 & Length >= 1430 ~ "Pass",
						     my_summary[,7] >=91 & my_summary[,8] >=94 & my_summary[,8] < 97.3 & Length >= 1430 ~ "Review",
						     TRUE ~ "Fail"))      


#head(summary_df2)
#write_csv(summary_df, "tmp1.csv")
#write_csv(summary_df2, "tmp2.csv")
# write the summary file
write_csv(my_summary, "16S_silva_summary.csv")


