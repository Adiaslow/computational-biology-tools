#!/bin/bash
# Check if correct number of arguments provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <fastq_file>"
    echo
    echo "Description:"
    echo "  This script compares quality scores of two specific reads from a FASTQ file"
    echo
    echo "Arguments:"
    echo "  fastq_file - Path to the FASTQ file to analyze"
    echo
    echo "Example:"
    echo "  $0 /path/to/file.fastq"
    exit 1
fi

# Get argument
FASTQ_FILE="$1"

# Check if input file exists
if [ ! -f "$FASTQ_FILE" ]; then
    echo "Error: FASTQ file not found: $FASTQ_FILE"
    exit 1
fi

# Function to convert quality scores to numeric values and calculate average
calculate_quality_score() {
    local quality_string="$1"
    local sum=0
    local length=${#quality_string}

    for (( i=0; i<length; i++ )); do
        # Extract each character and convert from ASCII to quality score
        char="${quality_string:$i:1}"
        # Convert ASCII to decimal and subtract 33 (Phred+33 encoding)
        val=$(printf "%d" "'$char'")
        val=$((val - 33))
        sum=$((sum + val))
    done

    # Calculate average and round to two decimal places
    awk -v sum="$sum" -v len="$length" 'BEGIN {printf "%.2f", sum/len}'
}

# Extract read1 and read2 (assuming they are the first two reads in the file)
# Each read in FASTQ takes 4 lines
read1_quality=$(sed -n '4p' "$FASTQ_FILE")
read2_quality=$(sed -n '8p' "$FASTQ_FILE")

# Calculate average quality scores
read1_score=$(calculate_quality_score "$read1_quality")
read2_score=$(calculate_quality_score "$read2_quality")

# Display the reads and their quality scores
echo "Read 1:"
sed -n '1,4p' "$FASTQ_FILE"
echo "Average quality score: $read1_score"
echo
echo "Read 2:"
sed -n '5,8p' "$FASTQ_FILE"
echo "Average quality score: $read2_score"
echo

# Compare scores and determine which is higher
if (( $(echo "$read1_score > $read2_score" | bc -l) )); then
    echo "read1 has a higher quality score"
elif (( $(echo "$read2_score > $read1_score" | bc -l) )); then
    echo "read2 has a higher quality score"
else
    echo "Both reads have equal quality scores"
fi
