#!/bin/bash -x
set -u
set -o pipefail

# assemble Sanger 16S reads
#docker container run --rm --workdir $(pwd) -v $(pwd):$(pwd) geargenomics/tracy tracy assemble -t 9 -p 0.9 -f 0.9 -o prefix *.ab1

#for i in *.xls; do Rscript /mnt/efs/scratch/Xmeng/16S/Sanger/sanger_scripts/split_qc.R $i && cat qc_full.csv >> all_full_qc.csv; done

mygroup=${1:?"Specify a Group name"}

input_path=${2}

script_path="/work/nextflow-bin"

ab1_path="${input_path}/all_ab1_files/"
qc_path="${input_path}/qc_files"
full_qc_csv="${qc_path}/all_full_qc.csv"
primer_set="${script_path}/4primers"

# filter qc files

cd ${qc_path}

if [ -f $full_qc_csv ]; then
 rm  $full_qc_csv;
fi

for i in ${qc_path}/*.xls; do split_qc.R $i && cat ${qc_path}/qc_full.csv >> $full_qc_csv; done

cd ${input_path}

mycpu=`grep -c ^processor /proc/cpuinfo`

echo "The number of CPU is $mycpu"

# get the sample list
ls ${ab1_path} | cut -d"_" -f 1 | sort | uniq > ${mygroup}_sample.list

while IFS=' ' read -r -a primer
do
 #echo "${primer[0]}"
 #primer+=("28F")
 #primer+=("1492R")

  mydir=""
  for ((idx=0; idx<${#primer[@]}; ++idx));
  do
      mydir+="${primer[idx]}_"
  done

  mkdir -p ${mydir%_}
  out_path="${mydir%_}_outputs"
  mkdir -p "$out_path/Assemblies"

  echo "**************************************************"
  echo ${mydir%_}

  for i in $(cat ./${mygroup}_sample.list)
  do
      echo $i
      ab1_files=""
      for ((idx=0; idx<${#primer[@]}; ++idx));
      do
        PFILE="${ab1_path}${i}_${primer[idx]}*"
	      if ls $PFILE 1> /dev/null 2>&1; then
          #files=$(ls ${ab1_path}${i}_${primer[idx]}* 2> /dev/null | wc -l)
          #if [ **"$files" != "0"** ]; then
          ab1_files+="${ab1_path}${i}"
          #echo "$i"
          ab1_files+="_${primer[idx]}* "
          #echo "$ab1_files"
        fi
      done
      echo "tracy assemble -t 9  -f 0.9 -o ${mydir%_}/$i $ab1_files"
      tracy assemble -t 9  -f 0.9 -o ${mydir%_}/$i $ab1_files || true
      #docker container run --workdir $(pwd) -v $(pwd):$(pwd) geargenomics/tracy tracy assemble -t 9  -f 0.9 -o ${mydir%_}/$i $ab1_files
      sleep 1
  done

  cd ${mydir%_}
  # Search
  echo "Seaching Silva Database"
  for i in *.cons.fa; do bash ${script_path}/run_blast_silva.sh $i; done
  #Update query name
  for i in *.cons.blastn.archive.outFmt_6.tsv; do sed -i "s/Consensus/${i%.cons.blastn.archive.outFmt_6.tsv}/" $i; done


  # create sample -> assembled seqeunce table
  if [ -f all.cons.csv ]; then
  rm  all.cons.csv
  fi

  for i in *.cons.fa; do
      echo -en "${i%.cons.fa}," >> all.cons.csv
      tail -n 1 $i >>  all.cons.csv
  done

  if [ -f blast_outFmt_6.cmd ]; then
  rm  blast_outFmt_6.cmd
  fi

  # search top 3 taxonomic
  for i in *.cons.blastn.archive.outFmt_6.tsv;
  do
    python ${script_path}/silva_blast_filter.py $i  ${i%.cons.blastn.archive.outFmt_6.tsv}
  #echo "python ${script_path}/silva_blast_filter.py $i  ${i%.cons.blastn.archive.outFmt_6.tsv}" >> blast_outFmt_6.cmd;
  done
  #cat blast_outFmt_6.cmd | parallel  -j ${mycpu} "{}"

  cat *.top3hits.tsv > all_samples_top3.tsv
  cat *.filtered3hits.tsv > all_samples_filtered3.tsv

  # calculate coverage
  for i in *.json; do python ${script_path}/calculate_coverage_sanger.py $i ${i%.json}; done
  #concate all coverage stat
  if [ -f samples.cov_stats.csv ]; then
  rm  samples.cov_stats.csv;
  fi
  for i in *.cov_stats.csv; do cut -d',' -f1,3,4,6 ${i} | tail -n1 >> samples.cov_stats.csv; done

  # Count primers actually used in each assembly
  if [ -f all_samples_primer_counts.tsv ]; then
  rm  all_samples_primer_counts.tsv;
  fi

  for i in *.json; do count_sanger_reads.sh $i >> all_samples_primer_counts.tsv; done

  # grep selected primers only
  primers=${mydir%_}
  #primers=${primers//_/\\|}
  echo $primers

  IFS='_' read -ra line <<< "$primers"
  if [ -f selected_qc_data.csv ]; then
  rm  selected_qc_data.csv
  fi

  for i in "${line[@]}"; do
      grep  $i ${full_qc_csv} >> selected_qc_data.csv
  done

  # process the filtered qc data
  mean_score_qc.R selected_qc_data.csv

  # generate summary table
  summary_silva.R

  # combine 2 summary files + sanger read count file
  #Rscript ${script_path}/sanger_assembly_summary.R

  # copy files to the output folder
  cp 16S_silva_summary.csv ../$out_path/"16S_silva_summary.csv"
  cp all_samples_primer_counts.tsv ../$out_path/
  cp all.cons.csv ../$out_path/
  cp *.cons.fa  ../$out_path/"Assemblies"

  cd -


done < ${primer_set}
