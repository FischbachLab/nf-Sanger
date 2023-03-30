Sample batch command
====================

## This is a Sanger assembly & annotation pipeline for the Nextflow framework.

#### 1. Only 4 fixed primers which are allowed in the pipeline are "27F", "789F", "907R", "1492R"
#### 2. Sample names are detected automatically. (Only dash sign (-) is allowed in the assigned sample names)
#### 3. Three required parameters are assigned group name, order name by QuintaraBio and order id by QuintaraBio

```{bash}
aws batch submit-job \
  --job-name nf-sanger \
  --job-queue priority-maf-pipelines \
  --job-definition nextflow-production \
  --container-overrides command="FischbachLab/nf-sanger, \
"--group","20230309_TYs", \
"--name","20230309_TYs", \
"--order","835278", \
"--output_path", "s3://genomics-workflow-core/Results/Sanger" "
```

### The final summary file path:
```{bash}
s3://genomics-workflow-core/Results/Sanger/20230309_TYs/QB_RAW_DATA_by_group/20230309_TYs/789F_907R_27F_1492R_outputs/sanger_assembly_summary.csv
```
### The sanger assembly path:
```{bash}
s3://genomics-workflow-core/Results/Sanger/20230309_TYs/QB_RAW_DATA_by_group/20230309_TYs/789F_907R_27F_1492R_outputs/Assemblies/
```
