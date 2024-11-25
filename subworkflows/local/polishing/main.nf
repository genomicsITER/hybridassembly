//
// Subworkflow with polishing functionality specific to the nf-core/hybridassembly pipeline
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { MINIMAP2_ALIGN as MINIMAP2_ALIGN_ROUND_1 } from '../../../modules/nf-core/minimap2/align/main'
include { RACON as RACON_ROUND_1                   } from '../../../modules/nf-core/racon/main'

include { MINIMAP2_ALIGN as MINIMAP2_ALIGN_ROUND_2 } from '../../../modules/nf-core/minimap2/align/main'
include { RACON as RACON_ROUND_2                   } from '../../../modules/nf-core/racon/main'

include { BWA_INDEX                                } from '../../../modules/nf-core/bwa/index/main'
include { BWA_MEM as BWA_ALIGN                     } from '../../../modules/nf-core/bwa/mem/main'
include { SAMTOOLS_INDEX as INDEX_BAM              } from '../../../modules/nf-core/samtools/index/main'
include { PICARD_SORTSAM                           } from '../../../modules/nf-core/picard/sortsam/main'
include { SAMTOOLS_INDEX as INDEX_SORTED_BAM       } from '../../../modules/nf-core/samtools/index/main'
include { PILON                                    } from '../../../modules/nf-core/pilon/main'

/*
========================================================================================
    SUBWORKFLOW TO POLISHING PIPELINE
========================================================================================
*/

workflow POLISHING_PIPELINE {

    take:
    short_reads
    long_reads
    initial_assembly

    main:

    ch_versions             = Channel.empty()

    ch_polishing_racon_1    = Channel.empty()
    ch_polishing_racon_2    = Channel.empty()
    ch_polishing_bam        = Channel.empty()
    ch_polishing_sorted_bam = Channel.empty()

    //
    // MODULE: First round of polishing with Racon
    //
    MINIMAP2_ALIGN_ROUND_1 (long_reads, initial_assembly, false, false, false)
    ch_versions = ch_versions.mix(MINIMAP2_ALIGN_ROUND_1.out.versions.first())

    ch_polishing_racon_1 = ch_polishing_racon_1
        .mix (long_reads)
        .join (initial_assembly)
        .join (MINIMAP2_ALIGN_ROUND_1.out.paf)

    RACON_ROUND_1 ( ch_polishing_racon_1 )
    ch_versions = ch_versions.mix(RACON_ROUND_1.out.versions.first())

    //
    // MODULE: Second round of polishing with Racon
    //
    MINIMAP2_ALIGN_ROUND_2 (long_reads, RACON_ROUND_1.out.improved_assembly, false, false, false)
    ch_versions = ch_versions.mix(MINIMAP2_ALIGN_ROUND_2.out.versions.first())

    ch_polishing_racon_2 = ch_polishing_racon_2
        .mix (long_reads)
        .join (RACON_ROUND_1.out.improved_assembly)
        .join (MINIMAP2_ALIGN_ROUND_2.out.paf)

    RACON_ROUND_2 ( ch_polishing_racon_2 )
    ch_versions = ch_versions.mix(RACON_ROUND_2.out.versions.first())

    //
    // MODULE: Final polishing step with Pilon
    //
    BWA_INDEX (RACON_ROUND_2.out.improved_assembly)
    ch_versions = ch_versions.mix(BWA_INDEX.out.versions.first())

    BWA_ALIGN (short_reads, BWA_INDEX.out.index, RACON_ROUND_2.out.improved_assembly, true)
    ch_versions = ch_versions.mix(BWA_ALIGN.out.versions.first())

    INDEX_BAM (BWA_ALIGN.out.bam)
    ch_versions = ch_versions.mix(INDEX_BAM.out.versions.first())

    ch_polishing_bam = ch_polishing_bam
        .mix (BWA_ALIGN.out.bam)
        .join (INDEX_BAM.out.bai)

    PICARD_SORTSAM (BWA_ALIGN.out.bam, params.picard_sort_order)
    ch_versions = ch_versions.mix(PICARD_SORTSAM.out.versions.first())

    INDEX_SORTED_BAM (PICARD_SORTSAM.out.bam)
    ch_versions = ch_versions.mix(INDEX_SORTED_BAM.out.versions.first())

    ch_polishing_sorted_bam = ch_polishing_sorted_bam
        .mix (PICARD_SORTSAM.out.bam)
        .join (INDEX_SORTED_BAM.out.bai)

    PILON (RACON_ROUND_2.out.improved_assembly, ch_polishing_sorted_bam, params.pilon_mode)
    ch_versions = ch_versions.mix(PILON.out.versions.first())

    emit:
    versions          = ch_versions
    polished_assembly = PILON.out.improved_assembly
}
