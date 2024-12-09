#!/bin/bash
# Check if correct number of arguments provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <refseq_bed> <chromhmm_bed> <output_bed> <state_pattern>"
    echo
    echo "Description:"
    echo "  This script performs comprehensive analysis of ChromHMM states and their"
    echo "  overlap with RefSeq genes, providing detailed statistics and generating"
    echo "  an output BED file of overlapping genes"
    echo
    echo "Arguments:"
    echo "  refseq_bed    - BED file with RefSeq genes"
    echo "  chromhmm_bed  - BED file with ChromHMM states"
    echo "  output_bed    - Output file name for identified genes"
    echo "  state_pattern - Pattern to match ChromHMM state (e.g., Active_Promoter)"
    echo
    echo "Example:"
    echo "  $0 RefSeq_genes_chr22_part_genesMerged.bed NHLF_ChromHMM_chr22_part.bed output.bed Active_Promoter"
    exit 1
fi

# Get arguments
REFSEQ_BED="$1"
CHROMHMM_BED="$2"
OUTPUT_BED="$3"
STATE_PATTERN="$4"

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
echo "=== ChromHMM State Analysis Results ==="
echo "Analysis Date: $(date)"
echo "RefSeq BED file: $REFSEQ_BED"
echo "ChromHMM BED file: $CHROMHMM_BED"
echo

# Show file information
echo "=== File Information ==="
echo "RefSeq BED file size: $(du -h "$REFSEQ_BED" | cut -f1)"
echo "ChromHMM BED file size: $(du -h "$CHROMHMM_BED" | cut -f1)"
echo

# Show general statistics
echo "=== General Statistics ==="
echo "Total number of genes: $(wc -l < "$REFSEQ_BED")"
echo "Total number of ChromHMM regions: $(wc -l < "$CHROMHMM_BED")"
echo

# Show chromosome distribution
echo "=== Chromosome Distribution ==="
echo "ChromHMM regions by chromosome:"
cut -f 1 "$CHROMHMM_BED" | sort | uniq -c
echo

# Show all ChromHMM states and their counts
echo "=== ChromHMM State Distribution ==="
echo "All ChromHMM states and their frequencies:"
cut -f 4 "$CHROMHMM_BED" | sort | uniq -c | sort -nr
echo

# Find matching state
echo "=== State Pattern Analysis ==="
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

# Create temporary file for matching state regions
TMP_REGIONS=$(mktemp)
trap 'rm -f "$TMP_REGIONS"' EXIT

# Extract regions with matching state
awk -v state="$MATCHING_STATE" '$4 == state' "$CHROMHMM_BED" > "$TMP_REGIONS"

# Detailed analysis of matching state regions
echo "=== Detailed State Analysis ==="
echo "Number of regions with state '$MATCHING_STATE': $(wc -l < "$TMP_REGIONS")"
echo "Total bases covered by '$MATCHING_STATE': $(awk '{sum += $3-$2} END {print sum}' "$TMP_REGIONS")"
echo "Average region length: $(awk '{sum += $3-$2; count++} END {printf "%.2f\n", sum/count}' "$TMP_REGIONS") bases"
echo

# Perform intersection analysis
echo "=== Gene Overlap Analysis ==="
bedtools intersect -a "$REFSEQ_BED" -b "$TMP_REGIONS" -u > "$OUTPUT_BED"
OVERLAPPING_COUNT=$(wc -l < "$OUTPUT_BED")
TOTAL_GENES=$(wc -l < "$REFSEQ_BED")
PERCENT=$(awk -v overlap="$OVERLAPPING_COUNT" -v total="$TOTAL_GENES" 'BEGIN {printf "%.2f", (overlap/total)*100}')

echo "Number of genes overlapping with '$MATCHING_STATE': $OVERLAPPING_COUNT"
echo "Percentage of total genes: $PERCENT%"
echo

# Analyze strand distribution of overlapping genes
echo "=== Strand Distribution of Overlapping Genes ==="
echo "Overlapping genes by strand:"
cut -f 6 "$OUTPUT_BED" | sort | uniq -c
echo

# Summary of results
echo "=== Summary ==="
echo "Analysis completed successfully"
echo "Results written to: $OUTPUT_BED"
echo
echo "To examine overlapping genes, use:"
echo "  head -n 5 $OUTPUT_BED    # View first 5 genes"
echo "  wc -l $OUTPUT_BED        # Count total genes"
echo "  cut -f 4 $OUTPUT_BED     # Extract gene names"
