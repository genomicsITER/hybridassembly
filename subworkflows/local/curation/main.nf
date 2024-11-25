//
// Subworkflow with curation functionality specific to the nf-core/hybridassembly pipeline
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { MINIMAP2_ALIGN as MINIMAP2_PURGEDUPS     } from '../../../modules/nf-core/minimap2/align/main'
include { PURGEDUPS_PBCSTAT                        } from '../../../modules/nf-core/purgedups/pbcstat/main'
include { PURGEDUPS_CALCUTS                        } from '../../../modules/nf-core/purgedups/calcuts/main'
include { PURGEDUPS_SPLITFA                        } from '../../../modules/nf-core/purgedups/splitfa/main'
include { MINIMAP2_ALIGN as MINIMAP2_SPLITFA       } from '../../../modules/nf-core/minimap2/align/main'
include { PURGEDUPS_PURGEDUPS                      } from '../../../modules/nf-core/purgedups/purgedups/main'
include { PURGEDUPS_GETSEQS                        } from '../../../modules/nf-core/purgedups/getseqs/main'

include { RAGTAG_CORRECT                           } from '../../../modules/local/ragtag_correct'
include { RAGTAG_SCAFFOLD                          } from '../../../modules/local/ragtag_scaffold'

include { SEQTK_SEQ                                } from '../../../modules/nf-core/seqtk/seq/main'
include { TGS_GAPCLOSER                            } from '../../../modules/local/tgs_gapcloser'

/*
========================================================================================
    SUBWORKFLOW TO CURATION PIPELINE
========================================================================================
*/

workflow CURATION_PIPELINE {

    take:
    long_reads
    polished_assembly

    main:

    ch_versions             = Channel.empty()
    ch_purgedups_purgedups  = Channel.empty()
    ch_purgedups_getseqs    = Channel.empty()

    //
    // MODULE: Purge haplotigs and overlaps with purge_dups
    //
    MINIMAP2_PURGEDUPS ( long_reads, polished_assembly, false, false, false )
    ch_versions = ch_versions.mix( MINIMAP2_PURGEDUPS.out.versions.first() )

    PURGEDUPS_PBCSTAT ( MINIMAP2_PURGEDUPS.out.paf )

    PURGEDUPS_CALCUTS ( PURGEDUPS_PBCSTAT.out.stat )

    PURGEDUPS_SPLITFA ( polished_assembly )

    MINIMAP2_SPLITFA ( PURGEDUPS_SPLITFA.out.split_fasta, PURGEDUPS_SPLITFA.out.split_fasta, false, false, false )

    ch_purgedups_purgedups = ch_purgedups_purgedups
        .mix (PURGEDUPS_PBCSTAT.out.basecov)
        .join (PURGEDUPS_CALCUTS.out.cutoff)
        .join (MINIMAP2_SPLITFA.out.paf)

    PURGEDUPS_PURGEDUPS ( ch_purgedups_purgedups )

    ch_purgedups_getseqs = ch_purgedups_getseqs
        .mix (polished_assembly)
        .join (PURGEDUPS_PURGEDUPS.out.bed)

    PURGEDUPS_GETSEQS ( ch_purgedups_getseqs )
    ch_versions = ch_versions.mix( PURGEDUPS_GETSEQS.out.versions.first() )

    //
    // MODULE: Correction and scaffolding with RagTag
    //
    RAGTAG_CORRECT ( PURGEDUPS_GETSEQS.out.purged, [ [:], params.fasta ] )
    ch_versions = ch_versions.mix( RAGTAG_CORRECT.out.versions.first() )

    RAGTAG_SCAFFOLD ( RAGTAG_CORRECT.out.corrected_fasta, [ [:], params.fasta ] )
    ch_versions = ch_versions.mix( RAGTAG_CORRECT.out.versions.first() )

    //
    // MODULE: Close gaps with TGS-GapCloser
    //
    SEQTK_SEQ ( long_reads )
    ch_versions = ch_versions.mix( SEQTK_SEQ.out.versions.first() )

    TGS_GAPCLOSER ( RAGTAG_SCAFFOLD.out.scaffold_fasta, SEQTK_SEQ.out.fastx )
    ch_versions = ch_versions.mix( TGS_GAPCLOSER.out.versions.first() )

    emit:
    versions          = ch_versions
    polished_assembly = TGS_GAPCLOSER.out.scaffolds_gapfilled

}
