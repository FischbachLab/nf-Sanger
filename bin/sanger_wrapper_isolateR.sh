#!/bin/bash -x

set -e
set -u
set -o pipefail

LOCAL=$(pwd)
START_TIME=$SECONDS
#export PATH="/opt/conda/bin:${PATH}"

# s3 inputs from env variables
#group="${1}" Assigned group name
#NAME="${2}"  QuintaraBio Name
#ORDER="${3}" order id
#S3OUTPUTPATH="${4}"


# Setup directory structure
OUTPUTDIR=${LOCAL}/tmp_$( date +"%Y%m%d_%H%M%S" )
RAW_DATA="${OUTPUTDIR}/raw_data"

LOCAL_OUTPUT="${OUTPUTDIR}/Sync"
LOG_DIR="${LOCAL_OUTPUT}/Logs"


mkdir -p "${OUTPUTDIR}" "${LOCAL_OUTPUT}" "${LOG_DIR}" "${RAW_DATA}"

trap '{ rm -rf ${OUTPUTDIR} ; exit 255; }' 1

# get data
echo "Downloading Sanger files" 
aws s3 sync ${S3INPUTPATH}/${NAME}/ ${RAW_DATA}/QB_RAW_DATA_Compressed/${NAME}/

mkdir -p ${LOCAL_OUTPUT}/QB_RAW_DATA_by_group/${group}/all_ab1_files
mkdir -p ${LOCAL_OUTPUT}/QB_RAW_DATA_by_group/${group}/qc_files


ORDER=($ORDER)
# for i in ${ORDER[@]}
for ((idx=0; idx<${#ORDER[@]}; ++idx));
do
  echo ${ORDER[idx]}
  cd ${RAW_DATA}/QB_RAW_DATA_Compressed/${NAME}/${ORDER[idx]}/
  #cp *_autoqc.xls ${LOCAL_OUTPUT}/QB_RAW_DATA_by_group/${group}/qc_files
  
  if [ ls "*.crdownload" 1>/dev/null 2>&1 ]; then
    rm  "*.crdownload"
  fi

  # each order id
  ids=`ls *.zip`
  echo ${ids[@]}
  for i in ${ids[@]};
  do               
    echo $i 
    PARENT=$(pwd);
    
    dirname=`echo "$i" | cut -f 2,3 -d_ | cut -f1 -d.`
    echo $dirname
    unzip "$i"
    cp  $dirname/*.ab1 ${LOCAL_OUTPUT}/QB_RAW_DATA_by_group/${group}/all_ab1_files   
  done
done

# update file names
cd ${LOCAL_OUTPUT}/QB_RAW_DATA_by_group/${group}/all_ab1_files
for i in *.ab1; do mv $i ${i%_202*}.ab1; done
cd -

#group=${1:?"Enter group name as argv[1]"}

export R_HOME="$(which R)"
echo $R_HOME

#ls -l /work/scripts/
#ls -l ${LOCAL_OUTPUT}/QB_RAW_DATA_by_group/${group}
#ls -l ${LOCAL_OUTPUT}/QB_RAW_DATA_by_group/${group}/all_ab1_files/

isolateR.R ${LOCAL_OUTPUT}/QB_RAW_DATA_by_group/${group}/all_ab1_files 2> ${LOG_DIR}/$group.log 


######################### HOUSEKEEPING #############################
DURATION=$((SECONDS - START_TIME))
hrs=$(( DURATION/3600 )); mins=$(( (DURATION-hrs*3600)/60)); secs=$(( DURATION-hrs*3600-mins*60 ))
printf 'This AWSome pipeline took: %02d:%02d:%02d\n' $hrs $mins $secs > ${LOCAL_OUTPUT}/job.complete
echo "Live long and prosper" >> ${LOCAL_OUTPUT}/job.complete
############################ PEACE! ################################
## Sync output
aws s3 sync "${LOCAL_OUTPUT}/QB_RAW_DATA_by_group/${group}/all_ab1_files/isolateR_output/" "${S3OUTPUTPATH}/Sanger_outputs/"
aws s3 sync "${LOG_DIR}" "${S3OUTPUTPATH}/Logs/"
aws s3 cp "${LOCAL_OUTPUT}/job.complete" "${S3OUTPUTPATH}/job.complete"
