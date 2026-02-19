#!/bin/bash
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --account=rrg-mchakrav-ab

bids=/scratch/m/mchakrav/jrasgado/sudmexmor/Bids
path=/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/smri/DBM_invivo
input=${path}/data

for ses in T1 T2 T3 T5; do
 for i in ${bids}/sub-*; do 
  mkdir -p ${input}/$(basename $i)/ses-${ses}/anat/

  cp -r ${i}/ses-${ses}/anat/* ${input}/$(basename $i)/ses-${ses}/anat/
  
  rm -d ${input}/$(basename $i)/ses-${ses}/anat
  rm -d ${input}/$(basename $i)/ses-${ses}/
  rm -d ${input}/$(basename $i)/

  chmod -R 777 ${input}/

 done
done
