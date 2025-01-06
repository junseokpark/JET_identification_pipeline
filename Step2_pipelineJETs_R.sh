#!/bin/bash

#### created by Alexandre Houy and Christel Goudot
#### modified and adapted by Ares Rocanin-Arjo
#### updated by Junseok Park (with Code Copilot)

#-------------------------------------------------------
##-- Configuration
#-------------------------------------------------------

################################################################################
##### Set variables
day=$(date +"%Y%m%d")
time=$(date +"%Hh%Mm%Ss")
date="${day}_${time}"

# Parsing command-line options
usage() {
    echo "Usage: $0 [options]"
    echo "  -j, --jetprojectdir   Path to JET pipeline directory (default: /usr/local/bin)"
    echo "  -d, --data-dir        Base directory for data (default: /mnt/data)"
    echo "  -o, --outputs-dir     Output results directory"
    echo "  -l, --log-dir         Logs directory"
    echo "  -s, --star-dir        Path to the STAR indexes directory"
    echo "  -m, --metadata        Path to the reference (genetic or repeat masker) directory"
    echo "  -e, --error-dir       Path to store error files"
    echo "  -rl, --read-length    Read length (default: 100)"
    echo "  -og, --organism       Organism (e.g., Human, Mouse) (default: Mouse)"
    echo "  -g, --genome          Genome (e.g., hg38, mm10) (default: mm10)"
    echo "  -db, --database       Database (default: ensembl)"
    echo "  --rlib-dir            Path to the R library directory (default: /usr/local/lib64/R/library)"
    echo "  --repeats-file        Path to the repeats file (default: /mnt/data/ref/hg38/hg38.RepeatMasker-4.0.6-Dfam-2.0.fa.out)"
    echo "  --gff-file            Path to the GFF file (default:/mnt/data/ref/hg38/Homo_sapiens.GRCh38.113.gtf)"
    echo "  --min-junction        Minimum junction size (default:2e7)"
    echo "  -h, --help            Display this help message and exit"
    exit 1
}

# Default values for variables
JETProjectDir="${JETProjectDir:-/home/junseokpark/apps/JET_identification_pipeline}"
dataDir="${dataDir:-/mnt/data/simul}"
starIndexesDir="${starIndexesDir:-/mnt/data/ref/hg38/star/idx}"
metadata="${metadata:-/mnt/data/simul/metadata_step2.txt}"
readLength="${readLength:-100}"
organism="${organism:-Human}"
genome="${genome:-hg38}"
database="${database:-ensembl}"
RlibDir="${RlibDir:-/usr/local/lib64/R/library}"  # Default R library directory
#repeatsFile="${repeatsFile:-/mnt/data/ref/hg38/repeatmasker_custom_output-4.0.6-Dfam-2.0.tsv}"  # Default repeats file
repeatsFile="${repeatsFile:-/home/junseokpark/apps/JET_identification_pipeline/refs/repeatmasker_reformat.txt}"
gffFile="${gffFile:-/mnt/data/ref/hg38/Homo_sapiens.GRCh38.113.gtf}"
minJunction="${minJunction:-2e7}"

# Parse command-line options and override defaults if specified
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -j|--jetprojectdir) JETProjectDir="$2"; shift ;;
        -d|--data-dir) dataDir="$2"; shift ;;
        -o|--outputs-dir) outputsDir="$2"; shift ;;
        -l|--log-dir) logDir="$2"; shift ;;
        -s|--star-dir) starIndexesDir="$2"; shift ;;
        -m|--metadata) metadata="$2"; shift ;;
        -e|--error-dir) ErrorDir="$2"; shift ;;
        -rl|--read-length) readLength="$2"; shift ;;
        -og|--organism) organism="$2"; shift ;;
        -g|--genome) genome="$2"; shift ;;
        -db|--database) database="$2"; shift ;;
        --rlib-dir) RlibDir="$2"; shift ;;
        --repeats-file) repeatsFile="$2"; shift ;;
        --gff-file) gffFile="$2"; shift ;;
        --min-junction) min-junction="$2"; shift ;; 
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
    shift
done

# Derived variables from input variables
outputsDir="${outputsDir:-$dataDir/output}" # Path to the output results directory
logDir="${logDir:-$dataDir/log}"            # Path to the logs directory
logFile="${logFile:-${logDir}/R_run_${date}.log}"
ErrorDir="${ErrorDir:-$dataDir/err}"        # Path to the error files directory

# Create necessary directories
mkdir -p "${logDir}"
mkdir -p "${outputsDir}"
mkdir -p "${ErrorDir}"
touch "${logFile}"

