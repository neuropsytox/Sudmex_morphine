#!/bin/bash

### The following scripts is to perform group level analysis using multivariate approach ###
###			Using longitudinal sessions of seed_based analysis		  ###
## How to use bash code/LME_SB/model_3dLMEr.sh ##

module load cobralab
# Setting paths
path=/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/fmri
atlas_folder=/scratch/m/mchakrav/jrasgado/neuropsytox_utils/Atlas/
template=${atlas_folder}/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_ExVivo_Template/SIGMA_ExVivo_Brain_Template_Masked.nii

container=${path}/container/afni.sif

cd $path

for i in $(cat ${path}/Seed_based/significative_rois.txt)
    do 
    file=$(basename $i).nii.gz
    roi=${file%.*.*}
    singularity exec -B /scratch:/scratch ${container} \
    @chauffeur_afni -ulay ${template} \
        -box_focus_slices AMASK_FOCUS_ULAY -olay ${path}/Seed_based/models/M1/${file} \
        -cbar Reds_and_Blues_Inv -ulay_range 0% 100% -func_range 3 \
        -set_subbricks 0 4 5 -clusterize "-NN 1 -clust_nvox 1" \
        -thr_olay_p2stat 0.000003 -thr_olay_pside bisided -olay_alpha Yes \
        -olay_boxed Yes -opacity 2 -prefix ${path}/Seed_based/Clusterize_maps/fdr/${roi}/output \
        -set_xhairs OFF -montx 4 -monty 4 -label_mode OFF -no_clean
done
