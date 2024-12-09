#!/bin/bash

# Check if correct number of arguments provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <refseq_bed> <chromhmm_bed> <output_bed>"
    echo "Example: $0 RefSeq_genes_chr22_part_genesMerged.bed NHLF_ChromHMM_chr22_part.bed NHLF_Txn_Elongation_genes.bed"
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

# Count total number of genes
echo "Total number of genes:"
wc -l < "$REFSEQ_BED"

# Create temporary file for Txn_Elongation regions
TMP_TXN="tmp_txn_regions.bed"

# Extract only the Txn_Elongation states from ChromHMM file
awk '$4 == "Txn_Elongation"' "$CHROMHMM_BED" > "$TMP_TXN"

# Use bedtools intersect to find genes that overlap with Txn_Elongation regions
# -u flag tells bedtools to write the original entry from RefSeq file once if any overlap exists
bedtools intersect -a "$REFSEQ_BED" -b "$TMP_TXN" -u > "$OUTPUT_BED"

# Count number of transcribed genes
echo "Number of transcribed genes:"
wc -l < "$OUTPUT_BED"

# Clean up temporary file
rm "$TMP_TXN"
