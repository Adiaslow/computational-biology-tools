#!/bin/bash
# Check if correct number of arguments provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <abundance.tsv> <gene_name>"
    echo
    echo "Description:"
    echo "  Calculate total gene expression (TPM) from Kallisto abundance output"
    echo
    echo "Arguments:"
    echo "  abundance.tsv - Kallisto abundance.tsv output file"
    echo "  gene_name    - Name of gene to analyze (e.g., HEATR6)"
    echo
    echo "Example:"
    echo "  $0 abundance.tsv HEATR6"
    exit 1
fi

ABUNDANCE_FILE="$1"
GENE_NAME="$2"

# Check if input file exists
if [ ! -f "$ABUNDANCE_FILE" ]; then
    echo "Error: Kallisto abundance file not found: $ABUNDANCE_FILE"
    exit 1
fi

# Sum TPM values for the specified gene with full precision
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
        # Print with full precision
        print sum
    }
' "$ABUNDANCE_FILE")

# Check if any matches were found
if [ -z "$tpm_sum" ] || [ "$tpm_sum" == "0" ]; then
    echo "Warning: No matches found for gene '$GENE_NAME'"
    exit 1
else
    # Show the individual transcript values for verification
    echo -e "\nIndividual transcript TPM values:"
    awk -v gene="$GENE_NAME" '
        NR > 1 {
            if ($1 ~ gene) {
                print "Transcript:", $1
                print "TPM:", $5
                print "---"
            }
        }
    ' "$ABUNDANCE_FILE"
    echo "Gene: $GENE_NAME"
    echo "Total Expression (TPM): $tpm_sum"
fi
