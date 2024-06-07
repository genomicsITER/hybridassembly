/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FASTQC                                   } from '../modules/nf-core/fastqc/main'
include { NANOPLOT as NANOPLOT_RAW                 } from '../modules/nf-core/nanoplot/main'
include { FILTLONG                                 } from '../modules/nf-core/filtlong/main'
include { NANOPLOT as NANOPLOT_FILT                } from '../modules/nf-core/nanoplot/main'
include { RATATOSK                                 } from '../modules/local/ratatosk'
include { REPLACE_IUPAC                            } from '../modules/local/replace_IUPAC'
include { NANOPLOT as NANOPLOT_CORR                } from '../modules/nf-core/nanoplot/main'
include { FLYE                                     } from '../modules/nf-core/flye/main'
include { MINIMAP2_ALIGN as MINIMAP2_ALIGN_ROUND_1 } from '../modules/nf-core/minimap2/align/main'
include { MINIMAP2_ALIGN as MINIMAP2_ALIGN_ROUND_2 } from '../modules/nf-core/minimap2/align/main'
include { RACON as RACON_ROUND_1                   } from '../modules/nf-core/racon/main'
include { RACON as RACON_ROUND_2                   } from '../modules/nf-core/racon/main'
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

    ch_versions          = Channel.empty()
    ch_multiqc_files     = Channel.empty()

    ch_short             = Channel.empty()
    ch_long              = Channel.empty()
    ch_maskedshort_long  = Channel.empty()

    ch_polishing_racon_1 = Channel.empty()

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

    //
    // MODULE: Run FastQC
    //
    FASTQC ( ch_short )
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]})
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())

    //
    // MODULE: Run NanoPlot
    //
    NANOPLOT_RAW ( ch_long )
    ch_multiqc_files = ch_multiqc_files.mix(NANOPLOT_RAW.out.txt.collect{it[1]})
    ch_versions = ch_versions.mix(NANOPLOT_RAW.out.versions.first())

    //
    // MODULE: Run FiltLong
    //
    FILTLONG ( ch_maskedshort_long )
    ch_multiqc_files = ch_multiqc_files.mix(FILTLONG.out.log.collect{it[1]})
    ch_versions = ch_versions.mix(FILTLONG.out.versions.first())

    ch_short_longfiltered = ch_short.join(FILTLONG.out.reads)

    //
    // MODULE: Run NanoPlot on filtered reads
    //
    NANOPLOT_FILT ( FILTLONG.out.reads )
    ch_multiqc_files = ch_multiqc_files.mix(NANOPLOT_FILT.out.txt.collect{it[1]})
    ch_versions = ch_versions.mix(NANOPLOT_FILT.out.versions.first())

    //
    // MODULE: Run Ratatosk on filtered reads (local module)
    //
    RATATOSK ( ch_short_longfiltered )
    ch_versions = ch_versions.mix(RATATOSK.out.versions.first())

    //
    // MODULE: Replace IUPAC characters from corrected reads
    //
    REPLACE_IUPAC ( RATATOSK.out.reads )
    ch_versions = ch_versions.mix(REPLACE_IUPAC.out.versions.first())

    ch_short_longcorrected = ch_short.mix(REPLACE_IUPAC.out.reads)

    //
    // MODULE: Run NanoPlot on filtered reads
    //
    NANOPLOT_CORR ( REPLACE_IUPAC.out.reads )
    ch_multiqc_files = ch_multiqc_files.mix(NANOPLOT_CORR.out.txt.collect{it[1]})
    ch_versions = ch_versions.mix(NANOPLOT_CORR.out.versions.first())

    //
    // MODULE: Run Flye on filtered and corrected reads
    //
    FLYE ( REPLACE_IUPAC.out.reads, params.flye_mode )
    ch_multiqc_files = ch_multiqc_files.mix(FLYE.out.txt.collect{it[1]})
    ch_multiqc_files = ch_multiqc_files.mix(FLYE.out.log.collect{it[1]})
    ch_multiqc_files = ch_multiqc_files.mix(FLYE.out.json.collect{it[1]})
    ch_versions = ch_versions.mix(FLYE.out.versions.first())

    //
    // MODULE: First round of polishing with Racon
    //
    MINIMAP2_ALIGN_ROUND_1 (REPLACE_IUPAC.out.reads, FLYE.out.fasta, false, false, false)
    ch_versions = ch_versions.mix(MINIMAP2_ALIGN_ROUND_1.out.versions.first())

    ch_polishing_racon_1 = ch_polishing_racon_1
        .mix (FLYE.out.fasta)
        .join (MINIMAP2_ALIGN_ROUND_1.out.paf)
        .map { meta, short_reads, long_reads, assembly, paf -> tuple(meta, long_reads, assembly, paf) }

    RACON_ROUND_1 ( ch_polishing_racon_1 )
    ch_versions = ch_versions.mix(RACON_ROUND_1.out.versions.first())

    //
    // MODULE: Second round of polishing with Racon
    //
    MINIMAP2_ALIGN_ROUND_2 (REPLACE_IUPAC.out.reads, RACON_ROUND_1.out.improved_assembly, false, false, false)
    ch_versions = ch_versions.mix(MINIMAP2_ALIGN_ROUND_2.out.versions.first())

    ch_polishing_racon_2 = ch_polishing_racon_1
        .mix (RACON_ROUND_1.out.improved_assembly)
        .join (MINIMAP2_ALIGN_ROUND_2.out.paf)
        .map { meta, short_reads, long_reads, assembly, paf -> tuple(meta, long_reads, assembly, paf) }

    RACON_ROUND_2 ( ch_polishing_racon_2 )
    ch_versions = ch_versions.mix(RACON_ROUND_2.out.versions.first())

    //
    // MODULE: Final polishing step with Pilon
    //
    // TODO

    //
    // MODULE: Purge haplotigs and overlaps with purge_dups
    //
    // TODO

    //
    // MODULE: Correction and scaffolding with RagTag
    //
    // TODO

    //
    // MODULE: Close gaps with TGS-GapCloser
    //
    // TODO

    //
    // MODULE: Assembly evaluation with QUAST
    //
    // TODO

    //
    // MODULE: Assembly evaluation with BUSCO
    //
    // TODO

    //
    // MODULE: Assembly evaluation with Merqury
    //
    // TODO

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
