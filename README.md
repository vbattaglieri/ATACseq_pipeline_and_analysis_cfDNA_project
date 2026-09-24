# ATAC-seq pipeline — cfDNA project (HCT116 WT vs DKO)

A modular, reproducible **[Snakemake](https://snakemake.readthedocs.io)** workflow
for chromatin-accessibility (ATAC-seq) analysis. This is the pipeline used for the
ATAC-seq analysis in the cfDNA project, centred on **HCT116 wild-type (WT)** vs its
**DNMT1/DNMT3B double-knockout (DKO)** derivative (plus additional cell-line and
T-cell samples).

> Part of a published project. If you use this pipeline, please cite:
> Pessei, V., Macagno, M., Mariella, E. et al. *DNA demethylation triggers cell
> free DNA release in colorectal cancer cells.* Genome Med 16, 118 (2024).
> https://doi.org/10.1186/s13073-024-01386-5

## Workflow

```
FASTQ
  │  Trim Galore (adapter/quality trimming + FastQC)
  ▼
 [optional] Xenome  ── host/graft separation for xenograft samples
  │
  ▼  bwa-mem2  → GRCh38 (hg38)
sorted BAM
  │  samtools  → keep properly-paired, MAPQ-filtered reads
  │  samtools  → remove mitochondrial (chrM) reads      ← default
  │  Picard    → remove PCR duplicates
  ▼
analysis-ready BAM
  │  MACS2 (BAMPE)  → per-sample peaks
  ▼
consensus peak set  ← Corces & Granja iterative-overlap method (R)
  │
  ├─ featureCounts  → counts matrix over consensus peaks
  └─ QC: TSS enrichment (deepTools), fragment-size, MultiQC
```

## Layout

```
.
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

The differential-accessibility step (WT vs DKO) is run downstream in R on
`results/counts/consensus_counts.tsv` (e.g. DESeq2 / edgeR).

## Data availability

Raw and processed sequencing data are deposited in the European Nucleotide
Archive (ENA) under accession codes
[PRJEB33045](https://www.ebi.ac.uk/ena/browser/view/PRJEB33045),
[PRJEB33640](https://www.ebi.ac.uk/ena/browser/view/PRJEB33640), and
[PRJEB57691](https://www.ebi.ac.uk/ena/browser/view/PRJEB57691) — not tracked in
git. Reference/genome files must be obtained from their original sources.

## License

Code released under the [MIT License](LICENSE). The consensus-peak R script
(`workflow/scripts/createIterativeOverlapPeakSet.R`) is adapted from
Corces & Granja et al. (Science 2018) — please cite that work.
