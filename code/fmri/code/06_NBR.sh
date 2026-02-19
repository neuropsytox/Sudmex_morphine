#!/bin/bash
#SBATCH --time=23:59:00
#SBATCH --account=rrg-mchakrav-ab

# load necessary modules
module load cobralab
mod=$1 #example sbatch <<script>> mod1

path=/scratch/m/mchakrav/jrasgado/sudmex_alc_stress/analysis/fmri

Rscript ${path}/code/NBR/nbr_${mod}.R

chmod -R 777 ${path}/NBR
