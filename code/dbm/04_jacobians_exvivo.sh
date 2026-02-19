#!/bin/bash

module load cobralab

path=/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/smri/DBM_invivo
jacobians=${path}/jacobians

cd ${jacobians}

${path}/code/optimized_antsMultivariateTemplateConstruction/twolevel_dbm.sh --walltime 05:00:00 \
 --jacobian-smooth 4vox,1mm ${path}/code/inputs.txt \
 --mask ${jacobians}/output/secondlevel/final/average/mask_shapeupdate.nii.gz

chmod -R 777 ${jacobians}
