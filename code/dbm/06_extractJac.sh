#!/bin/bash
#SBATCH --time=1:00:00
#SBATCH --nodes=1
#SBATCH --account=rrg-mchakrav-ab

module load cobralab
### Usage example: sbatch code/06_extractJac.sh ###
smooth=$1

cd /scratch/m/mchakrav/jrasgado/sudmexmor/analysis/smri/DBM_invivo/

nii2mnc jacobians/output/secondlevel/final/average/mask_shapeupdate.nii.gz jacobians/output/secondlevel/final/average/mask_shapeupdate.mnc

cd DBM/
Rscript ../code/06_extractJac.R ${smooth}

chmod -R 777 .
