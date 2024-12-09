#!/bin/bash

# Check if enough arguments
if [ "$#" -lt 2 ]; then
   echo "Usage: $0 <sample_id> <snp_id1> [snp_id2 ...]"
   exit 1
fi

sample=$1
shift
printf "%s\n" "$@" > snps.txt

bcftools view -s "$sample" -i 'ID=@snps.txt' /hb/groups/bme110/fall2024/problemSet5/ALL.chr21.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf | \
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