# Print the configured variables
echo "Configuration:"
echo "  JET Project Directory: ${JETProjectDir}"
echo "  Data Directory: ${dataDir}"
echo "  Outputs Directory: ${outputsDir}"
echo "  Log Directory: ${logDir}"
echo "  STAR Indexes Directory: ${starIndexesDir}"
echo "  Metadata Directory: ${metadata}"
echo "  Error Directory: ${ErrorDir}"
echo "  Read Length: ${readLength}"
echo "  Organism: ${organism}"
echo "  Genome: ${genome}"
echo "  Database: ${database}"
echo "  R Library Directory: ${RlibDir}"
echo "  Repeats File: ${repeatsFile}"
echo "  GFF File: ${gffFile}"

#-------------------------------------------------------
##-- STEP 2: Identification and classification of junctions, selection of JETs
#-------------------------------------------------------

echo -e "Starting R -----" >> ${logFile}

# Read rnaSample, name, and day from the metadata file
while IFS=',' read -r rnaSample name name_prefix day; do

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


    echo -e "\e[1m${rnaSample}\t${name}\e[0m" >> ${logFile}

    ############################################################################
    ##### Sample-specific Directories path
    #outputSampleDir="${outputsDir}/${name}_${day}"
    #mkdir -p "${outputSampleDir}"

    echo -e "\e[1m${name}\tCreating the outputFiles and setting tmpDIR\e[0m" >> ${logFile}

    ############################################################################
    ##### Calling sample-specific data files

    prefix="${outputSampleDir}/${name}"
    samFile="${prefix}_Chimeric.out.sam"
    bamFile="${prefix}_Aligned.sortedByCoord.out.bam"
    bamChimericFile="${prefix}_Chimeric.out.bam"
    bamChimericSortFile="${prefix}_Chimeric.out.sort.bam"
    chimericFile="${prefix}_Chimeric.out.junction"
    junctionFile="${prefix}_SJ.out.tab"
    logFinalOut="${prefix}_Log.final.out"

	# Print sample-specific data file paths
    echo "Sample-Specific Data Files for ${name}:"
    echo "  SAM File: $samFile"
    echo "  BAM File: $bamFile"
    echo "  BAM Chimeric File: $bamChimericFile"
    echo "  BAM Chimeric Sorted File: $bamChimericSortFile"
    echo "  Chimeric File: $chimericFile"
    echo "  Junction File: $junctionFile"
    echo "  STAR Log Final Output File: $logFinalOut"

    # Extract library size from STAR log
    libsize=$(grep "Uniquely mapped reads number" ${logFinalOut} | sed -r 's/[\\t]+//g' | cut -d '|' -f2)
    echo "Libsize: $libsize"

    echo -e "\e[1m${name}\tCalling and naming output files:\e[0m" >> ${logFile}
    echo -e "\e[1m${name}\t\tPrefix: ${prefix}\e[0m" >> ${logFile}
    echo -e "\e[1m${name}\t\tLibrary size: ${libsize}\e[0m" >> ${logFile}

    size=11

    ############################################################################
    ##### Naming sample-specific output files
    fastaFile="${prefix}_Fusions.annotatedchimJunc${minJunction}.size${size}.fasta"
    idsFile="${prefix}_Fusions.annotatedchimJunc${minJunction}.size${size}.ids.txt"
    netmhcpanFile4="${prefix}_Fusions.annotatedchimJunc${minJunction}.size${size}.netmhcpan4.0.txt"

    ############################################################################
    ##### R analysis

    cmd="Rscript ${JETProjectDir}/JET_analysis_filtered.R  \
        --chimeric ${chimericFile} \
        --junction ${junctionFile} \
        --genome ${genome} \
        --size ${size} \
        --libsize ${libsize} \
        --prefix ${prefix} \
        --verbose \
        --rscript_dir ${JETProjectDir} \
        --rlib_dir ${RlibDir} \
        --repeats_file ${repeatsFile} \
        --gff_file ${gffFile} \
        --min_junc ${minJunction} 
        "  # Pass the repeats file path

    {
        date=$(date +"%Y%m%d_%Hh%Mm%Ss")
        echo -e "${name}\tR_fusion_rna\t${cmd}\t${date}" >> ${logFile}

        echo "Starting command: ${cmd}"
        start_time=$(date +%s)

        # Run the command using eval and measure the time
        eval "time ${cmd}" 2>&1 | tee -a "${logFile}"

        end_time=$(date +%s)
        runtime=$((end_time - start_time))

        echo "Command finished. Processing time: ${runtime} seconds."



    } | tee -a "${logFile}"



done < ${metadata}

echo -e "END" >> ${logFile}