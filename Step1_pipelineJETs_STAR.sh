#!/bin/bash

#### created by Alexandre Houy and Christel Goudot
#### modified and adapted by Ares Rocanin-Arjo
#### updated by Junseok Park (with Code Copilot)

#-------------------------------------------------------
##-- Configuration
#-------------------------------------------------------

################################################################################
##### Set variables
day=`date +"%Y%m%d"`
time=`date +"%Hh%Mm%Ss"`
date="${day}_${time}"


################################################################################
##### Configurate and set the following paths 

# Function to display usage information
usage() {
    echo "Usage: $0 [options]"
    echo "  -s, --samtools        Path to samtools binary directory (default: /usr/local/bin)"
    echo "  -r, --star            Path to STAR binary directory (default: /usr/local/bin)"
    echo "  -l, --read-length     Read length (default: 100)"
    echo "  -o, --organism        Organism (Human/Mouse) (default: Human)"
    echo "  -g, --genome          Genome (e.g., hg38, mm10) (default: hg38)"
    echo "  -d, --database        Database (e.g., ensembl) (default: ensembl)"
    echo "  -b, --data-dir        Base directory (default: /mnt/data/simul)"
	echo "  -e, --ref-dir         Path to the reference files (default: /mnt/data/ref/hg38)"
    echo "  -f, --fasta           Name of the reference FASTA file (default: Homo_sapiens_assembly38.fasta)"
    echo "  -t, --gtf             Name of the reference GTF file (default: gencode.v46.annotation.gtf.gz)"
    echo "  -m, --meta            Path to the metadata file (default: /mnt/data/simul/metadata.txt)"
    echo "  -d, --threads         Number of CPU threads (default: 8)"
    echo "  -p, --output          Output directory"
    echo "  -h, --help            Display this help message and exit"
    exit 1
}

# Default values

# Default values for variables following the example style
samtoolsBinDir="${samtoolsBinDir:-/usr/local/bin}"
starBinDir="${starBinDir:-/usr/local/bin}"
readLength="${readLength:-100}"
organism="${organism:-Human}"
genome="${genome:-hg38}"
database="${database:-ensembl}"
dataDir="${dataDir:-/mnt/nfs/sims/referenceTE/intron}"
refDir="${refDir:-/mnt/nfs/ref/hg38}"
fastaFile="${fastaFile:-Homo_sapiens_assembly38.fasta}"
gtfGeneFile="${gtfGeneFile:-gencode.v46.annotation.gtf}"
threads="${threads:-8}"

# Parsing command-line options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -s|--samtools) samtoolsBinDir="$2"; shift ;;
        -r|--star) starBinDir="$2"; shift ;;
        -l|--read-length) readLength="$2"; shift ;;
        -o|--organism) organism="$2"; shift ;;
        -g|--genome) genome="$2"; shift ;;
        -d|--database) database="$2"; shift ;;
        -b|--data-dir) dataDir="$2"; shift ;;
		-e|--ref-dir) refDir="$2"; shift ;;
        -f|--fasta) fastaFile="$2"; shift ;;
        -t|--gtf) gtfGeneFile="$2"; shift ;;
        -m|--meta) metaFile="$2"; shift ;;
        -d|--threads) threads="$2"; shift ;;
        -p|--output) outputsDir="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
    shift
done

# Ensure the default values are properly updated when using related variables
#metaFile="${dataDir}/metadata-fq.txt"
#outputsDir="${dataDir}/output"
metaFile="${metaFile:-${dataDir}/metadata-fq.txt}"
outputsDir="${outputsDir:-${dataDir}/output}"


# Derived variables
fastaFile="${refDir}/${fastaFile}"
gtfGeneFile="${refDir}/${gtfGeneFile}"
#outputsDir="$dataDir/output" # Path to the output results directory
logDir="$outputsDir/log"       # Path to the logs directory
starIndexesDir="$refDir/star/idx" # Path to the STAR indexes
ErrorDir="$dataDir/err"     # Path to the error files directory

# Create necessary directories
mkdir -p "${logDir}"
mkdir -p "${outputsDir}"
mkdir -p "${ErrorDir}"
mkdir -p "${starIndexesDir}"

# Setting up the log file
logFile="${logDir}/STARrun_$(date +'%Y%m%d').log"
touch "${logFile}"

