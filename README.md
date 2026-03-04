# shahcompbio/bamkallisto

[![GitHub Actions CI Status](https://github.com/shahcompbio/bamkallisto/actions/workflows/nf-test.yml/badge.svg)](https://github.com/shahcompbio/bamkallisto/actions/workflows/nf-test.yml)
[![GitHub Actions Linting Status](https://github.com/shahcompbio/bamkallisto/actions/workflows/linting.yml/badge.svg)](https://github.com/shahcompbio/bamkallisto/actions/workflows/linting.yml)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/version-%E2%89%A525.04.0-green?style=flat&logo=nextflow&logoColor=white&color=%230DC09D&link=https%3A%2F%2Fnextflow.io)](https://www.nextflow.io/)
[![nf-core template version](https://img.shields.io/badge/nf--core_template-3.5.2-green?style=flat&logo=nfcore&logoColor=white&color=%2324B064&link=https%3A%2F%2Fnf-co.re)](https://github.com/nf-core/tools/releases/tag/3.5.2)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

## Introduction

**shahcompbio/bamkallisto** is a bioinformatics pipeline that converts transcriptome-aligned BAM files to FASTQ and quantifies transcript expression using [kallisto](https://pachterlab.github.io/kallisto/). It is designed for quantify expression in short-read RNAseq data against custom transcriptome references (e.g., ONT-derived assemblies) starting from existing transcriptome BAM files.

The pipeline performs the following steps:

1. Convert transcriptome BAMs to paired-end FASTQs ([`samtools collate/fastq`](http://www.htslib.org/doc/samtools.html))
2. Read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
3. Pseudoalignment and transcript quantification ([`kallisto quant`](https://pachterlab.github.io/kallisto/manual))
4. Aggregate QC report ([`MultiQC`](http://multiqc.info/))

```
samplesheet.csv
      |
  [parse samplesheet]
      |
  SAMTOOLS_COLLATEFASTQ (per sample)
      |
  FASTQC ──────────────────────┐
      |                        |
  KALLISTO_QUANT (per sample)  |
      |                        |
  results/{sample}/            |
    abundance.tsv              |
    abundance.h5               |
    run_info.json              |
                               |
  MULTIQC ◄────────────────────┘
      |
  multiqc_report.html
```

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,transcriptome_bam
SAMPLE_1,/path/to/sample1.Aligned.toTranscriptome.out.bam
SAMPLE_2,/path/to/sample2.Aligned.toTranscriptome.out.bam
```

Each row represents a transcriptome-aligned BAM file for one sample.

Now, you can run the pipeline using:

```bash
# With a pre-built kallisto index
nextflow run shahcompbio/bamkallisto \
   -profile <docker/singularity> \
   --input samplesheet.csv \
   --transcripts_index /path/to/kallisto/index \
   --outdir <OUTDIR>

# With a transcriptome FASTA (index will be built automatically)
nextflow run shahcompbio/bamkallisto \
   -profile <docker/singularity> \
   --input samplesheet.csv \
   --transcripts_fasta /path/to/transcriptome.fasta \
   --outdir <OUTDIR>

# With a GTF + genome FASTA (cDNA extraction + indexing)
nextflow run shahcompbio/bamkallisto \
   -profile <docker/singularity> \
   --input samplesheet.csv \
   --gtf /path/to/annotation.gtf \
   --genome_fasta /path/to/genome.fasta \
   --outdir <OUTDIR>
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

For more details, see the [usage documentation](docs/usage.md) and the [output documentation](docs/output.md).

## Parameters

| Parameter                     | Description                                          | Default  |
| ----------------------------- | ---------------------------------------------------- | -------- |
| `--input`                     | Path to samplesheet CSV                              | required |
| `--transcripts_index`         | Path to pre-built kallisto index                     | -        |
| `--transcripts_fasta`         | Path to transcriptome FASTA (builds index)           | -        |
| `--gtf`                       | Path to GTF annotation (used with `--genome_fasta`)  | -        |
| `--genome_fasta`              | Path to genome FASTA (used with `--gtf`)             | -        |
| `--outdir`                    | Output directory                                     | required |
| `--skip_fastqc`               | Skip FastQC step                                     | `false`  |
| `--kallisto_quant_fraglen`    | Estimated fragment length (single-end mode)          | `200`    |
| `--kallisto_quant_fraglen_sd` | Fragment length standard deviation (single-end mode) | `200`    |

One of `--transcripts_index`, `--transcripts_fasta`, or `--gtf` + `--genome_fasta` must be provided.

## Credits

shahcompbio/bamkallisto was originally written by Asher Preska Steinberg.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
