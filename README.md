--- UNDER CONSTRUCTION ---

# Hybrid assembly

A public repository of **hybrid *de novo* assembly** pipeline maintained by ITER.

## Introduction

**hybridassembly** is a bioinformatics pipeline that performs preprocessing, *de novo* assembly, polishing and evaluation steps to obtain high-quality human genomes using long-reads from Oxford Nanopore Sequencing (ONT) and short-reads from Illumina. It takes a samplesheet with ONT and Illumina FASTQ files as input, perform quality control (QC), filtering, error-correction, assembly, polishing with self long-reads and short-reads, and post-assembly curation, among assembly evaluations with different tools.

The **hybridassembly** pipeline is built using [Nextflow](https://www.nextflow.io/), following [nf-core](https://nf-co.re) guidelines and templates.

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
5. *De novo* assembler ([`Flye`](https://github.com/fenderglass/Flye))
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

Now, you can run the pipeline using:

```bash
nextflow run main.nf \
   -profile <default/docker/conda> \
   --input samplesheet.csv \
   --outdir <OUTDIR>
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_;
> see [docs](https://nf-co.re/usage/configuration#custom-configuration-files).

For more details and further functionality, please refer to the [usage documentation](docs/usage.md).

## Pipeline output

For more details about the output files and reports, please refer to the [output documentation](docs/output.md).

## Code for genome preprocessing, assembly, polishing, and evaluation

See [here](docs/benchmarking_code.md) a detailed use of each tool used for preprocessing, assembly, polishing, and evaluation.

## Credits

This pipeline was originally written by Adrián Muñoz-Barrera.

<!-- TODO Add the reference to the paper -->

<!-- TODO Add funding -->

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

Follow us on X: [@LabCflores](https://x.com/LabCflores)

## Citations

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.
