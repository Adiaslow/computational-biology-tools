#!/bin/bash

# Check if correct number of arguments provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <refseq_bed> <chromhmm_bed> <chromhmm_state_pattern> <output_bed>"
    echo
    echo "Description:"
    echo "  This script identifies genes that overlap with a specified ChromHMM state pattern"
    echo
    echo "Arguments:"
    echo "  refseq_bed           - BED file with RefSeq genes"
    echo "  chromhmm_bed         - BED file with ChromHMM states"
    echo "  chromhmm_state_pattern - Pattern to match ChromHMM state (e.g., Txn_Elongation)"
    echo "  output_bed           - Output file name for identified genes"
    echo
    echo "Example:"
    echo "  $0 RefSeq_genes.bed NHLF_ChromHMM.bed Txn_Elongation NHLF_genes.bed"
    exit 1
fi

# Get arguments
REFSEQ_BED="$1"
CHROMHMM_BED="$2"
STATE_PATTERN="$3"
OUTPUT_BED="$4"

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
module load bedtools

# Verify bedtools is available
if ! command -v bedtools &> /dev/null; then
    echo "Error: Failed to load bedtools module"
    exit 1
fi

# Print header for results
echo "=== Gene Analysis Results ==="
echo

# Show available ChromHMM states
echo "Available ChromHMM states:"
cut -f 4 "$CHROMHMM_BED" | sort | uniq
echo

# Find matching state
MATCHING_STATE=$(cut -f 4 "$CHROMHMM_BED" | sort | uniq | grep "$STATE_PATTERN")
MATCH_COUNT=$(echo "$MATCHING_STATE" | grep -v '^$' | wc -l)

if [ "$MATCH_COUNT" -eq 0 ]; then
    echo "Error: No ChromHMM states found matching pattern '$STATE_PATTERN'"
    exit 1
elif [ "$MATCH_COUNT" -gt 1 ]; then
    echo "Error: Multiple ChromHMM states match pattern '$STATE_PATTERN':"
    echo "$MATCHING_STATE"
    exit 1
fi

echo "Found matching ChromHMM state: $MATCHING_STATE"
echo

# Count and display total number of genes
total_genes=$(wc -l < "$REFSEQ_BED")
echo "Total number of genes: $total_genes"

# Create temporary file for selected state regions
TMP_REGIONS=$(mktemp)
trap 'rm -f "$TMP_REGIONS"' EXIT

# Extract regions with matching state
awk -v state="$MATCHING_STATE" '$4 == state' "$CHROMHMM_BED" > "$TMP_REGIONS"

# Check if we found any regions with specified state
regions_found=$(wc -l < "$TMP_REGIONS")
echo "Number of regions found for state '$MATCHING_STATE': $regions_found"

# Use bedtools intersect to find overlapping genes
bedtools intersect -a "$REFSEQ_BED" -b "$TMP_REGIONS" -u > "$OUTPUT_BED"

# Count and display number of overlapping genes
overlapping_genes=$(wc -l < "$OUTPUT_BED")
echo "Number of genes overlapping with '$MATCHING_STATE': $overlapping_genes"
echo
echo "Results written to: $OUTPUT_BED"
