//
// Subworkflow with assessment functionality specific to the nf-core/hybridassembly pipeline
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { QUAST                                    } from '../../../modules/nf-core/quast/main'

include { BUSCO_BUSCO as BUSCO                     } from '../../../modules/nf-core/busco/busco/main'

include { MERYL_COUNT                              } from '../../../modules/nf-core/meryl/count/main'
include { MERYL_UNIONSUM                           } from '../../../modules/nf-core/meryl/unionsum/main'
include { MERQURY_MERQURY as MERQURY               } from '../../../modules/nf-core/merqury/merqury/main'

/*
========================================================================================
    SUBWORKFLOW TO POLISHING PIPELINE
========================================================================================
*/

workflow ASSESSMENT_PIPELINE {

    take:
    short_reads
    curated_assembly
    reference

    main:
    ch_assembly_meryldb     = Channel.empty()
    ch_versions             = Channel.empty()
    ch_multiqc_files        = Channel.empty()

    //
    // MODULE: Run QUAST
    //
    QUAST ( curated_assembly, [ [:], reference ], [[:],[]] )
    ch_multiqc_files = ch_multiqc_files.mix( QUAST.out.results.collect{it[1]} )
    ch_versions = ch_versions.mix( QUAST.out.versions.first() )

    //
    // MODULE: Assembly evaluation with BUSCO
    //
    BUSCO ( curated_assembly, params.busco_mode, params.busco_lineage, [], [] )
    ch_multiqc_files = ch_multiqc_files.mix( BUSCO.out.short_summaries_txt.collect{it[1]} )
    ch_versions = ch_versions.mix( BUSCO.out.versions.first() )

    //
    // MODULE: Assembly evaluation with Merqury
    //
    MERYL_COUNT ( short_reads, params.meryl_kvalue )
    MERYL_UNIONSUM ( MERYL_COUNT.out.meryl_db, params.meryl_kvalue )

    ch_assembly_meryldb = MERYL_UNIONSUM.out.meryl_db.join( curated_assembly )
    MERQURY ( ch_assembly_meryldb )
    ch_versions = ch_versions.mix( MERQURY.out.versions.first() )

    emit:
    versions                 = ch_versions
    assessment_multiqc_files = ch_multiqc_files

}
