rule _preprocess__fastp__trim:
    """Run fastp on one library"""
    input:
        forward_=READS / "{sample_id}.{library_id}_1.fq.gz",
        reverse_=READS / "{sample_id}.{library_id}_2.fq.gz",
    output:
        forward_=FASTP / "{sample_id}.{library_id}_1.fq.gz",
        reverse_=FASTP / "{sample_id}.{library_id}_2.fq.gz",
        unpaired1=FASTP / "{sample_id}.{library_id}_u1.fq.gz",
        unpaired2=FASTP / "{sample_id}.{library_id}_u2.fq.gz",
        html=FASTP / "{sample_id}.{library_id}.html",
        json=FASTP / "{sample_id}.{library_id}_fastp.json",
    log:
        FASTP / "{sample_id}.{library_id}.log",
    params:
        adapter_forward=get_forward_adapter,
        adapter_reverse=get_reverse_adapter,
        extra=params["preprocess"]["fastp"]["extra"],
    threads: 24
    resources:
        mem_mb=4 * 1024,
        runtime=240,
    conda:
        "__environment__.yml"
    shell:
        """
        fastp \
            --in1 {input.forward_} \
            --in2 {input.reverse_} \
            --out1 {output.forward_} \
            --out2 {output.reverse_} \
            --unpaired1 {output.unpaired1} \
            --unpaired2 {output.unpaired2} \
            --html {output.html} \
            --json {output.json} \
            --verbose \
            --compression 9 \
            --adapter_sequence {params.adapter_forward} \
            --adapter_sequence_r2 {params.adapter_reverse} \
            --thread {threads} \
            {params.extra} \
        2> {log}
        """


rule preprocess__fastp__trim:
    """Run fastp over all libraries"""
    input:
        [
            FASTP / f"{sample_id}.{library_id}_{end}.fq.gz"
            for sample_id, library_id in SAMPLE_LIBRARY
            for end in "1 2 u1 u2".split(" ")
        ],


rule preprocess__fastp__fastqc:
    """Run fastqc over all libraries"""
    input:
        [
            FASTP / f"{sample_id}.{library_id}_{end}_fastqc.{extension}"
            for sample_id, library_id in SAMPLE_LIBRARY
            for end in ["1", "2"]
            for extension in ["html", "zip"]
        ],


rule preprocess__fastp__report:
    """Collect fastp and fastqc reports"""
    input:
        [
            FASTP / f"{sample_id}.{library_id}_fastp.json"
            for sample_id, library_id in SAMPLE_LIBRARY
        ],
        rules.preprocess__fastp__fastqc.input,


rule preprocess__fastp:
    """Run fastp and collect reports"""
    input:
        rules.preprocess__fastp__trim.input,
        rules.preprocess__fastp__report.input,
