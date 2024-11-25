process RAGTAG_SCAFFOLD {
    tag "$meta.id"
    label 'process_high_memory_long'

    conda "bioconda::ragtag=2.1.0-0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ragtag:2.1.0--pyhb7b1952_0' :
        'biocontainers/ragtag:2.1.0--pyhb7b1952_0' }"

    input:
    tuple val(meta), path(fasta)
    tuple val(meta2), path(reference)

    output:
    tuple val(meta), path("*.fasta"), emit: scaffold_fasta
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    ragtag.py scaffold -o . $reference $fasta

    mv ragtag.scaffold.fasta ${prefix}.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ragtag_scaffold: \$( ragtag.py --version )
    END_VERSIONS
    """
}