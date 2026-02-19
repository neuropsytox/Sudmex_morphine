#!/bin/bash
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=40
#SBATCH --account=rrg-mchakrav-ab

singularity exec -B /scratch:/scratch /scratch/m/mchakrav/jrasgado/sudmexmor/analysis/fmri/container/afni.sif  3dLMEr -prefix /scratch/m/mchakrav/jrasgado/sudmexmor/analysis/fmri/Seed_based/models/M1/M1_fc_dataset_left_basal_forebrain_region_left_Pmod1.nii.gz -jobs 80 	-mask /scratch/m/mchakrav/jrasgado/sudmexmor/analysis/fmri/Seed_based/mask_registered.nii.gz         -model 'Age*Group+Batch+(1|Subj)'         -qVars 'Age'         -qVarCenters 0         -gltCode MvS 'Group : 1*Mor -1*Sham'         -dataTable @/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/fmri/code/LME_SB/datasets/fc_dataset_left_basal_forebrain_region_left_Pmod1.txt

