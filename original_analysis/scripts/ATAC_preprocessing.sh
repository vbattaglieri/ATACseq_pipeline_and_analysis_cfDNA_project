#!/usr/bin/env bash 

set -o posix
set -e

echo -e "\n\n\t=====> Analysis ATAC -- Preprocessing and Peak Calling <=====\n\n" >&2

if [ $# -ne 3 ]; then
                echo "===============================================================" >&2
                echo -e "\n$0\n\nNecessarie 3 Variabili:\nFastq_R1\nFastq_R2\nSample_Name" >&2
                echo "===============================================================" >&2
                exit 1
        fi


echo "--> Load Variables and Paths" >&2

FASTQ_R1=$1
FASTQ_R2=$2
SAMPLENAME=$3

# ---- User configuration: edit these paths / env names for your environment ----
CONDA_BASE="${CONDA_BASE:-$HOME/miniconda3}"   # miniconda install root
REF_DIR="${REF_DIR:-/path/to/references}"      # ATAC references (indexes, blacklist, etc.)
TOOLS_DIR="${TOOLS_DIR:-/path/to/tools}"       # local tool installs (idea, xenome, picard jar)

idea_exe="${TOOLS_DIR}/idea-py3_IFOM/libexec/idea"          # IFOM-internal BWA wrapper
idea_conf="${TOOLS_DIR}/idea-py3_IFOM/hg38_complete.conf"
xenome="${TOOLS_DIR}/xenome-1.0.1-r/xenome"
trim_galore="${CONDA_BASE}/envs/ATAC_1/bin/trim_galore"
hg38_mito="${REF_DIR}/xenome_hg38_mito/hg38_mito"           # Xenome host/mito index
#macs2="${CONDA_BASE}/envs/ATAC_1/bin/macs2"

###

echo -e "--> Controllo Variabili Analisi\n" >&2

echo -e "FASTQ_R1:\t$FASTQ_R1\nFASTQ_R2:\t$FASTQ_R2\nNome:\t$SAMPLENAME" >&2
echo -e "Idea_exe\t$idea_exe" >&2
echo -e "Idea Conf\t$idea_conf" >&2
echo -e "Xenome\t$xenome" >&2
echo -e "Hg38 mito\t$hg38_mito" >&2
echo -e "macs2\t$macs2" >&2
echo -e "trim_galore\t$trim_galore\n\n" >&2

###

echo "--> Activate conda env ATAC_1" >&2

source ${CONDA_BASE}/bin/activate ATAC_1

echo "--> Read Trimming" >&2

$trim_galore --phred33 --paired  --basename "$SAMPLENAME" --cores 3 $FASTQ_R1 $FASTQ_R2 

echo "--> Filtering mitochondrial reads" >&2

$xenome classify -T 40 -M 24 -v -l err_Xenome_xeno_"$SAMPLENAME" -P $hg38_mito --pairs -i "$SAMPLENAME"_val_1.fq.gz  -i "$SAMPLENAME"_val_2.fq.gz  --output-filename-prefix "$SAMPLENAME" > "$SAMPLENAME".stat  

awk '{if(NR%4==1) print "@"$1,$2;else if(NR%4==3) print "+";else print}' "$SAMPLENAME"_graft_1.fastq | gzip > "$SAMPLENAME"_noMT_R1.trimmed.fastq.gz &

pid1=$!

awk '{if(NR%4==1) print "@"$1,$2;else if(NR%4==3) print "+";else print}' "$SAMPLENAME"_graft_2.fastq | gzip > "$SAMPLENAME"_noMT_R2.trimmed.fastq.gz &

pid2=$!

wait $pid1
wait $pid2

echo "--> Activate conda env idea_slurm" >&2

source ${CONDA_BASE}/bin/activate idea_slurm

echo "--> Mapping reads to hg38" >&2

$idea_exe map -1 "$SAMPLENAME"_noMT_R1.trimmed.fastq.gz -2 "$SAMPLENAME"_noMT_R2.trimmed.fastq.gz -C $idea_conf -B -s "$SAMPLENAME" -t 40 -m 4G

echo "--> Filter properly-paired reads" >&2

samtools view -f2 -q 10 -b -@ 20 -o "$SAMPLENAME".BWA.hg38.sorted.properly_paired.bam "$SAMPLENAME".BWA.hg38.sorted.bam

echo "--> Activate conda env for Picard 3.0" >&2

source ${CONDA_BASE}/bin/activate Picard

echo "--> Filter for duplicated reads"

java -jar "${TOOLS_DIR}/picard_3.0.jar" MarkDuplicates \
	I="$SAMPLENAME".BWA.hg38.sorted.properly_paired.bam \
	O="$SAMPLENAME".BWA.hg38.sorted.properly_paired.dedup.bam \
	M="$SAMPLENAME"_dup_metrics.txt \
	VALIDATION_STRINGENCY=LENIENT \
	REMOVE_DUPLICATES=true


exit
