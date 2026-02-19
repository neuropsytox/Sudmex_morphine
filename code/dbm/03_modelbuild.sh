#!/bin/bash

module load cobralab

export QBATCH_CHUNKSIZE=8
export QBATCH_CORES=80
export QBATCH_NODES=1

path=/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/smri/DBM_invivo
atlas_model=/scratch/m/mchakrav/jrasgado/sudmex_alcohol_rat/Atlas/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_InVivo_Template/SIGMA_InVivo_Brain_Template_Masked.nii
atlas_mask=/scratch/m/mchakrav/jrasgado/sudmex_alcohol_rat/Atlas/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_InVivo_Template/SIGMA_InVivo_Brain_Mask.nii
jacobians=${path}/jacobians
mkdir -p ${jacobians}

cd ${jacobians}

# Define the path to the output file to check for
output_file=${jacobians}/output/secondlevel/final-target/to_target_1Warp.nii.gz

# Loop until the output file exists
while [ ! -f $output_file ]
do

${path}/code/optimized_antsMultivariateTemplateConstruction/twolevel_modelbuild.sh ${path}/code/inputs.txt \
 --walltime-nonlinear 04:00:00 \
 --masks ${path}/code/inputs_mask.txt \
 --iterations 2 \
 --starting-target \
 ${atlas_model} \
 --starting-target-mask \
 ${atlas_mask} 

echo "sleeping"
sleep 4h # Sleep for a while before submitting again (adjust as needed)

done
chmod -R 777 ${jacobians}
