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
    # Store information about each read in the pair
    if (NR == 1) {
        tlen1 = sqrt($9 * $9)  # Get absolute value of TLEN field
        flag1 = $2
        pos1 = $4
    }
    else if (NR == 2) {
        tlen2 = sqrt($9 * $9)  # Get absolute value of TLEN field
        flag2 = $2
        pos2 = $4
    }
    count++

    # After processing both reads in the pair
    if (count == 2) {
        # Both TLEN values should be equal
        if (tlen1 != tlen2) {
            print "Warning: Inconsistent fragment lengths detected"
            print "Read 1 TLEN:", tlen1
            print "Read 2 TLEN:", tlen2
        }

        # Print detailed information
        print "Fragment Analysis for read pair:", read
        print "--------------------------------"
        print "Fragment length:", tlen1
        print "\nRead 1:"
        print "Position:", pos1
        print "FLAG:", flag1
        print "\nRead 2:"
        print "Position:", pos2
        print "FLAG:", flag2

        exit
    }
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
}'
