#!/bin/bash

#define the directory containing your files
input_dir=$1
output_meta=$2

#create the header for the metafile
echo -e "#FASTQ_R1\tFASTQ_R2\toperative_name" > $output_meta

#list all files in the directory
for FASTQ_R1 in ${input_dir}/*R1.fastq.gz; do
    # Derive the corresponding PBMC_R2 file
    FASTQ_R2="${FASTQ_R1/_R1./_R2.}"

    # Derive the base name for the sample to find corresponding postTMZ files
    base_name=$(basename $FASTQ_R1 | cut -d '_' -f 1,2 )
    
        echo -e "$FASTQ_R1\t$FASTQ_R2\t$base_name" >> $output_meta
done
