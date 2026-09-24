# ---- Peak calling and consensus set ------------------------------------------

rule macs2_callpeak:
    input:
        bam="results/dedup/{sample}.dedup.bam",
    output:
        summits="results/macs2/{sample}_summits.bed",
        narrowpeak="results/macs2/{sample}_peaks.narrowPeak",
    params:
        gsize=config["macs2"]["genome_size"],
        qvalue=config["macs2"]["qvalue"],
        extra=config["macs2"]["extra"],
        outdir="results/macs2",
    log:
        "logs/macs2/{sample}.log",
    threads: config["threads"]["macs2"]
    conda:
        "../envs/peaks.yaml"
    shell:
        r"""
        macs2 callpeak \
            -t {input.bam} \
            -f BAMPE \
            -g {params.gsize} \
            -q {params.qvalue} \
            {params.extra} \
            -n {wildcards.sample} \
            --outdir {params.outdir} > {log} 2>&1
        """


# Consensus peak set via the Corces & Granja (Science 2018) iterative-overlap
# method. Consumes every per-sample *_summits.bed in results/macs2/.
rule consensus_peaks:
    input:
        summits=expand("results/macs2/{sample}_summits.bed", sample=SAMPLES),
        blacklist=config["reference"]["blacklist"],
    output:
        bed="results/consensus/All_Samples.consensus_peaks.bed",
    params:
        macs2dir="results/macs2",
        outdir="results/consensus",
        genome="BSgenome.Hsapiens.UCSC.hg38",
        spm=config["consensus"]["spm"],
        rule=config["consensus"]["rule"],
        extend=config["consensus"]["extend"],
    log:
        "logs/consensus/consensus.log",
    conda:
        "../envs/consensus.yaml"
    shell:
        r"""
        Rscript workflow/scripts/createIterativeOverlapPeakSet.R \
            --macs2dir {params.macs2dir} \
            --suffix _summits.bed \
            --outdir {params.outdir} \
            --blacklist {input.blacklist} \
            --genome {params.genome} \
            --spm {params.spm} \
            --rule {params.rule} \
            --extend {params.extend} > {log} 2>&1
        # normalise the Corces output name to the pipeline target
        cp {params.outdir}/All_Samples.fwp.filter.non_overlapping.bed {output.bed}
        """


# Count reads in consensus peaks (featureCounts via a SAF built from the BED).
rule consensus_counts:
    input:
        bed="results/consensus/All_Samples.consensus_peaks.bed",
        bams=expand("results/dedup/{sample}.dedup.bam", sample=SAMPLES),
    output:
        counts="results/counts/consensus_counts.tsv",
    log:
        "logs/counts/featurecounts.log",
    threads: 8
    conda:
        "../envs/peaks.yaml"
    shell:
        r"""
        # BED -> SAF (GeneID, Chr, Start, End, Strand)
        awk 'BEGIN{{OFS="\t"; print "GeneID","Chr","Start","End","Strand"}}
             {{print $1"_"$2"_"$3, $1, $2+1, $3, "."}}' {input.bed} > results/counts/consensus.saf
        featureCounts -T {threads} -p --countReadPairs \
            -F SAF -a results/counts/consensus.saf \
            -o {output.counts} {input.bams} > {log} 2>&1
        """
