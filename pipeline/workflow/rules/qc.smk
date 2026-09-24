# ---- QC: signal tracks, TSS enrichment, aggregate report ---------------------

rule bam_coverage:
    input:
        bam="results/dedup/{sample}.dedup.bam",
    output:
        bw="results/tracks/{sample}.cpm.bw",
    log:
        "logs/bamcoverage/{sample}.log",
    threads: 8
    conda:
        "../envs/qc.yaml"
    shell:
        "bamCoverage --bam {input.bam} --outFileName {output.bw} "
        "--binSize 10 --normalizeUsing CPM --numberOfProcessors {threads} "
        "> {log} 2>&1"


# TSS enrichment: signal in a window centred on annotated TSS.
rule tss_enrichment:
    input:
        bw="results/tracks/{sample}.cpm.bw",
        tss=config["reference"]["tss_bed"],
    output:
        matrix="results/tss/{sample}.tss_matrix.gz",
        table="results/tss/{sample}.tss_enrichment.txt",
    log:
        "logs/tss/{sample}.log",
    threads: 8
    conda:
        "../envs/qc.yaml"
    shell:
        r"""
        computeMatrix reference-point \
            --referencePoint center \
            -S {input.bw} -R {input.tss} \
            -a 2000 -b 2000 --binSize 10 \
            --numberOfProcessors {threads} \
            -o {output.matrix} \
            --outFileNameMatrix {output.table} > {log} 2>&1
        """


rule multiqc:
    input:
        # QC inputs that should exist before aggregating
        expand("results/qc/dedup/{sample}.dup_metrics.txt", sample=SAMPLES),
        expand("results/macs2/{sample}_peaks.narrowPeak", sample=SAMPLES),
        expand("results/tss/{sample}.tss_enrichment.txt", sample=SAMPLES),
    output:
        html="results/qc/multiqc_report.html",
    log:
        "logs/multiqc/multiqc.log",
    conda:
        "../envs/qc.yaml"
    shell:
        "multiqc results/ logs/ -n multiqc_report.html "
        "-o results/qc --force > {log} 2>&1"
