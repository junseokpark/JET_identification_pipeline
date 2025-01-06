#!/bin/bash

# Default values for variables
JETProjectDir="/home/junseokpark/apps/JET_identification_pipeline"


samtoolsBinDir="/usr/local/bin"
starBinDir="/usr/local/bin"
readLength=100
organism="Human"
genome="hg38"
database="ensembl"
refDir="/mnt/nfs/ref/hg38"
fastaFile="Homo_sapiens_assembly38.fasta"
gtfGeneFile="gencode.v46.annotation.gtf"
threads=8

multiMetaFile="${JETProjectDir}/scripts/step1_mutiprocessing_list.txt"

# Read rnaSample and name from the metaFile
while IFS=',' read -r dataDir metadata; do
    

    dataDir="${dataDir}"
    metaFile="${dataDir}/${metadata}"

    # Derived variables from input variables
    outputsDir="$dataDir/output" # Path to the output results directory
    logDir="$dataDir/log"            # Path to the logs directory
    ErrorDir="$dataDir/err"        # Path to the error files directory
    mkdir -p ${logDir}
    logFile="${logDir}/step1_multisample_running_$(date +'%Y%m%d').log"

    # Example: rnaSample="5X", name="simreftetss270_5X"
    echo -e "\e[1m${dataDir}\t${metaFile}\e[0m" > "${logFile}"
    
    echo $JETProjectDir
    echo $dataDir
    echo $metaFile

    # Script execute
    executeCMD="${JETProjectDir}/Step1_pipelineJETs_STAR.sh \
        --samtools ${samtoolsBinDir} \
        --star ${starBinDir} \
        --read-length ${readLength} \
        --organism ${organism} \
        --genome ${genome} \
        --database ${database} \
        --ref-dir ${refDir} \
        --fasta ${fastaFile} \
        --gtf ${gtfGeneFile} \
        --threads ${threads} \
        --meta ${metaFile} \
        --data-dir ${dataDir} \
        --output ${outputsDir}

       "
    echo $executeCMD
    eval $executeCMD

done < "${multiMetaFile}"