# Display the configured paths and values
echo "Configuration:"
echo "  Samtools Directory: $samtoolsBinDir"
echo "  STAR Directory: $starBinDir"
echo "  Read Length: $readLength"
echo "  Organism: $organism"
echo "  Genome: $genome"
echo "  Database: $database"
echo "  Reference Directory: $refDir"
echo "  Data Directory: $dataDir"
echo "  Outputs Directory: $outputsDir"
echo "  Log Directory: $logDir"
echo "  Metadata File: $metaFile"
echo "  STAR Indexes Directory: $starIndexesDir"
echo "  Error Directory: $ErrorDir"
echo "  FASTA File: $fastaFile"
echo "  GTF File: $gtfGeneFile"
echo "  Log File: $logFile"

#-------------------------------------------------------
##-- STEP 0: STAR pre-indexing
#-------------------------------------------------------
################################################################################
##### Pre-processing reference 

if [ -d "$starIndexesDir" ] && [ "$(ls -A "$starIndexesDir")" ]; then
    echo "STAR index already exists in $starIndexesDir. Proceeding to the next job."
    # Call the next job or function here
else
    echo "No STAR index found in $starIndexesDir. You may need to create it."
    # Call the STAR index creation command or function here

    cmd="${starBinDir}/STAR \
	--runThreadN ${threads} \
	--runMode genomeGenerate \
	--genomeDir ${starIndexesDir} \
	--genomeFastaFiles ${fastaFile} \
	--sjdbGTFfile ${gtfGeneFile} \
	--sjdbOverhang ${readLength}"

    {
        echo "Starting command: ${cmd}"
        start_time=$(date +%s)

        # Run the command using eval and measure the time
        eval "time ${cmd}" 2>&1 | tee -a "${logFile}"

        end_time=$(date +%s)
        runtime=$((end_time - start_time))

        echo "Command finished. Processing time: ${runtime} seconds."

    } | tee -a "${logFile}"
fi


#eval "time ${cmd}"


#-------------------------------------------------------
##-- STEP 1: STAR alignment
#-------------------------------------------------------


