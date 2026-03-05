/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { SAMTOOLS_COLLATEFASTQ     } from '../modules/nf-core/samtools/collatefastq/main'
include { FASTQC                    } from '../modules/nf-core/fastqc/main'
include { GFFREAD                   } from '../modules/nf-core/gffread/main'
include { KALLISTO_INDEX            } from '../modules/nf-core/kallisto/index/main'
include { QUANTIFY_PSEUDO_ALIGNMENT } from '../subworkflows/nf-core/quantify_pseudo_alignment/main'
include { MULTIQC                   } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap          } from 'plugin/nf-schema'
include { paramsSummaryMultiqc      } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML    } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText    } from '../subworkflows/local/utils_nfcore_bamkallisto_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow BAMKALLISTO {
    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:

    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()

    //
    // Convert BAM to paired-end FASTQ
    //
    SAMTOOLS_COLLATEFASTQ(
        ch_samplesheet,
        [[:], [], []],
        false,
    )
    //
    // MODULE: Run FastQC
    //
    if (!params.skip_fastqc) {
        FASTQC(SAMTOOLS_COLLATEFASTQ.out.fastq)
        ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect { it[1] })
        ch_versions = ch_versions.mix(FASTQC.out.versions.first())
    }

    //
    // Prepare index channel (KALLISTO_QUANT expects tuple for index)
    //
    ch_index = channel.empty()
    if (params.transcripts_index) {
        // Use pre-built kallisto index
        ch_index = channel.value([[:], file(params.transcripts_index)])
    }
    else if (params.transcripts_fasta) {
        // Build index from transcriptome FASTA
        KALLISTO_INDEX([[:], file(params.transcripts_fasta)])
        ch_index = KALLISTO_INDEX.out.index
    }
    else {
        // Extract cDNA from GTF + genome FASTA, then index
        GFFREAD([[id: "cdna"], file(params.gtf)], file(params.genome_fasta))
        KALLISTO_INDEX(GFFREAD.out.gffread_fasta)
        ch_index = KALLISTO_INDEX.out.index
    }
    //
    // Prepare channels for QUANTIFY_PSEUDO_ALIGNMENT
    //
    ch_samplesheet_file = channel.fromPath(params.input)
        .map { path -> [[:], path] }
    ch_gtf = channel.value(file(params.gtf))
    ch_transcript_fasta = params.transcripts_fasta
        ? channel.value(file(params.transcripts_fasta))
        : channel.value([])

    //
    // Quantify with kallisto + tximport gene-level summarization
    //
    QUANTIFY_PSEUDO_ALIGNMENT(
        ch_samplesheet_file,
        SAMTOOLS_COLLATEFASTQ.out.fastq,
        ch_index,
        ch_transcript_fasta,
        ch_gtf,
        params.gtf_id_attribute,
        params.gtf_extra_attribute,
        params.pseudo_aligner,
        false,
        params.salmon_quant_libtype,
        params.kallisto_quant_fraglen,
        params.kallisto_quant_fraglen_sd,
    )
    ch_multiqc_files = ch_multiqc_files.mix(QUANTIFY_PSEUDO_ALIGNMENT.out.multiqc.collect { _meta, multiqc -> multiqc })
    ch_versions = ch_versions.mix(QUANTIFY_PSEUDO_ALIGNMENT.out.versions)
    //
    // Collate and save software versions
    //
    def topic_versions = Channel
        .topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [process[process.lastIndexOf(':') + 1..-1], "  ${tool}: ${version}"]
        }
        .groupTuple(by: 0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'bamkallisto_software_' + 'mqc_' + 'versions.yml',
            sort: true,
            newLine: true,
        )
        .set { ch_collated_versions }


    //
    // MODULE: MultiQC
    //
    ch_multiqc_config = channel.fromPath(
        "${projectDir}/assets/multiqc_config.yml",
        checkIfExists: true
    )
    ch_multiqc_custom_config = params.multiqc_config
        ? channel.fromPath(params.multiqc_config, checkIfExists: true)
        : channel.empty()
    ch_multiqc_logo = params.multiqc_logo
        ? channel.fromPath(params.multiqc_logo, checkIfExists: true)
        : channel.empty()

    summary_params = paramsSummaryMap(
        workflow,
        parameters_schema: "nextflow_schema.json"
    )
    ch_workflow_summary = channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml')
    )
    ch_multiqc_custom_methods_description = params.multiqc_methods_description
        ? file(params.multiqc_methods_description, checkIfExists: true)
        : file("${projectDir}/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description = channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description)
    )

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true,
        )
    )

    MULTIQC(
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        [],
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions // channel: [ path(versions.yml) ]
}
