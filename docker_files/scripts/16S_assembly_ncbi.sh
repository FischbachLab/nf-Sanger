#!/bin/bash -x
set -u
set -o pipefail

mygroup=${1:?"Specify a Group name"}

input_path=${2}

script_path="/work/scripts"

ab1_path="${input_path}/all_ab1_files/"
qc_path="${input_path}/qc_files"
full_qc_csv="${qc_path}/all_full_qc.csv"
primer_set="${script_path}/4primers"

# filter qc files

cd ${qc_path}

if [ -f $full_qc_csv ]; then
 rm  $full_qc_csv;
fi

for i in ${qc_path}/*.xls; do Rscript ${script_path}/split_qc.R $i && cat ${qc_path}/qc_full.csv >> $full_qc_csv; done

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

   mkdir -p "${mydir%_}_ncbi"
   out_path="${mydir%_}_ncbi_outputs"
    #mkdir -p "$out_path/Assemblies"

   echo "**************************************************"
   echo "${mydir%_}_ncbi"

  for i in $(cat ./${mygroup}_sample.list)
  do
   #   echo $i
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
      if [ -f ${mydir%_}/${i}.cons.fa ]; then
        cp "${mydir%_}/${i}.cons.fa" "${mydir%_}_ncbi"
      fi
      #docker container run --workdir $(pwd) -v $(pwd):$(pwd) geargenomics/tracy tracy assemble -t 9  -f 0.9 -o "${mydir%_}_ncbi"/$i $ab1_files
      #sleep 1
   done

cd "${mydir%_}_ncbi"
# Search
echo "Seaching NCBI 16S Database"
for i in *.cons.fa; do bash ${script_path}/run_blast_ncbi.sh $i; done
#Update query name
for i in *.cons.blastn.archive.outFmt_6.tsv; do sed -i "s/Consensus/${i%.cons.blastn.archive.outFmt_6.tsv}/" $i; done

if [ -f blast_outFmt_6.cmd ]; then
 rm  blast_outFmt_6.cmd
fi

# search top 3 taxonomic

for i in *.cons.blastn.archive.outFmt_6.tsv; do cut -f1,3,13,15,16 $i | head -n 3 | awk -F"\t" '{ print $1"\t"$5"\t"$2"\t"$3"\t"$4}' >  ${i%.cons.blastn.archive.outFmt_6.tsv}.top3hits.tsv; done

for i in *.cons.blastn.archive.outFmt_6.tsv; do head -n 3 $i | awk -F"\t" '{if(min==""){min=$13}; if($14<min) {min=$14}}  { print $1"\t"$16"\t"$3"\t"$15"\t"$13*100/$14"\t"($4-$5)*100/min}'  >  ${i%.cons.blastn.archive.outFmt_6.tsv}.filtered3hits.tsv; done

cat *.top3hits.tsv > all_samples_top3_ncbi.tsv
cat *.filtered3hits.tsv > all_samples_filtered3_ncbi.tsv

# calculate coverage
#for i in *.json; do python ${script_path}/calculate_coverage_sanger.py $i ${i%.json}; done
#concate all coverage stat
if [ -f samples.cov_stats.csv ]; then
 rm  samples.cov_stats.csv;
fi
#for i in *.cov_stats.csv; do cut -d',' -f1,3,4,6 ${i} | tail -n1 >> samples.cov_stats.csv; done
cp "../${mydir%_}/samples.cov_stats.csv" .

# grep selected primers only
primers=${mydir%_}
#primers=${primers//_/\\|}
echo $primers

IFS='_' read -ra line <<< "$primers"
if [ -f selected_qc_data.csv ]; then
 rm  selected_qc_data.csv
fi

for i in "${line[@]}"; do
    grep $i ${full_qc_csv} >> selected_qc_data.csv
done

# process the filtered qc data
Rscript ${script_path}/mean_score_qc.R selected_qc_data.csv

# generate summary table
Rscript ${script_path}/summary_ncbi.R

# copy files to the output folder
#cp 16S_summary.csv ../"$out_path/16S_ncbi_summary.csv"

cp 16S_ncbi_summary.csv ../"${mydir%_}_outputs/16S_ncbi_summary.csv"
#cp *.cons.fa  ../"$out_path/Assemblies"

cd -


done < ${primer_set}
