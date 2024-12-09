#!/bin/bash
# Check if correct number of arguments provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <bam_file> <read_name>"
    echo
    echo "Description:"
    echo "  Calculates the fragment length for a specific paired-end read from a BAM file"
    echo
    echo "Arguments:"
    echo "  bam_file   - Path to the BAM file"
    echo "  read_name  - Name of the read pair to analyze"
    echo
    echo "Example:"
    echo "  $0 sample.bam SRR2175475.35069651"
    exit 1
fi

BAM_FILE="$1"
READ_NAME="$2"

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

# Extract fragment length information using awk
samtools view "$BAM_FILE" | awk -v read="$READ_NAME" '
$1 == read {
    # Store all values in arrays indexed by FLAG
    tlen[$2] = sqrt($9 * $9)  # absolute value of TLEN
    pos[$2] = $4
    flags[$2] = $2
    count++
}
END {
    if (count == 0) {
        print "Error: Read pair not found in BAM file"
        exit 1
    }
    else if (count == 1) {
        print "Error: Only one read of the pair found"
        exit 1
    }

    # Print fragment analysis
    print "Fragment Analysis for read pair:", read
    print "--------------------------------"

    # Find the reads (first in pair has FLAG & 64, second has FLAG & 128)
    for (f in flags) {
        if (and(f, 64)) {  # First read in pair
            read1_flag = f
            read1_pos = pos[f]
            read1_tlen = tlen[f]
        }
        if (and(f, 128)) {  # Second read in pair
            read2_flag = f
            read2_pos = pos[f]
            read2_tlen = tlen[f]
        }
    }

    print "Fragment length:", read1_tlen
    print "\nRead 1:"
    print "Position:", read1_pos
    print "FLAG:", read1_flag
    print "\nRead 2:"
    print "Position:", read2_pos
    print "FLAG:", read2_flag
}'
