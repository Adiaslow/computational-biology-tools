#!/bin/bash

# Check if correct number of arguments provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <refseq_bed> <chromhmm_bed> <output_bed>"
    echo
    echo "Description:"
    echo "  This script counts genes and identifies transcribed genes using ChromHMM data"
    echo
    echo "Arguments:"
    echo "  refseq_bed    - BED file with RefSeq genes"
    echo "  chromhmm_bed  - BED file with ChromHMM states"
    echo "  output_bed    - Output file name for transcribed genes"
    echo
    echo "Example:"
    echo "  $0 RefSeq_genes.bed NHLF_ChromHMM.bed NHLF_Txn_Elongation_genes.bed"
    exit 1
fi

# Get arguments
REFSEQ_BED="$1"
CHROMHMM_BED="$2"
OUTPUT_BED="$3"

# Check if input files exist
if [ ! -f "$REFSEQ_BED" ]; then
    echo "Error: RefSeq BED file not found: $REFSEQ_BED"
    exit 1
fi

if [ ! -f "$CHROMHMM_BED" ]; then
    echo "Error: ChromHMM BED file not found: $CHROMHMM_BED"
    exit 1
fi

# Load bedtools module
module purge  # Clear any existing modules
module load bedtools

# Verify bedtools is available
if ! command -v bedtools &> /dev/null; then
    echo "Error: Failed to load bedtools module"
    exit 1
fi

# Print header for results
echo "=== Gene Analysis Results ==="
echo

# Count and display total number of genes
total_genes=$(wc -l < "$REFSEQ_BED")
echo "Total number of genes: $total_genes"

# Create temporary file for Txn_Elongation regions
TMP_TXN=$(mktemp)
trap 'rm -f "$TMP_TXN"' EXIT

# Debug: Check unique states in ChromHMM file
echo -e "\nUnique states in ChromHMM file:"
cut -f 4 "$CHROMHMM_BED" | sort | uniq

# Extract Txn_Elongation states from ChromHMM file
awk '$4 == "Txn_Elongation"' "$CHROMHMM_BED" > "$TMP_TXN"

# Debug: Check if we found any Txn_Elongation regions
txn_regions=$(wc -l < "$TMP_TXN")
echo -e "\nNumber of Txn_Elongation regions found: $txn_regions"

# Use bedtools intersect to find transcribed genes
bedtools intersect -a "$REFSEQ_BED" -b "$TMP_TXN" -u > "$OUTPUT_BED"

# Count and display number of transcribed genes
transcribed_genes=$(wc -l < "$OUTPUT_BED")
echo -e "\nNumber of transcribed genes: $transcribed_genes"

# Debug: Show the first few lines of the temporary and output files
echo -e "\nFirst few lines of Txn_Elongation regions file:"
head -n 3 "$TMP_TXN"

echo -e "\nFirst few lines of output file (if any):"
head -n 3 "$OUTPUT_BED"

echo -e "\nResults written to: $OUTPUT_BED"
