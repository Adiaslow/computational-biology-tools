#!/bin/bash
# Check if the correct number of arguments provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <bam_file> <chromosome>"
    echo
    echo "Description:"
    echo "  Counts the number of reads aligned to specified chromosome in a BAM file"
    echo
    echo "Arguments:"
    echo "  bam_file    - Path to the BAM file"
    echo "  chromosome  - Chromosome to count (e.g., chr17 or 17)"
    echo
    echo "Example:"
    echo "  $0 sample.bam chr17"
    echo "  $0 sample.bam 17"
    exit 1
fi

BAM_FILE="$1"
CHROMOSOME="$2"

# Check if input file exists
if [ ! -f "$BAM_FILE" ]; then
    echo "Error: BAM file $BAM_FILE does not exist"
    exit 1
fi

# Load samtools if not already loaded
if ! module list 2>&1 | grep -q "samtools"; then
    echo "Loading samtools module..."
    module load samtools
fi

# Check if samtools is available
if ! command -v samtools &> /dev/null; then
    echo "Error: Failed to load samtools module"
    exit 1
fi

# Add 'chr' prefix if not present
if [[ ! "$CHROMOSOME" =~ ^chr ]]; then
    CHROMOSOME="chr${CHROMOSOME}"
fi

# Count reads on specified chromosome (using grep to filter)
echo "Counting reads on ${CHROMOSOME}..."
read_count=$(samtools view "$BAM_FILE" | awk -v chr="$CHROMOSOME" '$3 == chr {count++} END {print count}')

echo "Number of reads aligned to ${CHROMOSOME}: $read_count"
