#!/bin/bash

### The following scripts is to perform group level analysis using multivariate approach ###
###			Using longitudinal sessions of seed_based analysis		  ###
## How to use bash code/LME_SB/model_3dLMEr.sh ##

module load cobralab
# Setting paths
lv_path=/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/fmri
path=/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/fmri

atlas_model=${path}/../../analysis/smri/DBM_invivo/DBM/tomodel/atlas_labels_registered.nii.gz
cd $lv_path

Rscript code/LME_SB/arranging_dataset.R

if [ ! -f ${path}/Seed_based/mask_registered.nii.gz ]; then

 echo "sending mask to subjects space"

 antsRegistration_affine_SyN.sh \
  --float --fast \
  --clobber \
  ${atlas_model} \
  ${path}/rabies/preproc_out/Session-T3/bold_datasink/commonspace_labels/_scan_info_subject_id042.sessionT3_split_name_sub-042_ses-T3_T2w/_run_None/sub-042_ses-T3_task-rest_bold_RAS_EPI_anat_labels.nii.gz \
  ${path}/Seed_based/mask_registered

 antsApplyTransforms -d 3 -i ${atlas_model} -t ${path}/Seed_based/mask_registered0GenericAffine.mat \
  -t ${path}/Seed_based/mask_registered1InverseWarp.nii.gz \
  -r ${path}/rabies/preproc_out/Session-T3/bold_datasink/commonspace_labels/_scan_info_subject_id042.sessionT3_split_name_sub-042_ses-T3_T2w/_run_None/sub-042_ses-T3_task-rest_bold_RAS_EPI_anat_labels.nii.gz \
  -o ${path}/Seed_based/mask_registered.nii.gz -n GenericLabel --verbose

else

 echo "mask already in subjects space"

fi

bash code/LME_SB/model_3dLMEr.sh
