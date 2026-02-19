#!/bin/bash
#SBATCH --time=05:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=40
#SBATCH --account=rrg-mchakrav-ab

### The following scripts is to perform group level analysis using multivariate approach ###
###			Using longitudinal sessions of seed_based analysis		  ###
## How to use bash code/LME_SB/model_3dLMEr.sh ##

module load cobralab
# Setting paths
path=/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/fmri
atlas_folder=/scratch/m/mchakrav/jrasgado/neuropsytox_utils/Atlas/
path_atlas=/scratch/m/mchakrav/jrasgado/neuropsytox_utils
ROIs_reg_folder=${path}/Atlas/
container=${path}/container/afni.sif

Template_fmri=${path}/Atlas/template_sharpen_shapeupdate_brain.nii.gz
Template_mask=${path}/../smri/DBM_invivo/DBM/tomodel/atlas_mask_registered.nii.gz

Maps_template=${path}/rabies/preproc_out/Session-T3/bold_datasink/commonspace_labels/_scan_info_subject_id042.sessionT3_split_name_sub-042_ses-T3_T2w/_run_None/sub-042_ses-T3_task-rest_bold_RAS_EPI_anat_labels.nii.gz
Maps_mask=${path}/../smri/DBM_invivo/jacobians/output/secondlevel/final/average/mask_shapeupdate.nii.gz

if [ ! -f ${ROIs_reg_folder}/maps_registered0GenericAffine.mat ]; then

 antsRegistration_affine_SyN.sh \
    --float \
    --clobber \
    --moving-mask ${Maps_mask} \
    --fixed-mask ${Template_mask} \
    ${Maps_template} \
    ${Template_fmri} \
    ${ROIs_reg_folder}/maps_registered

else

 echo "antsRegistration prepared"

fi

for i in $(ls ${path}/Seed_based/Clusterize_maps/uncorrected/M1_fc_dataset*/__*/olay_clust_reset_thr.nii); do

    roi=${i%.*}_registered.mnc
    
    if [ ! -f ${roi} ]; then  

    antsApplyTransforms -d 3 -i ${i} -t ${ROIs_reg_folder}/maps_registered0GenericAffine.mat \
    -t ${ROIs_reg_folder}/maps_registered1InverseWarp.nii.gz \
    -r ${Template_fmri} \
    -o ${i%.*}_registered.nii.gz -n GenericLabel --verbose

    #nii2mnc ${i%.*}_registered.nii.gz ${roi}

    else

    echo "rois already in atlas space (rabies output)"

    fi

done
