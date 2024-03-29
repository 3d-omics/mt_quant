rule _quantify__bowtie2__build:
    """Build bowtie2 index for the mags"""
    input:
        reference=MAGS / "{mag_catalogue}.fa.gz",
        fai=MAGS / "{mag_catalogue}.fa.gz.fai",
    output:
        prefix=touch(BOWTIE2_INDEX / "{mag_catalogue}"),
    log:
        BOWTIE2_INDEX / "{mag_catalogue}.log",
    conda:
        "__environment__.yml"
    params:
        extra=params["quantify"]["bowtie2"]["extra"],
    threads: 24
    resources:
        mem_mb=double_ram(32),
        runtime=6 * 60,
    retries: 5
    shell:
        """
        bowtie2-build \
            --threads {threads} \
            {params.extra} \
            {input.reference} \
            {output.prefix} \
        2> {log} 1>&2
        """


rule quantify__bowtie2__build:
    """Build all the bowtie2 indexes"""
    input:
        [BOWTIE2_INDEX / f"{mag_catalogue}" for mag_catalogue in MAG_CATALOGUES],


rule _quantify__bowtie2__map:
    """Map one library to reference genome using bowtie2

    Output SAM file is piped to samtools sort to generate a CRAM file.
    """
    input:
        forward_=get_forward_for_bowtie2,
        reverse_=get_reverse_for_bowtie2,
        bowtie2_index=BOWTIE2_INDEX / "{mag_catalogue}",
        reference=MAGS / "{mag_catalogue}.fa.gz",
        fai=MAGS / "{mag_catalogue}.fa.gz.fai",
    output:
        cram=BOWTIE2 / "{mag_catalogue}.{sample_id}.{library_id}.cram",
        crai=BOWTIE2 / "{mag_catalogue}.{sample_id}.{library_id}.cram.crai",
    log:
        BOWTIE2 / "{mag_catalogue}.{sample_id}.{library_id}.log",
    params:
        extra=params["quantify"]["bowtie2"]["extra"],
        samtools_mem=params["quantify"]["bowtie2"]["samtools"]["mem_per_thread"],
        rg_id=compose_rg_id,
        rg_extra=compose_rg_extra,
    threads: 24
    conda:
        "__environment__.yml"
    resources:
        mem_mb=double_ram(32),
        runtime=1440,
    shell:
        """
        ( bowtie2 \
            -x {input.bowtie2_index} \
            -1 {input.forward_} \
            -2 {input.reverse_} \
            --threads {threads} \
            --rg-id '{params.rg_id}' \
            --rg '{params.rg_extra}' \
            {params.extra} \
        | samtools sort \
            -l 9 \
            -M \
            -m {params.samtools_mem} \
            -o {output.cram} \
            --reference {input.reference} \
            --threads {threads} \
            --write-index \
        ) 2> {log} 1>&2
        """


rule quantify__bowtie2__map:
    """Collect the results of `bowtie2_map_one` for all libraries"""
    input:
        [
            BOWTIE2 / f"{mag_catalogue}.{sample_id}.{library_id}.cram"
            for sample_id, library_id in SAMPLE_LIBRARY
            for mag_catalogue in MAG_CATALOGUES
        ],


rule quantify__bowtie2__report:
    """Generate bowtie2 reports for all libraries:
    - samtools stats
    - samtools flagstats
    - samtools idxstats
    """
    input:
        [
            BOWTIE2 / f"{mag_catalogue}.{sample_id}.{library_id}.{report}"
            for sample_id, library_id in SAMPLE_LIBRARY
            for report in BAM_REPORTS
            for mag_catalogue in MAG_CATALOGUES
        ],


rule quantify__bowtie2:
    """Run bowtie2 on all libraries and generate reports"""
    input:
        rules.quantify__bowtie2__map.input,
        rules.quantify__bowtie2__report.input,
