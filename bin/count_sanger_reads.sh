#!/bin/bash

set -euoE pipefail

file=${1:?"Specify an input file  as argv[1]"}
primer_set="/work/nextflow-bin/4primers"

sample=$(basename ${file} )
sample=${sample%.json}


while IFS=' ' read -r -a primer
do
  for ((idx=0; idx<${#primer[@]}; ++idx));
    do
      count=0
      #echo "${primer[idx]} ${#primer[@]} $idx"

      if  grep -q ${primer[idx]} $file
      then
	count=`egrep -c -e ${primer[idx]} $file`
        count=`echo "scale=0; $count/2" | bc -l`
      fi

      echo -e $sample"\t"${primer[idx]}"\t"$count
   done

done < ${primer_set}
