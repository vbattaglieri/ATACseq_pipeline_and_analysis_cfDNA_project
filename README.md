# ATAC-seq analysis for cfDNA project (HCT116 WT vs DKO)

Chromatin-accessibility (ATAC-seq) analysis for a colorectal-cancer cfDNA study,
centred on **HCT116 wild-type (WT)** vs its **DNMT1/DNMT3B double-knockout (DKO)**
derivative.

This repository is organised in **two parts**:

| Folder | What it is |
|--------|------------|
| [`original_analysis/`](original_analysis/) | The **actual scripts** used for the published analysis |
| [`pipeline/`](pipeline/) | A **productized, reproducible reimplementation** in [Snakemake](https://snakemake.readthedocs.io) — modular rules, per-step conda environments, a SLURM profile, and a samplesheet-driven interface. |

> Part of a published project. If you use or refer to this code, please cite the
> associated publication *Pessei, V., Macagno, M., Mariella, E. et al. DNA demethylation triggers cell free DNA release in colorectal cancer cells. Genome Med 16, 118 (2024). https://doi.org/10.1186/s13073-024-01386-5*.

## Overview of the workflow

```
FASTQ
  │  Trim Galore (adapter/quality trimming)
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

## `original_analysis/` — what was actually run

- `scripts/ATAC_preprocessing.sh` — end-to-end preprocessing (Trim Galore →
  Xenome mito/host filtering → BWA mapping → proper-pair filter → Picard dedup).
- `scripts/createIterativeOverlapPeakSet.R` — consensus peak set, adapted from
  **Corces & Granja et al., Science 2018** (attribution retained in the header).
- `scripts/TSS_score.sh`, `scripts/depth_of_tss.sh` — TSS-enrichment scoring
  (samtools depth over flank/center windows; MANE / RefSeq TSS references).
- `scripts/create_metadata_FASTQ.sh` — builds the R1/R2/sample metadata sheet.
- `scripts/python_helpers/` — small pandas/stdlib utilities (peak-value
  correlation, median/min-max summarisation, methylation-probe filtering).
- `results/` — selected QC figures (TSS enrichment, fragment-size and
  insert-size distributions, replicate correlation).

## `pipeline/` — reproducible Snakemake workflow

See [`pipeline/README.md`](pipeline/README.md) for full usage. Quick version:

```bash
cd pipeline
# 1. edit config/config.yaml (reference paths) and config/samples.tsv (your FASTQs)
# 2. dry-run
snakemake -n --use-conda
# 3. run locally
snakemake --cores 16 --use-conda
# 4. or on a SLURM cluster
snakemake --profile profiles/slurm --use-conda
```

Key design choices (vs. the original scripts):
- **chrM removal by default**; **Xenome** host/graft filtering is optional
  (`xenome.enabled` in the config) for xenograft samples.
- **Per-rule conda environments** and pinned tool versions for reproducibility.

## Reference & data notes

- Genome: **GRCh38 / hg38**. Build the `bwa-mem2` index and obtain the
  [ENCODE blacklist](https://github.com/Boyle-Lab/Blacklist) and a TSS BED
  (MANE / RefSeq) before running.
- Raw and processed sequencing data are deposited and available in the European Nucleotide Archive (ENA) with PRJEB33045 (https://www.ebi.ac.uk/ena/browser/view/PRJEB33045), PRJEB33640 (https://www.ebi.ac.uk/ena/browser/view/PRJEB33640), and PRJEB57691 (https://www.ebi.ac.uk/ena/browser/view/PRJEB57691) accession codes.

## License

Code released under the [MIT License](LICENSE). The consensus-peak R script is
adapted from Corces & Granja et al. (Science 2018) — please cite that work.
