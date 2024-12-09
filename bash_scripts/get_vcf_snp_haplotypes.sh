#!/bin/bash
# Check if enough arguments
if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <vcf_file> <sample_id> <snp_id1> [snp_id2 ...]"
    echo
    echo "Description:"
    echo "  This script extracts haplotypes for specified SNPs from a VCF file for a given sample."
    echo "  It processes phased genotype data and outputs both haplotypes as sequences of alleles."
    echo "  The script requires bcftools and handles both reference and alternate alleles."
    echo
    echo "Arguments:"
    echo "  vcf_file  - Input VCF file containing genetic variants"
    echo "  sample_id - ID of the sample to analyze"
    echo "  snp_id1   - First SNP ID to include in haplotype"
    echo "  [snp_id2 ...] - Additional SNP IDs (optional)"
    echo
    echo "Output:"
    echo "  Displays two lines showing the allele sequence for each haplotype:"
    echo "    Haplotype 1: sequence of alleles from first chromosome"
    echo "    Haplotype 2: sequence of alleles from second chromosome"
    echo
    echo "Requirements:"
    echo "  - bcftools (loaded automatically)"
    echo "  - Input VCF must be properly formatted with:"
    echo "    * Phased genotypes (separated by |)"
    echo "    * Valid sample IDs"
    echo "    * SNP IDs in the ID field"
    echo
    echo "Examples:"
    echo "  Extract haplotypes for a single SNP:"
    echo "    $0 sample.vcf SAMPLE1 rs123"
    echo
    echo "  Extract haplotypes for multiple SNPs:"
    echo "    $0 sample.vcf SAMPLE1 rs123 rs456 rs789"
    echo
    echo "Notes:"
    echo "  - SNPs will be processed in the order provided"
    echo "  - Missing or invalid SNP IDs will be skipped"
    echo "  - Temporary file 'snps.txt' will be created and removed"
    echo "  - For unphased data (/ separator), results may not represent true haplotypes"
    exit 1
fi

# Check if bcftools module is loaded
if ! module list 2>&1 | grep -q "bcftools"; then
    echo "Loading bcftools module..."
    module load bcftools
fi

# Check if module load was successful
if ! command -v bcftools &> /dev/null; then
    echo "Error: Failed to load bcftools module"
    exit 1
fi

vcf_file=$1
shift
sample=$1
shift

# Check if VCF file exists
if [ ! -f "$vcf_file" ]; then
    echo "Error: VCF file $vcf_file does not exist"
    exit 1
fi

# Create temporary file with SNP IDs
printf "%s\n" "$@" > snps.txt

# Extract and process haplotypes
echo "=== Haplotype Analysis ==="
echo "VCF File: $vcf_file"
echo "Sample: $sample"
echo "Number of SNPs: $#"
echo

bcftools view -s "$sample" -i 'ID=@snp
