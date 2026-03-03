# bamkallisto Pipeline Plan

## Overview

Simple Nextflow pipeline to convert transcriptome-aligned BAMs to FASTQs and quantify with kallisto against a custom transcriptome.

## Processes

### 1. BAM2FASTQ

Convert paired-end transcriptome BAMs to FASTQ pairs using samtools.

- **Tool**: `samtools fastq`
- **Container**: `quay.io/biocontainers/samtools` (latest stable, e.g. 1.21)
- **Command**:
  ```bash
  samtools fastq -1 ${sample}_R1.fastq.gz -2 ${sample}_R2.fastq.gz \
    -0 /dev/null -s /dev/null --threads ${task.cpus} ${bam}
  ```
- **Input**: tuple val(meta), path(bam)
- **Output**: tuple val(meta), path("*_R1.fastq.gz"), path("*_R2.fastq.gz")
- **Resources**: ~4 CPUs, 8 GB memory

### 2. KALLISTO_QUANT

Pseudoalign reads and quantify transcript expression.

- **Tool**: `kallisto quant`
- **Container**: `quay.io/biocontainers/kallisto` (e.g. 0.51.1)
- **Command**:
  ```bash
  kallisto quant -i ${index} -o ${sample} -t ${task.cpus} ${fastq_1} ${fastq_2}
  ```
- **Input**: tuple val(meta), path(fastq_1), path(fastq_2), path(index)
- **Output**: tuple val(meta), path("${sample}/abundance.tsv"), path("${sample}/abundance.h5"), path("${sample}/run_info.json")
- **Resources**: ~4 CPUs, 16 GB memory

## Input Samplesheet

CSV format with columns:

```csv
sample,bam
IID_H214200_T01_01_WT01,/data1/papaemme/isabl/data/analyses/29/68/582968/IID_H214200_T01_01_WT01.bam
```

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `input` | Path to samplesheet CSV | required |
| `kallisto_index` | Path to pre-built kallisto index | required |
| `outdir` | Output directory | `results` |

## Pre-built Kallisto Index

Located at:
```
/data1/shahs3/users/preskaa/SarcAtlas/data/APS033_ont_transcript_assembly/nanoquant_default_NDR/kallisto/kallisto
```

This index was built from the ONT-derived custom transcriptome.

## Workflow DAG

```
samplesheet.csv
      |
  [parse samplesheet]
      |
  BAM2FASTQ (per sample)
      |
  KALLISTO_QUANT (per sample)
      |
  results/{sample}/abundance.tsv
```

## Profiles Needed

- `singularity` — run containers via Singularity
- `slurm` — submit processes as SLURM jobs

## HPC Launch Command

```bash
nextflow run /path/to/bamkallisto \
  -profile singularity,slurm \
  --input samplesheet.csv \
  --kallisto_index /data1/shahs3/users/preskaa/SarcAtlas/data/APS033_ont_transcript_assembly/nanoquant_default_NDR/kallisto/kallisto \
  --outdir /data1/shahs3/users/preskaa/SarcAtlas/data/APS054_rnaseq_test \
  -with-trace \
  -with-report \
  -resume
```
