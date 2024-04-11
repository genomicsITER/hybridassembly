--- UNDER CONSTRUCTION ---

# Hybrid assembly

A public repository of **hybrid assembly** pipeline maintained by ITER.

## Introduction

**nf-core/hybridassembly** is a bioinformatics pipeline that ...

<!-- TODO nf-core:
   Complete this sentence with a 2-3 sentence summary of what types of data the pipeline ingests, a brief overview of the
   major pipeline sections and the types of output it produces. You're giving an overview to someone new
   to nf-core here, in 15-20 seconds. For an example, see https://github.com/nf-core/rnaseq/blob/master/README.md#introduction
-->

## Pipeline summary

<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/Simplified pipeline.drawio.svg">
    <img alt="Hybrid assembly pipeline" src="docs/images/Simplified pipeline.drawio.svg">
  </picture>
</h1>

1. Illumina read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
2. ONT read QC ([`NanoPlot`](https://github.com/wdecoster/NanoPlot))
3. Quality filtering long reads ([`Filtlong`](https://github.com/rrwick/Filtlong))
4. Hybrid error correction of long reads ([`Ratatosk`](https://github.com/DecodeGenetics/Ratatosk))
5. De novo assembler ([`Flye`](https://github.com/fenderglass/Flye))
6. Assembly polishing using long-reads ([`Racon`](https://github.com/isovic/racon))
7. Assembly polishing using short-reads ([`Pilon`](https://github.com/broadinstitute/pilon))
8. Purge haplotigs and overlaps ([`Purge_Dups`](https://github.com/dfguan/purge_dups))
9. Contig correction and scaffolding ([`RagTag`](https://github.com/malonge/RagTag))
10. Close gaps ([`TGS-GapCloser`](https://github.com/BGI-Qingdao/TGS-GapCloser))
11. Quality assessment of genome assembly ([`QUAST`](https://quast.sourceforge.net/))
12. k-mer based assembly evaluation ([`Merqury`](https://github.com/marbl/merqury))
13. Single-Copy Orthologs based assessment ([`BUSCO`](https://busco.ezlab.org/))
14. Aggregate QC results ([`MultiQC`](http://multiqc.info/))

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,fastq_1,fastq_2,long_reads
SAMPLENAME,SAMPLENAME_R1_001.fastq.gz,SAMPLENAME_R2_001.fastq.gz,SAMPLENAME_LR.fastq.gz
```

Each row represents a sample with both paired-end FASTQ files (gzipped) and ONT long-read FASTQ file (gzipped).

<!-- TODO nf-core: Describe the minimum required steps to execute the pipeline, e.g. how to prepare samplesheets.
     Explain what rows and columns represent. For instance (please edit as appropriate):

-->

Now, you can run the pipeline using:

<!-- TODO nf-core: update the following command to include all required parameters for a minimal example -->

```bash
nextflow run main.nf \
   -profile <default/docker/conda> \
   --input samplesheet.csv \
   --outdir <OUTDIR>
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_;
> see [docs](https://nf-co.re/usage/configuration#custom-configuration-files).

For more details and further functionality, please refer to the [usage documentation](https://nf-co.re/hybridassembly/usage) and the [parameter documentation](https://nf-co.re/hybridassembly/parameters).

## Pipeline output

To see the results of an example test run with a full size dataset refer to the [results](https://nf-co.re/hybridassembly/results) tab on the nf-core website pipeline page.
For more details about the output files and reports, please refer to the
[output documentation](https://nf-co.re/hybridassembly/output).

## Code for genome preprocessing, assembly, polishing, and evaluation

See [here](https://github.com/AdrianMBarrera/hybridassembly/blob/master/docs/benchmarking_code.md) a detailed use of each tool used for preprocessing, assembly, polishing, and evaluation.

## Credits

nf-core/hybridassembly was originally written by Adrián Muñoz.

We thank the following people for their extensive assistance in the development of this pipeline:

<!-- TODO nf-core: If applicable, make list of people who have also contributed -->

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#hybridassembly` channel](https://nfcore.slack.com/channels/hybridassembly) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use nf-core/hybridassembly for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).

## Changelog

> May ??, 2024. Make this repository public.
> April 11, 2024. Added command usage sections.
> April 1, 2024. Created the initial version of this repository.
