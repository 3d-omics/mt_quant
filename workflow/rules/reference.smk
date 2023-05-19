rule reference_set_dna:
    input:
        fa=features["host"]["dna"],
    output:
        fa=REFERENCE / "genome.fa",
    log:
        REFERENCE / "genome.log",
    conda:
        "../envs/empty.yml"
    shell:
        "pigz -dc {input.fa} > {output.fa} 2> {log}"


rule reference_set_gtf:
    input:
        gtf=features["host"]["gtf"],
    output:
        gtf=REFERENCE / "annotation.gtf",
    log:
        REFERENCE / "annotation.log",
    conda:
        "../envs/empty.yml"
    shell:
        "pigz -dc {input.gtf} > {output.gtf}"


rule reference:
    input:
        rules.reference_set_dna.output.fa,
        rules.reference_set_gtf.output.gtf,
