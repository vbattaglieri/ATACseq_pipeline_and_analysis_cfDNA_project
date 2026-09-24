# ---- Post-alignment filtering ------------------------------------------------
# 1. keep properly-paired, good-MAPQ reads  (samtools -f2 -q <min_mapq>)
# 2. remove mitochondrial reads (default: chrM)
# 3. mark & remove PCR duplicates (Picard)

rule filter_proper_pairs:
    input:
        bam="results/aligned/{sample}.sorted.bam",
    output:
        bam=temp("results/filtered/{sample}.pp.bam"),
    params:
        mapq=config["filter"]["min_mapq"],
    log:
        "logs/filter/{sample}.pp.log",
    threads: 8
    conda:
        "../envs/align.yaml"
    shell:
        "samtools view -f2 -q {params.mapq} -b -@ {threads} "
        "-o {output.bam} {input.bam} 2> {log}"


rule remove_mito:
    input:
        bam="results/filtered/{sample}.pp.bam",
    output:
        bam=temp("results/filtered/{sample}.noMT.bam"),
    params:
        mito=config["mito_contig"],
    log:
        "logs/filter/{sample}.noMT.log",
    threads: 8
    conda:
        "../envs/align.yaml"
    shell:
        r"""
        samtools index {input.bam}
        # keep every reference contig except the mitochondrial one
        chroms=$(samtools idxstats {input.bam} | cut -f1 | grep -vw '{params.mito}' | grep -v '\*')
        samtools view -b -@ {threads} {input.bam} $chroms > {output.bam} 2> {log}
        """


rule mark_duplicates:
    input:
        bam="results/filtered/{sample}.noMT.bam",
    output:
        bam="results/dedup/{sample}.dedup.bam",
        metrics="results/qc/dedup/{sample}.dup_metrics.txt",
    log:
        "logs/markdup/{sample}.log",
    threads: 4
    conda:
        "../envs/align.yaml"
    shell:
        r"""
        picard MarkDuplicates \
            I={input.bam} \
            O={output.bam} \
            M={output.metrics} \
            VALIDATION_STRINGENCY=LENIENT \
            REMOVE_DUPLICATES=true > {log} 2>&1
        samtools index {output.bam}
        """
