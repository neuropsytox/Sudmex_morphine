#!/bin/bash
#SBATCH --time=15:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=80
#SBATCH --account=rrg-mchakrav-ab

# load necessary modules
module load cobralab

path=/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/fmri
atlas_folder=/scratch/m/mchakrav/jrasgado/neuropsytox_utils/Atlas/

#template=${atlas_folder}/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Functional_Imaging/SIGMA_EPI_Brain_Template_Masked.nii
#mask=${atlas_folder}/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Functional_Imaging/SIGMA_EPI_Brain_Mask.nii
#wm=${atlas_folder}/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Functional_Imaging/SIGMA_EPI_WM_bin.nii.gz
#csf=${atlas_folder}/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Functional_Imaging/SIGMA_EPI_CSF_bin.nii.gz
#atlas=${atlas_folder}/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Brain_Atlases/SIGMA_Functional_Atlas/SIGMA_Functional_Brain_Atlas_Functional_Template.nii

template=${atlas_folder}/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_InVivo_Template/SIGMA_InVivo_Brain_Template.nii
mask=${atlas_folder}/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_InVivo_Template/SIGMA_InVivo_Brain_Mask.nii
wm=${atlas_folder}/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_InVivo_Template/SIGMA_InVivo_WM_mask.nii
csf=${atlas_folder}/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_InVivo_Template/SIGMA_InVivo_CSF_mask.nii
atlas=${atlas_folder}/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Brain_Atlases/SIGMA_Anatomical_Atlas/InVivo_Atlas/SIGMA_InVivo_Anatomical_Brain_Atlas.nii
#atlas=${atlas_folder}/Mask_erode.nii
#atlas=${atlas_folder}/ROI_fmri_mask.nii

TR=1.0

container=${path}/container/rabies_v051.sif

#define input/output folders
ses=$1

data_input=${path}/data/Session-${ses}
preproc_output=${path}/rabies/preproc_out/Session-${ses}
mkdir -p ${preproc_output}

#RABIES call 
singularity run -B /scratch:/scratch -B ${atlas_folder}:/Atlas -B ${data_input}:/data_input:ro -B ${preproc_output}:/preproc_output \
${container} -p MultiProc --scale_min_memory 10.0 --local_threads 80 \
preprocess /data_input /preproc_output \
--anat_template ${template} \
--brain_mask ${mask} \
--WM_mask ${wm} \
--CSF_mask ${csf} \
--vascular_mask ${csf} \
--labels ${atlas} \
--TR ${TR}s \
--commonspace_resampling 0.3x0.3x0.3 \
--commonspace_reg masking=false,brain_extraction=false,template_registration=SyN,fast_commonspace=true \
--anat_inho_cor method=disable,otsu_thresh=2,multiotsu=false \
--HMC_option 2 \
--tpattern seq-z \
--anat_autobox 

chmod -R 777 ${preproc_output}
