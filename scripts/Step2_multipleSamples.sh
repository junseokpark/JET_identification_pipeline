#!/bin/bash

# Default values for variables
JETProjectDir="/home/junseokpark/apps/JET_identification_pipeline"
starIndexesDir="$/mnt/nfs/ref/hg38/star/idx"
readLength="100"
organism="Human"
genome="hg38"
database="ensembl"
RlibDir="/usr/local/lib64/R/library"  # Default R library directory
repeatsFile="/home/junseokpark/apps/JET_identification_pipeline/refs/repeatmasker_reformat.txt"
gffFile="/mnt/nfs/ref/hg38/Homo_sapiens.GRCh38.113.gtf"
multiMetaFile="${JETProjectDir}/scripts/step2_mutiprocessing_list.txt"

# Read rnaSample and name from the metaFile
while IFS=',' read -r dataDir metadata; do
    

    dataDir="${dataDir}"
    metaFile="${dataDir}/${metadata}"

    # Derived variables from input variables
    outputsDir="$dataDir/output" # Path to the output results directory
    logDir="$dataDir/log"            # Path to the logs directory
    ErrorDir="$dataDir/err"        # Path to the error files directory
    mkdir -p ${logDir}
    logFile="${logDir}/step2_multisample_running_$(date +'%Y%m%d').log"

    # Example: rnaSample="5X", name="simreftetss270_5X"
    echo -e "\e[1m${dataDir}\t${metaFile}\e[0m" > "${logFile}"
    
    echo $JETProjectDir
    echo $dataDir
    echo $metaFile

    # Script execute
    executeCMD="${JETProjectDir}/Step2_pipelineJETs_R.sh --jetprojectdir ${JETProjectDir} \
        --data-dir ${dataDir} \
        --outputs-dir ${outputsDir} \
        --log-dir ${logDir} \
        --star-dir ${starIndexesDir} \
        --metadata ${metaFile} \
        --error-dir ${ErrorDir} \
        --read-length ${readLength} \
        --organism ${organism} \
        --genome ${genome} \
        --database ${database} \
        --rlib-dir ${RlibDir} \
        --repeats-file ${repeatsFile} \
        --gff-file ${gffFile} 
       "
    echo $executeCMD
    eval $executeCMD

done < "${multiMetaFile}"