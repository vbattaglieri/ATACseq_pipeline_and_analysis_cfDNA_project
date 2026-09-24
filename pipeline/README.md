# ATAC-seq Snakemake pipeline

A modular, reproducible ATAC-seq workflow: **FASTQ → trimming → (optional
Xenome) → bwa-mem2 → filtering → chrM removal → dedup → MACS2 → Corces
consensus peaks → counts + QC**.

## Layout

```
pipeline/
├── config/
│   ├── config.yaml         # reference paths + parameters
│   └── samples.tsv         # sample sheet (sample, fastq_1, fastq_2, condition)
├── workflow/
│   ├── Snakefile           # entry point
│   ├── rules/
│   │   ├── common.smk      # sample sheet parsing + targets
│   │   ├── trimming.smk    # Trim Galore + FastQC
│   │   ├── mapping.smk     # optional Xenome + bwa-mem2
│   │   ├── filtering.smk   # proper-pair/MAPQ, chrM removal, Picard dedup
│   │   ├── peaks.smk       # MACS2, consensus peaks, featureCounts
│   │   └── qc.smk          # bigWig, TSS enrichment, MultiQC
│   ├── envs/               # per-rule conda environments (pinned)
│   └── scripts/
│       └── createIterativeOverlapPeakSet.R   # Corces consensus method
└── profiles/
    └── slurm/config.yaml   # SLURM executor profile
```

## Requirements

- [Snakemake](https://snakemake.readthedocs.io) ≥ 8 and conda/mamba.
- For SLURM: `snakemake-executor-plugin-slurm`.
- All bioinformatics tools are provisioned automatically per-rule via
  `--use-conda` (bwa-mem2, samtools, Picard, MACS2, bedtools, subread,
  deepTools, MultiQC, R/Bioconductor, and optionally Xenome).

## Setup

1. **References** — edit `config/config.yaml`:
   - `bwa_mem2_index`: build with `bwa-mem2 index genome.fa` (prefix path).
   - `blacklist`: [ENCODE hg38 blacklist](https://github.com/Boyle-Lab/Blacklist).
   - `tss_bed`: MANE/RefSeq TSS BED for the TSS-enrichment QC.
   - `chrom_sizes`: hg38 chrom sizes.
2. **Samples** — list your FASTQs in `config/samples.tsv` (tab-separated).
3. **(Optional) Xenome** — for xenograft samples, set `xenome.enabled: true` and
   point `binary`/`index` at your Xenome install and host/mito index. When off,
   mitochondrial reads are removed post-alignment via samtools.

## Run

```bash
# dry run (shows the DAG of jobs without executing)
snakemake -n --use-conda

# local execution
snakemake --cores 16 --use-conda

# SLURM cluster
snakemake --profile profiles/slurm --use-conda
```

## Outputs

```
results/
├── trimmed/        # Trim Galore FASTQs
├── aligned/        # sorted BAMs (bwa-mem2)
├── dedup/          # analysis-ready, deduplicated BAMs (+ .bai)
├── macs2/          # per-sample peaks (narrowPeak, summits)
├── consensus/      # All_Samples.consensus_peaks.bed
├── counts/         # consensus_counts.tsv (featureCounts matrix)
├── tracks/         # CPM-normalised bigWig signal tracks
├── tss/            # per-sample TSS-enrichment matrices
└── qc/             # MultiQC report + dedup metrics
```

The differential-accessibility step (WT vs DKO) is intentionally left to a
downstream R analysis on `results/counts/consensus_counts.tsv` (e.g. DESeq2 /
edgeR), mirroring the structure of the RNA-seq project.

## Notes & caveats

- This pipeline is derived from the original analysis scripts in
  [`../original_analysis/`](../original_analysis/) and is provided as a
  reproducible blueprint; validate references and parameters against your own
  data before production use.
- The `idea` BWA wrapper used in the original scripts is IFOM-internal and has
  been replaced here with standard `bwa-mem2`.
- The consensus-peak R script is adapted from Corces & Granja et al.
  (Science 2018) — please cite that work.
