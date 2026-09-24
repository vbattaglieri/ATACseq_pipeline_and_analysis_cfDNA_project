import pandas as pd
from snakemake.utils import validate

# ---- Load sample sheet -------------------------------------------------------
samples = (
    pd.read_csv(config["samples"], sep="\t", dtype=str)
    .set_index("sample", drop=False)
    .sort_index()
)

SAMPLES = samples["sample"].tolist()


def get_fastqs(wildcards):
    """Return the raw R1/R2 FASTQ paths for a sample."""
    row = samples.loc[wildcards.sample]
    return {"r1": row["fastq_1"], "r2": row["fastq_2"]}


def all_outputs():
    """Final targets requested by rule `all`."""
    targets = [
        "results/qc/multiqc_report.html",
        "results/consensus/All_Samples.consensus_peaks.bed",
        "results/counts/consensus_counts.tsv",
    ]
    targets += expand("results/tss/{sample}.tss_enrichment.txt", sample=SAMPLES)
    return targets
