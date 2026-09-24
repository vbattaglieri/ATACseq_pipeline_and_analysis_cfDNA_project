## Il file di reference per TSS e' MANE TSS, si chiama clean perche ho tolto chromosomi extra e alternativi (MANE.GRCh38.v1.3_selected_TSS_sites_clean)
## Creo file CHIAVE per Right Flank
## awk 'BEGIN{OFS=FS="\t"}{print $1,$2,$2+100,$4}' MANE.GRCh38.v1.3_selected_TSS_sites_clean | awk '{for (i=$2; i<=$3; i++) print $1"\t"i"\t"$4}' > right_flank_key.txt
## Creo file CHIAVE per Left Flank
## awk 'BEGIN{OFS=FS="\t"}{print $1,$3-100,$3,$4}' MANE.GRCh38.v1.3_selected_TSS_sites_clean | awk '{for (i=$2; i<=$3; i++) print $1"\t"i"\t"$4}'  > left_flank_key.txt
## Creo file CHIAVE per center (1800bp)
## awk 'BEGIN{FS=OFS="\t"}{print $1,$2+100,$3-100,$4}' MANE.GRCh38.v1.3_selected_TSS_sites_clean |  awk '{for (i=$2; i<=$3; i++) print $1"\t"i"\t"$4}' > center_key.txt
## Creo file per le conte di Samtools per Right Flank (faccio -1 per avere la stessa posizione di partenza)
## awk 'BEGIN{OFS=FS="\t"}{print $1,$2-1,$2+100}' MANE.GRCh38.v1.3_selected_TSS_sites_clean > right_flank_BED_samtools.txt
## Creo file per le conte di Samtools per Left Flank (faccio -101 per avere la stessa posizione di partenza)
## awk 'BEGIN{OFS=FS="\t"}{print $1,$3-101,$3}' MANE.GRCh38.v1.3_selected_TSS_sites_clean > left_flank_BED_samtools.txt
## Creo file per le conte di Samtools per Left Flank (faccio -101 per avere la stessa posizione di partenza)
## awk 'BEGIN{FS=OFS="\t"}{print $1,$2+99,$3-100}' MANE.GRCh38.v1.3_selected_TSS_sites_clean > center_BED_samtools.txt


## Calcolo le depth per Right,Left flanks e center

samtools depth -a -b right_flank_BED_samtools.txt -o Right_flank_depth.txt ../HCC2998.BWA.hg38.sorted.properly_paired.dedup.bam

samtools depth -a -b left_flank_BED_samtools.txt -o Left_flank_depth.txt ../HCC2998.BWA.hg38.sorted.properly_paired.dedup.bam

samtools depth -a -b center_BED_samtools.txt -o Center_depth.txt ../HCC2998.BWA.hg38.sorted.properly_paired.dedup.bam

## Join la depth file con la CHIAVE

join -1 1 -2 1  <(awk '{print $1"_"$2,$3}' Right_flank_depth.txt | sort -k1,1) <(awk '{print $1"_"$2,$3}' right_flank_key.txt | sort -k1,1 ) > depth_right

join -1 1 -2 1  <(awk '{print $1"_"$2,$3}' Left_flank_depth.txt | sort -k1,1) <(awk '{print $1"_"$2,$3}' left_flank_key.txt | sort -k1,1 ) > depth_left

join -1 1 -2 1  <(awk '{print $1"_"$2,$3}' Center_depth.txt | sort -k1,1) <(awk '{print $1"_"$2,$3}' center_key.txt | sort -k1,1 ) | awk 'BEGIN{OFS="\t"}{print $3,$1,$2}' > tmp3

#Calcolo la flank value per ogni TSS

cat depth* | sort -k1,1 | awk 'BEGIN{OFS="\t"}{print $1,$3}' | datamash -g 1 mean 2 > flank_value_TSS




