/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { PREPROCESSING_PIPELINE                   } from '../subworkflows/local/preprocessing'
include { FLYE                                     } from '../modules/nf-core/flye/main'
include { POLISHING_PIPELINE                       } from '../subworkflows/local/polishing'
include { CURATION_PIPELINE                        } from '../subworkflows/local/curation'
include { ASSESSMENT_PIPELINE                       } from '../subworkflows/local/assessment'

include { MULTIQC                                  } from '../modules/nf-core/multiqc/main'

include { paramsSummaryMap                         } from 'plugin/nf-validation'

include { paramsSummaryMultiqc                     } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML                   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText                   } from '../subworkflows/local/utils_nfcore_hybridassembly_pipeline'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow HYBRIDASSEMBLY {

    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:

    ch_versions            = Channel.empty()
    ch_multiqc_files       = Channel.empty()

    ch_short               = Channel.empty()
    ch_long                = Channel.empty()
    ch_maskedshort_long    = Channel.empty()

    ch_purgedups_purgedups = Channel.empty()
    ch_purgedups_getseqs   = Channel.empty()

    ch_samplesheet.map {
        meta, short_reads1, short_reads2, long_reads ->
            return [ meta, [short_reads1, short_reads2] ]
    }.set {
        ch_short
    }

    ch_samplesheet.map {
        meta, short_reads1, short_reads2, long_reads ->
            return [ meta, [ long_reads ] ]
    }.set {
        ch_long
    }

    ch_samplesheet.map {
        meta, short_reads1, short_reads2, long_reads ->
            return [ meta, [], [ long_reads ] ]
    }.set {
        ch_maskedshort_long
    }

    ch_reference = Channel.empty()

    //
    // SUBWORKFLOW: Preprocessing subworkflow
    //
    PREPROCESSING_PIPELINE ( ch_short, ch_long, ch_maskedshort_long )
    ch_multiqc_files = ch_multiqc_files.mix( PREPROCESSING_PIPELINE.out.preprocessing_multiqc_files )
    ch_versions = ch_versions.mix( PREPROCESSING_PIPELINE.out.versions.first() )

    //
    // MODULE: Run Flye on filtered and corrected reads
    //
    FLYE ( PREPROCESSING_PIPELINE.out.corrected_long_reads, params.flye_mode )
    ch_multiqc_files = ch_multiqc_files.mix( FLYE.out.txt.collect{it[1]} )
    ch_multiqc_files = ch_multiqc_files.mix( FLYE.out.log.collect{it[1]} )
    ch_multiqc_files = ch_multiqc_files.mix( FLYE.out.json.collect{it[1]} )
    ch_versions = ch_versions.mix( FLYE.out.versions.first() )

    //
    // SUBWORKFLOW: Polishing subworkflow
    //
    POLISHING_PIPELINE ( ch_short, PREPROCESSING_PIPELINE.out.corrected_long_reads, FLYE.out.fasta )
    ch_versions = ch_versions.mix( POLISHING_PIPELINE.out.versions.first() )

    //
    // SUBWORKFLOW: Polishing subworkflow
    //
    CURATION_PIPELINE ( PREPROCESSING_PIPELINE.out.corrected_long_reads, POLISHING_PIPELINE.out.polished_assembly )
    ch_versions = ch_versions.mix( CURATION_PIPELINE.out.versions.first() )

    //
    // SUBWORKFLOW: Assessment subworkflow
    //
    ASSESSMENT_PIPELINE ( ch_short, CURATION_PIPELINE.out.polished_assembly, params.fasta )
    ch_multiqc_files = ch_multiqc_files.mix( ASSESSMENT_PIPELINE.out.assessment_multiqc_files )
    ch_versions = ch_versions.mix( ASSESSMENT_PIPELINE.out.versions.first() )

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(storeDir: "${params.outdir}/pipeline_info", name: 'nf_core_pipeline_software_mqc_versions.yml', sort: true, newLine: true)
        .set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    ch_multiqc_config                     = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config              = params.multiqc_config ? Channel.fromPath(params.multiqc_config, checkIfExists: true) : Channel.empty()
    ch_multiqc_logo                       = params.multiqc_logo ? Channel.fromPath(params.multiqc_logo, checkIfExists: true) : Channel.empty()
    summary_params                        = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary                   = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', sort: false))

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
