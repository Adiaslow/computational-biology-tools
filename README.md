# computational-biology-tools
## Usage
0. Remove Old Version (if cloned previously):
```bash
rm -rf computational-biology-tools/
```
1. Clone Repository:
```bash
git clone "https://github.com/Adiaslow/computational-biology-tools.git"
```
2. Run Script:
```bash
bash computational-biology-tools/bash_scripts/<script_name> <arguments>
```
- *See each script for the required arguments.*
---

## Current Scripts
- `analyze_bam_read.sh`
  - Provides detailed alignment information for a specific read including position, strand, CIGAR analysis, and junction detection.
- `analyze_bed_transcripted_genes_state_pattern.sh`
  - Performs comprehensive analysis of ChromHMM states and their overlap with RefSeq genes, providing detailed statistics and generating an output BED file of overlapping genes.
- `compare_fastq_quality.sh`
  - Compares quality scores of two specific reads from a FASTQ file.
- `count_bam_chromosome_reads.sh`
  - Counts the number of reads aligned to specified chromosome in a BAM file.
- `get_bam_fragment_length.sh`
  - Calculates the fragment length for a specific paired-end read from a BAM file.
- `get_kallisto_abundance_gene_expression.sh`
 - Calculates total gene expression (TPM) from Kallisto abundance output.
- `get_vcf_snp_haplotypes.sh`
  - Processes phased genotype data and outputs both haplotypes as sequences of alleles.
