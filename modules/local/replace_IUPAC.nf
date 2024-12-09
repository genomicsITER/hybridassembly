process REPLACE_IUPAC {
    tag "$meta.id"
    label 'process_high_memory_long'

    conda "conda-forge::python=3.12"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.12' :
        'biocontainers/python:3.12' }"

    input:
    tuple val(meta), path(fastq)

    output:
    tuple val(meta), path("*.fastq.gz"), emit: reads
    path "versions.yml",                 emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    replaceIUPAC.py $fastq > ${prefix}.fixed.fastq

    rm ${prefix}.fastq
    mv ${prefix}.fixed.fastq ${prefix}.fastq

    gzip -c ${prefix}.fastq > ${prefix}.fastq.gz
    rm ${prefix}.fastq

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
