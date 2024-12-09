#!/bin/bash
# Check if enough arguments
if [ "$#" -lt 3 ]; then
   echo "Usage: $0 <vcf_file> <sample_id> <snp_id1> [snp_id2 ...]"
   exit 1
fi

# Check if bcftools module is loaded
if ! module list 2>&1 | grep -q "bcftools"; then
    echo "Loading bcftools module..."
    module load bcftools
fi

# Check if module load was successful
if ! command -v bcftools &> /dev/null; then
    echo "Error: Failed to load bcftools module"
    exit 1
fi

vcf_file=$1
shift
sample=$1
shift

# Check if VCF file exists
if [ ! -f "$vcf_file" ]; then
    echo "Error: VCF file $vcf_file does not exist"
    exit 1
fi

printf "%s\n" "$@" > snps.txt
bcftools view -s "$sample" -i 'ID=@snps.txt' "$vcf_file" | \
awk -F'\t' '
!/^#/ {
   ref=$4; alt=$5; gt=$10;
   split(gt,g,"|");
   allele1 = (g[1]=="0" ? ref : alt);
   allele2 = (g[2]=="0" ? ref : alt);
   hap1[FNR]=allele1;
   hap2[FNR]=allele2;
}
END {
   printf "Haplotype 1: ";
   for(i=1;i<=FNR;i++) printf "%s", hap1[i];
   printf "\nHaplotype 2: ";
   for(i=1;i<=FNR;i++) printf "%s", hap2[i];
   printf "\n";
}'
rm snps.txt
