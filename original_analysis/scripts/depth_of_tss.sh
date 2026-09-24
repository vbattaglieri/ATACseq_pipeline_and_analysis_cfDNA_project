#!/bin/bash

# Usage: depth_of_tss.sh <TSS_positions.tsv> <sample.bam> [output.txt]
# TSS positions file: tab-separated "chr:start-end<TAB>gene_name" (e.g. RefSeq hg38 TSS +/-4000bp)
input_file="${1:?need TSS positions file}"
bam_file="${2:?need BAM file}"
output_file="${3:-output_with_depth.txt}"

while IFS=$'\t' read -r position gene_name; do
    
    # Use samtools depth to get the depth for the specified position
    depth=$(samtools depth -a -q 30 -r "$position" "$bam_file" | awk '{print $3}')

    # Print the original line along with the depth
    echo -e "${position}\t${depth}\t${gene_name}" >> "${output_file}"

done < "$input_file"

