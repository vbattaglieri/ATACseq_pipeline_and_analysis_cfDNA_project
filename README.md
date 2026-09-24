# ATAC-seq analysis — cfDNA project (HCT116 WT vs DKO)

Chromatin-accessibility (ATAC-seq) analysis for a colorectal-cancer cfDNA study,
centred on **HCT116 wild-type (WT)** vs its **DNMT1/DNMT3B double-knockout (DKO)**
derivative, with additional cell-line and T-cell samples used for characterization.

This repository is organised in **two parts**:

| Folder | What it is |
|--------|------------|
| [`original_analysis/`](original_analysis/) | The **actual scripts** used for the published analysis — bash/R/Python, cleaned and with machine-specific paths genericized. Shows the real, exploratory workflow. |
| [`pipeline/`](pipeline/) | A **productized, reproducible reimplementation** in [Snakemake](https://snakemake.readthedocs.io) — modular rules, per-step conda environments, a SLURM profile, and a samplesheet-driven interface. Shows how I'd engineer the same analysis for reuse. |

> Part of a published project. If you use or refer to this code, please cite the
> associated publication *(add citation / DOI here)*.

## Workflow at a glance

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
- **bwa-mem2** replaces the IFOM-internal `idea` BWA wrapper → runnable anywhere.
- **chrM removal by default**; **Xenome** host/graft filtering is optional
  (`xenome.enabled` in the config) for xenograft samples.
- **Samplesheet-driven** (`config/samples.tsv`) instead of positional arguments.
- **Per-rule conda environments** and pinned tool versions for reproducibility.

## Reference & data notes

- Genome: **GRCh38 / hg38**. Build the `bwa-mem2` index and obtain the
  [ENCODE blacklist](https://github.com/Boyle-Lab/Blacklist) and a TSS BED
  (MANE / RefSeq) before running.
- Raw/processed sequencing data are deposited in a public repository
  *(add GEO/SRA accession here)* — not tracked in git.

## License

Code released under the [MIT License](LICENSE). The consensus-peak R script is
adapted from Corces & Granja et al. (Science 2018) — please cite that work.
