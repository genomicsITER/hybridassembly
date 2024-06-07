process RATATOSK {
    tag "$meta.id"
    label 'process_high_memory_long'

    conda "bioconda::ratatosk=0.9.0-0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ratatosk:0.9.0--hdcf5f25_0' :
        'biocontainers/ratatosk:0.9.0--hdcf5f25_0' }"

    input:
    tuple val(meta), path(shortreads), path(longreads)

    output:
    tuple val(meta), path("*.fastq"), emit: reads
    tuple val(meta), path("*.log")     , emit: log
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo $shortreads | sed 's/ /\\n/g' > short_read_list
    echo $longreads > long_read_list

    Ratatosk correct -v $args -s short_read_list -l long_read_list -o ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ratatosk: \$( Ratatosk --version )
    END_VERSIONS
    """
}