# Read rnaSample and name from the metaFile
while IFS=',' read -r rnaSample name name_prefix temp_day; do
    # Example: rnaSample="5X", name="simreftetss270_5X"
    echo -e "\e[1m${rnaSample}\t${name}\e[0m" >> "${logFile}"

    echo "${rnaSample}"
    echo "${name}"
    echo "${name_prefix}"

    ############################################################################
    ##### Sample-specific Directories and Temporary Paths

    if [ ! -z "${name_prefix}" ]; then 
        outputSampleDir="${outputsDir}/${name_prefix}_${name}_${day}"
    else
        outputSampleDir="${outputsDir}/${name}_${day}"
    fi
    mkdir -p "${outputSampleDir}"

    # Temporary directory for STAR files
    tmpDir="${outputsDir}/tmp"
    mkdir -p $tmpDir
    echo -e "\e[1m${rnaSample}\tCreating the output directory and setting tmpDir\e[0m" >> "${logFile}"


    ############################################################################
    ##### Defining Paths for Sample-Specific Data and Output Files

    # Paths to sample FASTQ files
    fastqR1Filegz="${dataDir}/${rnaSample}/${name}.1.fq.gz"
    fastqR2Filegz="${dataDir}/${rnaSample}/${name}.2.fq.gz"
    fastqR1File="${dataDir}/${rnaSample}/${name}.1.fq"
    fastqR2File="${dataDir}/${rnaSample}/${name}.2.fq"

    # Print the paths to the FASTQ files
    echo "fastqR1Filegz: ${fastqR1Filegz}"
    echo "fastqR2Filegz: ${fastqR2Filegz}"
    echo "fastqR1File: ${fastqR1File}"
    echo "fastqR2File: ${fastqR2File}"

    echo -e "\e[1m${rnaSample}\tReading FASTQ files: ${fastqR1File} and ${fastqR2File}\e[0m" >> "${logFile}"

    # Prefix for naming output files
    prefix="${outputSampleDir}/${name}"

    # Print the prefix
    echo "prefix: ${prefix}"

    # Output files
    samFile="${prefix}_Chimeric.out.sam"
    bamFile="${prefix}_Aligned.sortedByCoord.out.bam"
    bamChimericFile="${prefix}_Chimeric.out.bam"
    bamChimericSortFile="${prefix}_Chimeric.out.sort.bam"
    chimericFile="${prefix}_Chimeric.out.junction"
    junctionFile="${prefix}_SJ.out.tab"

    # Print all output file variables
    echo "samFile: ${samFile}"
    echo "bamFile: ${bamFile}"
    echo "bamChimericFile: ${bamChimericFile}"
    echo "bamChimericSortFile: ${bamChimericSortFile}"
    echo "chimericFile: ${chimericFile}"
    echo "junctionFile: ${junctionFile}"

    echo -e "\e[1m${rnaSample}\tNaming output files:\e[0m" >> "${logFile}"
    echo -e "\e[1m${rnaSample}\t\tPrefix: ${prefix}\e[0m" >> "${logFile}"

    ############################################################################
    ##### Check if FASTQ Files Exist and Decompress if Necessary

    flag=false

    # Decompress FASTQ files if needed
    if [ ! -f "${fastqR1File}" ] && [ -f "${fastqR1Filegz}" ]; then
        gunzip -c "${fastqR1Filegz}" > "${fastqR1File}"
    fi
    if [ ! -f "${fastqR2File}" ] && [ -f "${fastqR2Filegz}" ]; then
        gunzip -c "${fastqR2Filegz}" > "${fastqR2File}"
    fi

    # Print decompression status
    echo "Decompression status for ${rnaSample}:"
    echo "fastqR1File: ${fastqR1File}, exists: $(test -f "${fastqR1File}" && echo 'yes' || echo 'no')"
    echo "fastqR2File: ${fastqR2File}, exists: $(test -f "${fastqR2File}" && echo 'yes' || echo 'no')"

    # Check if the decompressed or gzipped FASTQ files exist
    if [ ! -f "${fastqR1File}" ] && [ ! -f "${fastqR1Filegz}" ]; then
        echo "${fastqR1File} not found!" 1>&2
        fastqR1File="NA"
        flag=true
    fi
    if [ ! -f "${fastqR2File}" ] && [ ! -f "${fastqR2Filegz}" ]; then
        echo "${fastqR2File} not found!" 1>&2
        fastqR2File="NA"
        flag=true
    fi

    # Skip to the next sample if any file is missing
    if ${flag}; then
        continue
    fi

    # Skip to the next sample if any file is missing
    if ${flag}; then
        continue
    fi

    echo -e "${name}\t${fastqR1File}\t${fastqR2File}" >> "${logFile}"

    cmd="${starBinDir}/STAR \
				--quantMode GeneCounts \
				--twopassMode Basic \
				--runThreadN ${threads} \
				--genomeDir ${starIndexesDir} \
				--sjdbGTFfile ${gtfGeneFile} \
				--sjdbOverhang 100 \
				--readFilesIn ${fastqR1File} ${fastqR2File} \
				--outFileNamePrefix ${prefix}_ \
				--outTmpDir ${tmpDir}/STAR_${name}_${date} \
				--outReadsUnmapped Fastx \
				--outSAMtype BAM SortedByCoordinate \
				--bamRemoveDuplicatesType UniqueIdentical \
				--outFilterMismatchNoverLmax 0.04 \
				--outMultimapperOrder Random \
				--outFilterMultimapNmax 1000 \
				--winAnchorMultimapNmax 1000 \
				--chimOutType WithinBAM SoftClip \
				--chimSegmentMin 12 \
				--chimJunctionOverhangMin 10 ; \
			${samtoolsBinDir}/samtools view -@ ${threads} -b ${samFile} > ${bamChimericFile} ; \
			${samtoolsBinDir}/samtools sort -@ ${threads} -o ${bamChimericSortFile} -O bam ${bamChimericFile} ; \
			${samtoolsBinDir}/samtools index ${bamChimericSortFile} ; \
			${samtoolsBinDir}/samtools index ${bamFile}"


    {
        echo -e "${name}\tStar_rna:\t${starcmd}\t${date}" >> ${logFile}
        echo "Starting command: ${cmd}"
        start_time=$(date +%s)

        # Run the command using eval and measure the time
        eval "time ${cmd}" 2>&1 | tee -a "${logFile}"

        end_time=$(date +%s)
        runtime=$((end_time - start_time))

        echo "Command finished. Processing time: ${runtime} seconds."

    } | tee -a "${logFile}"

done < "${metaFile}"