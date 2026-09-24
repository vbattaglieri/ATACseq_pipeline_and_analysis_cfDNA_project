# ---- Read trimming (Trim Galore, with built-in FastQC) -----------------------

rule trim_galore:
    input:
        unpack(get_fastqs),
    output:
        r1="results/trimmed/{sample}_val_1.fq.gz",
        r2="results/trimmed/{sample}_val_2.fq.gz",
    log:
        "logs/trim_galore/{sample}.log",
    threads: config["threads"]["trim"]
    conda:
        "../envs/trim.yaml"
    shell:
        "trim_galore --phred33 --paired --fastqc --cores {threads} "
        "--basename {wildcards.sample} "
        "--output_dir results/trimmed {input.r1} {input.r2} > {log} 2>&1"
