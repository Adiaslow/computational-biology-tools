#!/bin/bash
# Check if correct number of arguments provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <refseq_bed> <chromhmm_bed> <state_pattern>"
    echo
    echo "Description:"
    echo "  This script analyzes ChromHMM states and their overlap with RefSeq genes"
    echo
    echo "Arguments:"
    echo "  refseq_bed    - BED file with RefSeq genes"
    echo "  chromhmm_bed  - BED file with ChromHMM states"
    echo "  state_pattern - Pattern to match ChromHMM state (e.g., Active_Promoter)"
    echo
    echo "Example:"
    echo "  $0 RefSeq_genes_chr22_part_genesMerged.bed NHLF_ChromHMM_chr22_part.bed Active_Promoter"
    exit 1
fi

# Get arguments
REFSEQ_BED="$1"
CHROMHMM_BED="$2"
STATE_PATTERN="$3"

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
echo "=== ChromHMM State Analysis ==="
echo

# Show all available ChromHMM states
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

# Count regions with the specified state
state_count=$(grep -c "$MATCHING_STATE" "$CHROMHMM_BED")
echo "Number of regions with state '$MATCHING_STATE': $state_count"

# Create temporary file for matching state regions
TMP_REGIONS=$(mktemp)
trap 'rm -f "$TMP_REGIONS"' EXIT

# Extract regions with matching state
awk -v state="$MATCHING_STATE" '$4 == state' "$CHROMHMM_BED" > "$TMP_REGIONS"

# Find genes overlapping with matching state regions
overlapping_genes=$(bedtools intersect -a "$REFSEQ_BED" -b "$TMP_REGIONS" -u | wc -l)
echo "Number of genes overlapping with '$MATCHING_STATE' regions: $overlapping_genes"
