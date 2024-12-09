#!/bin/bash
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <bam_file> <read_id>"
    echo
    echo "Description:"
    echo "  This script provides detailed alignment information for a specific read"
    echo "  including position, strand, CIGAR analysis, and junction detection"
    echo
    echo "Example:"
    echo "  $0 sample.bam SRR2175475.32870740"
    exit 1
fi

bam_file=$1
read_id=$2

if [ ! -f "$bam_file" ]; then
    echo "Error: BAM file $bam_file does not exist"
    exit 1
fi

# Load required modules
if ! module list 2>&1 | grep -q "samtools"; then
    echo "Loading samtools module..."
    module load samtools
fi

if ! command -v samtools &> /dev/null; then
    echo "Error: Failed to load samtools module"
    exit 1
fi

samtools view "$bam_file" | awk -v read="$read_id" '
function decode_flag(flag) {
    # Decode SAM FLAG values
    flags = ""
    if (flag + 0 == 0) return "unmapped"
    if (flag % 2) flags = flags "paired-end;"
    if (flag % 4 >= 2) flags = flags "properly paired;"
    if (flag % 8 >= 4) flags = flags "unmapped;"
    if (flag % 16 >= 8) flags = flags "mate unmapped;"
    if (flag % 32 >= 16) flags = flags "reverse strand;"
    if (flag % 64 >= 32) flags = flags "mate reverse strand;"
    if (flag % 128 >= 64) flags = flags "first in pair;"
    if (flag % 256 >= 128) flags = flags "second in pair;"
    if (flag % 512 >= 256) flags = flags "not primary;"
    if (flag % 1024 >= 512) flags = flags "fails QC;"
    if (flag % 2048 >= 1024) flags = flags "PCR/optical duplicate;"
    if (flag % 4096 >= 2048) flags = flags "supplementary;"
    return flags
}

function analyze_cigar(cigar) {
    # Analyze CIGAR string for detailed operations
    cigar_info = ""
    n = ""
    matches = 0
    deletions = 0
    insertions = 0
    splice_sites = 0

    for(i=1; i<=length(cigar); i++) {
        c = substr(cigar,i,1)
        if(c ~ /[0-9]/) n = n c
        else {
            num = int(n)
            if(c == "M") matches += num
            else if(c == "D") deletions += num
            else if(c == "I") insertions += num
            else if(c == "N") splice_sites += 1
            n = ""
        }
    }

    cigar_info = sprintf("Matches: %d, Deletions: %d, Insertions: %d, Splice junctions: %d",
                        matches, deletions, insertions, splice_sites)
    return cigar_info
}

{
    if ($1 == read) {
        print "\nAlignment Record:", NR
        print "------------------------"

        # Basic alignment info
        paired = ($2 + 0) % 2 ? "paired-end" : "single-end"
        is_reverse = (($2 + 0) % 32 >= 16)
        strand = is_reverse ? "-" : "+"

        # Position calculations
        left_pos = $4 - 1  # Convert to 0-based
        alignment_length = 0
        n = ""
        for(i=1; i<=length($6); i++) {
            c = substr($6,i,1)
            if(c ~ /[0-9]/) n = n c
            else if(c ~ /[MDN]/) {
                alignment_length += int(n)
                n = ""
            } else n = ""
        }
        right_pos = left_pos + alignment_length - 1

        # Determine biological positions
        if (is_reverse) {
            start = right_pos
            end = left_pos
        } else {
            start = left_pos
            end = right_pos
        }

        # Read number for paired-end
        read_num = ""
        if (paired == "paired-end") {
            read_num = (($2 + 0) % 128 >= 64) ? "/1" : "/2"
        }

        # Output comprehensive alignment information
        print "Read Information:"
        print "---------------"
        print "Name:", $1 read_num
        print "Type:", paired
        print "FLAG:", $2, "(" decode_flag($2) ")"
        print "Mapping Quality:", $5

        print "\nLocation Information:"
        print "-------------------"
        print "Chromosome:", $3
        print "Genomic start:", left_pos
        print "Genomic end:", right_pos
        print "Biological start (5):", start
        print "Biological end (3):", end
        print "Strand:", strand

        print "\nCIGAR Analysis:"
        print "--------------"
        print "CIGAR string:", $6
        print analyze_cigar($6)

        print "\n"
    }
}'
