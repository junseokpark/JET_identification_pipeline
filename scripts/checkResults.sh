#!/bin/bash

# Get the current working directory
#base_dir=$(pwd)

#TE_TYPES=("AluY" "L1HS" "LTR5" "SVA_F")

#base_dir="/mnt/nfs/sims/nonReferenceTE"
base_dir="/mnt/nfs/sims/referenceTE/TSS"

TE_TYPES=("")

#for TE_TYPE in "${TE_TYPES[@]}"; do

    temp_base_dir="${base_dir}/output"
    # Iterate through all subdirectories in the base directory

    echo $temp_base_dir
    for dir in "$temp_base_dir"/*/; do
        # Check if any file matching *_Log.final.out exists in the directory
        if ! ls "$dir"*_Log.final.out >/dev/null 2>&1; then
            # If no such file exists, print the directory path
            #echo "Missing file in: $dir"
            dir_name=$(basename "$dir")


            # Extract the first string before "_" and the last string after "_"
            first_part=$(echo "$dir_name" | awk -F"_" '{print $1}')
            last_part=$(echo "$dir_name" | awk -F"_" '{print $NF}')

            # Remove the first and last parts from the directory name
            middle_part=$(echo "$dir_name" | sed -E "s/^${first_part}_//; s/_${last_part}$//")



            echo "${first_part}/fq,${middle_part},${first_part},${last_part}"
        fi
    done

#done