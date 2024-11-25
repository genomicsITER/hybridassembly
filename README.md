# Hybrid assembly

--- UNDER CONSTRUCTION ---

<!--[![GitHub Actions CI Status](https://github.com/nf-core/viralrecon/workflows/nf-core%20CI/badge.svg)](https://github.com/nf-core/viralrecon/actions?query=workflow%3A%22nf-core+CI%22)
[![GitHub Actions Linting Status](https://github.com/nf-core/viralrecon/workflows/nf-core%20linting/badge.svg)](https://github.com/nf-core/viralrecon/actions?query=workflow%3A%22nf-core+linting%22)
[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?logo=Amazon%20AWS)](https://nf-co.re/viralrecon/results)
[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.3901628-1073c8)](https://doi.org/10.5281/zenodo.3901628)
-->

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A524.04.2-23aa62.svg)](https://www.nextflow.io/)
[![nf-core](https://img.shields.io/badge/build_using-nf--core-1a9655)](https://nf-co.re/)

[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

[![Follow on X](http://img.shields.io/badge/%40LabCFlores-1DA1F2?labelColor=000000&logo=X)](https://x.com/LabCFlores)
<!--[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23viralrecon-4A154B?labelColor=000000&logo=slack)](https://nfcore.slack.com/channels/viralrecon)
[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/c/nf-core)-->

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

> [!TIP]
> If you are working with large genomes, as human, we recommend to include only one sample in the samplesheet at a time, due to the high computational requirements used by some pipeline steps.

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

## Running the pipeline with test data

To ensure the pipeline is set up correctly and functioning as expected, you can run it with the provided test data. The test data consists of a small subset of the human chromosome 22 sequence, specifically selected for quick and efficient testing. Follow these steps:

### 1. Clone the repository

First, clone the repository and navigate to the project directory:

```bash
git clone https://github.com/genomicsITER/hybridassembly
cd hybridassembly
```

Test data is included in the repository under the `test_data/` directory.

### 2. Run the pipeline

Execute the pipeline with the test data using the following command:

```bash
nextflow run main.nf \
   -profile test,<docker/singularity/conda> \
   -config test.config
```

### 3. Check the results

Upon successful completion, the output files will be saved in the `test_data/results` directory. Review the output to verify that the pipeline ran correctly.

### 4. Troubleshooting

If you encounter errors, ensure:

- The required dependencies (e.g., Nextflow, Docker/Singularity/Conda) are installed.
- You are using a compatible environment.
- Use the -resume flag to retry failed tasks without re-running completed ones:

```bash
nextflow run main.nf \
   -profile test,<docker/singularity/conda> \
   -config test.config \
   -resume
```

For further assistance, feel free to open an issue in this repository.

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

[Preprint](https://www.biorxiv.org/content/10.1101/2024.05.28.595812v1): Muñoz-Barrera, Adrián, Luis A. Rubio-Rodríguez, David Jáspez, Almudena Corrales, Itahisa Marcelino-Rodriguez, José M. Lorenzo-Salazar, Rafaela González-Montelongo, and Carlos Flores. 2024. “Benchmarking of Bioinformatics Tools for the Hybrid de Novo Assembly of Human Whole-Genome Sequencing Data.” bioRxiv.

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.
