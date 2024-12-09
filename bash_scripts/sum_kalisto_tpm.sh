#!/bin/bash

# Check if correct number of arguments provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <kallisto_abundance.tsv> <gene_name>"
    echo
    echo "Description:"
    echo "  This script sums TPM values for a specified gene from Kallisto output"
    echo
    echo "Arguments:"
    echo "  kallisto_abundance.tsv - Kallisto abundance.tsv output file"
    echo "  gene_name              - Name of gene to analyze"
    echo
    echo "Example:"
    echo "  $0 abundance.tsv RNFT1"
    exit 1
fi

# Get arguments
ABUNDANCE_FILE="$1"
GENE_NAME="$2"

# Check if input file exists
if [ ! -f "$ABUNDANCE_FILE" ]; then
    echo "Error: Kallisto abundance file not found: $ABUNDANCE_FILE"
    exit 1
fi

# Sum TPM values for the specified gene and round to nearest whole number
tpm_sum=$(awk -v gene="$GENE_NAME" '
    # Skip header line
    NR > 1 {
        # If target contains gene name
        if ($1 ~ gene) {
            # Add TPM value (assumes TPM is in 5th column)
            sum += $5
        }
    }
    END {
        # Round to nearest whole number
        printf "%.0f\n", sum
    }
' "$ABUNDANCE_FILE")

# Check if any matches were found
if [ -z "$tpm_sum" ] || [ "$tpm_sum" == "0" ]; then
    echo "Warning: No matches found for gene '$GENE_NAME' in file"
    exit 1
else
    echo "Gene name: $GENE_NAME"
    echo "Total TPM (rounded): $tpm_sum"
fi
