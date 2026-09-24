# ---- Optional host/graft (Xenome) filtering ----------------------------------
# Enabled via config["xenome"]["enabled"]. When off, alignment uses the
# Trim Galore output directly and mitochondrial reads are removed after mapping
# (see filtering.smk).

rule xenome_classify:
    input:
        r1="results/trimmed/{sample}_val_1.fq.gz",
        r2="results/trimmed/{sample}_val_2.fq.gz",
    output:
        r1="results/xenome/{sample}_graft_1.fastq.gz",
        r2="results/xenome/{sample}_graft_2.fastq.gz",
    params:
        binary=config["xenome"]["binary"],
        index=config["xenome"]["index"],
        graft=config["xenome"]["graft_prefix"],
        prefix=lambda w: f"results/xenome/{w.sample}",
    log:
        "logs/xenome/{sample}.log",
    threads: config["threads"]["align"]
    conda:
        "../envs/xenome.yaml"
    shell:
        r"""
        {params.binary} classify -T {threads} -M 24 -v \
            -P {params.index} --pairs \
            -i {input.r1} -i {input.r2} \
            --output-filename-prefix {params.prefix} > {log} 2>&1
        # re-compress the requested graft class
        gzip -c {params.prefix}_{params.graft}_1.fastq > {output.r1}
        gzip -c {params.prefix}_{params.graft}_2.fastq > {output.r2}
        """


def reads_for_alignment(wildcards):
    """Choose Xenome-filtered reads if enabled, else the trimmed reads."""
    if config["xenome"]["enabled"]:
        return {
            "r1": f"results/xenome/{wildcards.sample}_graft_1.fastq.gz",
            "r2": f"results/xenome/{wildcards.sample}_graft_2.fastq.gz",
        }
    return {
        "r1": f"results/trimmed/{wildcards.sample}_val_1.fq.gz",
        "r2": f"results/trimmed/{wildcards.sample}_val_2.fq.gz",
    }


# ---- Alignment (bwa-mem2) → coordinate-sorted BAM ----------------------------

rule bwa_mem2:
    input:
        unpack(reads_for_alignment),
    output:
        bam="results/aligned/{sample}.sorted.bam",
    params:
        index=config["reference"]["bwa_mem2_index"],
        rg=lambda w: rf"@RG\tID:{w.sample}\tSM:{w.sample}\tPL:ILLUMINA",
    log:
        "logs/bwa_mem2/{sample}.log",
    threads: config["threads"]["align"]
    conda:
        "../envs/align.yaml"
    shell:
        r"""
        bwa-mem2 mem -t {threads} -R '{params.rg}' \
            {params.index} {input.r1} {input.r2} 2> {log} \
          | samtools sort -@ {threads} -m 2G -o {output.bam} -
        samtools index -@ {threads} {output.bam}
        """
