#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <bam_file> <read_id>"
    exit 1
fi

bam_file=$1
read_id=$2

if [ ! -f "$bam_file" ]; then
    echo "Error: BAM file $bam_file does not exist"
    exit 1
fi

if ! module list 2>&1 | grep -q "samtools"; then
    echo "Loading samtools module..."
    module load samtools
fi

if ! command -v samtools &> /dev/null; then
    echo "Error: Failed to load samtools module"
    exit 1
fi

samtools view "$bam_file" | awk -v read="$read_id" '
{
    if ($1 == read) {
        # Check if paired-end using bitwise AND
        paired = ($2 + 0) % 2 ? "paired-end" : "single-end"

        # Get strand - bit 0x10 (16) indicates reverse strand
        is_reverse = (($2 + 0) % 32 >= 16)
        strand = is_reverse ? "-" : "+"

        # Calculate the length of the alignment from CIGAR string
        left_pos = $4 - 1  # Convert to 0-based
        alignment_length = 0
        n = ""
        for(i=1; i<=length($6); i++) {
            c = substr($6,i,1)
            if(c ~ /[0-9]/) n = n c
            else if(c ~ /[MDN]/) {  # These operations consume reference
                alignment_length += int(n)
                n = ""
            } else n = ""  # Reset for other operations
        }
        right_pos = left_pos + alignment_length - 1

        # Determine biological start/end based on strand
        if (is_reverse) {
            start = right_pos
            end = left_pos
        } else {
            start = left_pos
            end = right_pos
        }

        # Determine read number for paired-end
        read_num = ""
        if (paired == "paired-end") {
            read_num = (($2 + 0) % 128 >= 64) ? "/1" : "/2"
        }

        print "Read type:", paired
        print "Chromosome:", $3
        print "Genomic start:", left_pos  # Leftmost position on reference
        print "Genomic end:", right_pos   # Rightmost position on reference
        print "Biological start:", start  # 5 prime end of the read
        print "Biological end:", end      # 3 prime end of the read
        print "Name:", $1 read_num
        print "Score:", $5
        print "Strand:", strand
    }
}'
