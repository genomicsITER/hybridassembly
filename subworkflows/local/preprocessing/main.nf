//
// Subworkflow with preprocessing functionality specific to the nf-core/hybridassembly pipeline
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FASTQC                                   } from '../../../modules/nf-core/fastqc/main'
include { NANOPLOT as NANOPLOT_RAW                 } from '../../../modules/nf-core/nanoplot/main'

include { FILTLONG                                 } from '../../../modules/nf-core/filtlong/main'
include { NANOPLOT as NANOPLOT_FILT                } from '../../../modules/nf-core/nanoplot/main'

include { RATATOSK                                 } from '../../../modules/local/ratatosk'
include { REPLACE_IUPAC                            } from '../../../modules/local/replace_IUPAC'
include { NANOPLOT as NANOPLOT_CORR                } from '../../../modules/nf-core/nanoplot/main'

/*
========================================================================================
    SUBWORKFLOW TO POLISHING PIPELINE
========================================================================================
*/

workflow PREPROCESSING_PIPELINE {

    take:
    short_reads
    long_reads
    maskedshort_long

    main:
    ch_versions             = Channel.empty()
    ch_multiqc_files        = Channel.empty()

    ch_short_longfiltered   = Channel.empty()
    ch_short_longcorrected  = Channel.empty()

    //
    // MODULE: Run FastQC
    //
    FASTQC ( short_reads )
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())

    //
    // MODULE: Run NanoPlot
    //
    NANOPLOT_RAW ( long_reads )
    ch_versions = ch_versions.mix(NANOPLOT_RAW.out.versions.first())

    //
    // MODULE: Run FiltLong
    //
    FILTLONG ( maskedshort_long )
    ch_versions = ch_versions.mix(FILTLONG.out.versions.first())

    ch_short_longfiltered = short_reads.join(FILTLONG.out.reads)

    //
    // MODULE: Run NanoPlot on filtered reads
    //
    NANOPLOT_FILT ( FILTLONG.out.reads )
    ch_versions = ch_versions.mix( NANOPLOT_FILT.out.versions.first() )

    //
    // MODULE: Run Ratatosk on filtered reads (local module)
    //
    RATATOSK ( ch_short_longfiltered )
    ch_versions = ch_versions.mix( RATATOSK.out.versions.first() )

    //
    // MODULE: Replace IUPAC characters from corrected reads
    //
    REPLACE_IUPAC ( RATATOSK.out.reads )
    ch_versions = ch_versions.mix( REPLACE_IUPAC.out.versions.first() )

    ch_short_longcorrected = short_reads.mix( REPLACE_IUPAC.out.reads )

    //
    // MODULE: Run NanoPlot on filtered reads
    //
    NANOPLOT_CORR ( REPLACE_IUPAC.out.reads )
    ch_versions = ch_versions.mix( NANOPLOT_CORR.out.versions.first() )

    // Collect files for MultiQC
    ch_multiqc_files = ch_multiqc_files.mix( FASTQC.out.zip.collect{it[1]} )
    ch_multiqc_files = ch_multiqc_files.mix( NANOPLOT_RAW.out.txt.collect{it[1]} )
    ch_multiqc_files = ch_multiqc_files.mix( FILTLONG.out.log.collect{it[1]} )
    ch_multiqc_files = ch_multiqc_files.mix( NANOPLOT_FILT.out.txt.collect{it[1]} )
    ch_multiqc_files = ch_multiqc_files.mix( NANOPLOT_CORR.out.txt.collect{it[1]} )

    emit:
    versions                    = ch_versions
    corrected_long_reads        = REPLACE_IUPAC.out.reads
    preprocessing_multiqc_files = ch_multiqc_files
}
