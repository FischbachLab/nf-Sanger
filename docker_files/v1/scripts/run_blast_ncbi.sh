#!/bin/bash -x
# shellcheck disable=SC2086
set -e
set -u
set -o pipefail

TASK=${TASK:-"blastn"}
QUERY_EXT=${QUERY_EXT:-".fa"}
THREADS=${THREADS:-12}

QUERY_PATH=${1}

LOCAL_DB=${2:-"/mnt/efs/databases/Blast/16S_ribosomal_RNA/16S_ribosomal_RNA"}
#LOCAL_DB=${2:-"/mnt/efs/scratch/Xmeng/BLAST/blastdb/16S_ribosomal_RNA"}
# filtered Silva NR
#/home/ec2-user/efs/docker/Xmeng/16S/Sanger/silva_db_filtered/Filtered_SILVA_138.1_SSURef_NR99_tax_silva.fasta"
#/home/ec2-user/efs/docker/Xmeng/BLAST/blastdb/SILVA_138.1_SSURef_tax_silva.fasta"}  # /home/ec2-user/efs/docker/PacBio/Assemblies/BLAST/UHGGdb/extended_db/UHGG_isolates_ext"}
RESULTS_PATH=$(echo "${QUERY_PATH}" | sed -e "s/queries/results/" -e "s/${QUERY_EXT}/.${TASK}.archive/")

# BASE_PATH="/home/ec2-user/efs/docker/PacBio/Assemblies/BLAST/UHGGdb"
# LOCAL_DB="${BASE_PATH}/db/UHGG_isolates"
# LOCAL_DB="${BASE_PATH}/extended_db/UHGG_isolates_ext"
BASE_PATH=$(pwd)
LOCAL_QUERY_FASTA="${BASE_PATH}/${QUERY_PATH}"
LOCAL_RESULT_FILE="${BASE_PATH}/${RESULTS_PATH}"

LOCAL_DB_DIR="$(dirname ${LOCAL_DB})"
DBNAME="$(basename ${LOCAL_DB})"

LOCAL_QUERY_DIR="$(dirname ${LOCAL_QUERY_FASTA})"
QUERY_FILE_NAME="$(basename ${LOCAL_QUERY_FASTA})"

LOCAL_RESULTS_DIR="$(dirname ${LOCAL_RESULT_FILE})"
RESULTS_FILE_NAME="$(basename ${LOCAL_RESULT_FILE})"

mkdir -p ${LOCAL_RESULTS_DIR}

DOCKER_DB_DIR="/blast/blastdb_custom"
DOCKER_QUERIES_DIR="/blast/queries"
DOCKER_RESULTS_DIR="/blast/results"


        ${TASK} \
            -num_threads ${THREADS} \
            -query ${LOCAL_QUERY_DIR}/${QUERY_FILE_NAME} \
            -out ${LOCAL_RESULTS_DIR}/${RESULTS_FILE_NAME} \
            -db ${LOCAL_DB_DIR}/${DBNAME} \
            -outfmt 11 \
            -dbsize 1000000 \
            -num_alignments 20


        blast_formatter \
            -archive ${LOCAL_RESULTS_DIR}/${RESULTS_FILE_NAME} \
            -outfmt '6 std qlen slen qcovs sscinames' \
            -out ${LOCAL_RESULTS_DIR}/${RESULTS_FILE_NAME}.outFmt_6.tsv
