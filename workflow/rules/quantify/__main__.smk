include: "__functions__.smk"
include: "bowtie2.smk"
include: "coverm.smk"
include: "samtools.smk"


rule quantify:
    """
    Run the quantify steps:
    - bowtie2: Map to MAG catalogue
    - coverm: Get the count tables
    """
    input:
        rules.quantify__coverm.input,
