# shahcompbio/bamkallisto: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.1.0 - [26/03/05]

### `Added`

- Gene-level quantification via tximport using nf-core `quantify_pseudo_alignment` subworkflow
- Support for both kallisto and salmon pseudoaligners (`--pseudo_aligner`)
- New parameters:
  - `--gtf_id_attribute`: Gene ID attribute in GTF (default: 'gene_id')
  - `--gtf_extra_attribute`: Extra gene attribute in GTF (default: 'gene_name')
  - `--salmon_quant_libtype`: Override Salmon library type
  - `--extra_kallisto_quant_args`: Extra args for kallisto (default: '-b 100')
  - `--extra_salmon_quant_args`: Extra args for salmon

### `Fixed`

### `Dependencies`

- samtools 1.22.1
- kallisto 0.51.1
- salmon (via nf-core subworkflow)
- tximport, tximeta, summarizedExperiment (R packages)
- FastQC
- MultiQC
- gffread 0.12.7

### `Deprecated`

## 1.0.0 - [26/03/04]

Initial release of shahcompbio/bamkallisto, created with the [nf-core](https://nf-co.re/) template.

### `Added`

- BAM-to-FASTQ conversion using `samtools collate | samtools fastq` (SAMTOOLS_COLLATEFASTQ)
- Transcript quantification with `kallisto quant` including bootstrap support (`-b 100`)
- Three paths for kallisto index preparation:
  - Pre-built kallisto index (`--transcripts_index`)
  - Transcriptome FASTA (`--transcripts_fasta`) with automatic indexing
  - GTF + genome FASTA (`--gtf` + `--genome_fasta`) with cDNA extraction via gffread
- FastQC for read quality control (skippable with `--skip_fastqc`)
- MultiQC for aggregated QC reporting
- Test profile using yeast (S. cerevisiae R64-1-1) data from nf-core/test-datasets

### `Fixed`

### `Dependencies`

- samtools 1.22.1
- kallisto 0.51.1
- FastQC
- MultiQC
- gffread 0.12.7

### `Deprecated`
