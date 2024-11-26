process TGS_GAPCLOSER {
    tag "$meta.id"
    label 'process_high_memory_long'

    conda "bioconda::tgsgapcloser=1.2.1-1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/tgsgapcloser:1.2.1--h5b5514e_1' :
        'biocontainers/tgsgapcloser:1.2.1--h5b5514e_1' }"

    input:
    tuple val(meta), path(scaffolds)
    tuple val(meta), path(reads_fasta)

    output:
    tuple val(meta), path("*.fasta")          , emit: scaffolds_gapfilled
    tuple val(meta), path("*.gap_fill_detail"), emit: gap_fill_details
    path "versions.yml"                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    tgsgapcloser $args --scaff $scaffolds --reads $reads_fasta --output tgsgapcloser

    mv tgsgapcloser*.scaff_seqs ${prefix}.fasta
    mv tgsgapcloser.gap_fill_detail ${prefix}.gap_fill_detail

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tgsgapcloser: \$( tgsgapcloser | grep "Version" | cut -d":" -f2 )
    END_VERSIONS
    """
}
