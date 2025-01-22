#!/usr/bin/env Rscript

library(isolateR)

args <- commandArgs(trailingOnly = TRUE)
ab1_path <-  args[1] 

#ab1_path = paste("/mnt/efs/scratch/Xmeng/data/16S/Sanger/QB_RAW_DATA_by_group", project, "all_ab1_files", sep="/")
#ab1_path = paste(".", project, "all_ab1_files", sep="/")

# Run isoQC to trim poor quality regions
isoQC.S4 <- isoQC(input=ab1_path, sliding_window_cutoff=20)


# Assemble full length 16S seqeunce
fpath2 <- file.path(ab1_path, "isolateR_output/01_isoQC_trimmed_sequences_PASS.csv")
sanger_assembly(input =fpath2, suffix = "_1492R.ab1|_27F.ab1|_789F.ab1|_907R.ab1")

fpath3 <- file.path(ab1_path,"isolateR_output/01_isoQC_trimmed_sequences_PASS_consensus.csv")

# Perform quick classification
isoTAX.S4 <- isoTAX(input=fpath3, quick_search=TRUE)

# Don't Generate strain library any longer
#fpath4 <- file.path(ab1_path, "isolateR_output/02_isoTAX_results.csv")
#isoLIB.S4 <- isoLIB(input=fpath4,
#                    old_lib_csv=NULL,
#                    group_cutoff=0.995,
#                    include_warnings=FALSE)


# all in one step
#isoALL.S4 <- isoALL(input=ab1_path)