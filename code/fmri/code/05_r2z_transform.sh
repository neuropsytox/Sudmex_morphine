#!/bin/bash

### The following scripts is to perform group level analysis using multivariate approach ###
###			Using longitudinal sessions of seed_based analysis		  ###
## How to use bash code/05_r2z_transform.sh ##

module load cobralab
# Setting paths
lv_path=/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/fmri
cd $lv_path

sbatch code/LME_SB/r2z_transform.sh