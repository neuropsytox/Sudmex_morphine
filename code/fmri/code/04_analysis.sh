#!/bin/bash
#SBATCH --time=03:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=80
#SBATCH --account=rrg-mchakrav-ab

# load necessary modules
module load cobralab

path=/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/fmri
atlas_folder=/scratch/m/mchakrav/jrasgado/neuropsytox_utils/Atlas
TR=1.0
size=0.4

template=${atlas_folder}/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_InVivo_Template/SIGMA_InVivo_Brain_Template.nii
mask=${atlas_folder}/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_InVivo_Template/SIGMA_InVivo_Brain_Mask.nii
wm=${atlas_folder}/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_InVivo_Template/SIGMA_InVivo_WM_mask.nii
csf=${atlas_folder}/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_InVivo_Template/SIGMA_InVivo_CSF_mask.nii
atlas=${atlas_folder}/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Brain_Atlases/SIGMA_Anatomical_Atlas/InVivo_Atlas/SIGMA_InVivo_Anatomical_Brain_Atlas.nii

atlas_rois=${path}/Atlas/ROIs_registered2templatesmri/ROI_${size}

container=${path}/container/rabies_v051.sif

### define input/output folders ###
ses=$1

data_input=${path}/data/Session-${ses}
preproc_output=${path}/rabies/preproc_out/Session-${ses}
confound_out=${path}/rabies/confound_out/Session-${ses}
analysis_out=${path}/rabies/analysis_out/Session-${ses}
mkdir -p ${analysis_out}

### RABIES call ###
singularity run -B /scratch:/scratch -B ${data_input}:/data_input:ro -B ${atlas_folder}:/Atlas \
-B ${preproc_output}:/preproc_output -B ${confound_out}:/confound_out -B ${analysis_out}:/analysis \
${container} -p Linear \
analysis /confound_out /analysis \
--data_diagnosis \
--group_ica apply=true,dim=30,random_seed=1 \
--FC_matrix --ROI_type parcellated \
--ROI_csv ${atlas} \
--seed_list \
 ${atlas_rois}/left_brainstem_left_2_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/left_brainstem_left_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/left_corpus_callosum_and_associated_subcortical_white_matter_left_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/left_deeper_layers_of_the_superior_colliculus_left_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/left_dentate_gyrus_left_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/left_entorhinal_cortex_left_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/left_frontal_association_cortex_left_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/left_granule_cell_level_of_the_cerebellum_left_2_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/left_granule_cell_level_of_the_cerebellum_left_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/left_lateral_parietal_associative_cortex_left_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/left_molecular_layer_of_the_cerebellum_left_2_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/left_molecular_layer_of_the_cerebellum_left_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/left_olfactory_bulb_left_2_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/left_olfactory_bulb_left_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/left_pre_limbic_system_left_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/left_primary_auditory_cortex_left_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/left_primary_somatosensory_cortex_forelimb_left_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/right_brainstem_2_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/right_brainstem_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/right_entorhinal_cortex_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/right_granule_cell_level_of_the_cerebellum_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/right_middle_cerebellar_peduncle_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/right_molecular_layer_of_the_cerebellum_2_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/right_molecular_layer_of_the_cerebellum_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/right_olfactory_bulb_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/right_parietal_cortex_postero_rostral_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/right_primary_cingular_cortex_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/right_primary_somatosensory_cortex_jaw_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/right_primary_somatosensory_cortex_upperlips_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/right_primary_visual_cortex_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/right_striatum_Lmod1_peaks_sphere_bin.nii.gz \
 ${atlas_rois}/right_ventral_hippocampal_commissure_Lmod1_peaks_sphere_bin.nii.gz 

chmod -R 777 ${analysis_out}
