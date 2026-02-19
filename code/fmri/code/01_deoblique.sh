#!/bin/bash
#SBATCH --time=20:00:00
#SBATCH --nodes=1
#SBATCH --account=rrg-mchakrav-ab

module load cobralab

# Reading variables
base=/scratch/m/mchakrav/jrasgado/sudmexmor/
path=/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/fmri
container=${path}/container/afni.sif

cd ${base}/BIDS/in_vivo

read -p "which session do you want to run? (i.e. T5): " session
read -p "which subject do you want to run? (i.e. sub-42): " subject

for i in $(ls -d ${subject}/ses-${session}); do 
 sub=$(dirname $i)
 ses=$(basename $i)
 
 mkdir -p ${path}/data/Session-${session}/${sub}/${ses}/anat
 cp -r ${base}/analysis/smri/DBM_invivo/preproc/${sub}/${ses}/anat/${sub}_${ses}_pp.mnc ${path}/data/Session-${session}/${sub}/${ses}/anat/
 cp -r ${i}/anat/${sub}_${ses}_run-02_T2w.json ${path}/data/Session-${session}/${sub}/${ses}/anat/

 mnc2nii -nii ${path}/data/Session-${session}/${sub}/${ses}/anat/${sub}_${ses}_pp.mnc \
  ${path}/data/Session-${session}/${sub}/${ses}/anat/${sub}_${ses}_pp.nii.gz
 mv ${path}/data/Session-${session}/${sub}/${ses}/anat/${sub}_${ses}_pp.nii.gz \
  ${path}/data/Session-${session}/${sub}/${ses}/anat/${sub}_${ses}_run-02_T2w.nii.gz
 rm ${path}/data/Session-${session}/${sub}/${ses}/anat/${sub}_${ses}_pp.mnc

 mkdir -p ${path}/data/Session-${session}/${sub}/${ses}/func
 cp -r ${i}/func/${sub}_${ses}_task-rest_run-01_bold.nii.gz ${path}/data/Session-${session}/${sub}/${ses}/func/
 cp -r ${i}/func/${sub}_${ses}_task-rest_run-01_bold.json ${path}/data/Session-${session}/${sub}/${ses}/func

 singularity exec -B /scratch:/scratch ${container} 3dWarp -oblique2card \
  -prefix ${path}/data/Session-${session}/${sub}/${ses}/anat/${sub}_${ses}_run-02_T2w_do.nii.gz \
  ${path}/data/Session-${session}/${sub}/${ses}/anat/${sub}_${ses}_run-02_T2w.nii.gz
 rm  ${path}/data/Session-${session}/${sub}/${ses}/anat/${sub}_${ses}_run-02_T2w.nii.gz
 mv ${path}/data/Session-${session}/${sub}/${ses}/anat/${sub}_${ses}_run-02_T2w_do.nii.gz \
  ${path}/data/Session-${session}/${sub}/${ses}/anat/${sub}_${ses}_run-02_T2w.nii.gz

 singularity exec -B /scratch:/scratch ${container} 3dWarp -oblique2card \
  -prefix ${path}/data/Session-${session}/${sub}/${ses}/func/${sub}_${ses}_task-rest_run-01_bold_do.nii.gz \
  ${path}/data/Session-${session}/${sub}/${ses}/func/${sub}_${ses}_task-rest_run-01_bold.nii.gz
 rm ${path}/data/Session-${session}/${sub}/${ses}/func/${sub}_${ses}_task-rest_run-01_bold.nii.gz
 mv ${path}/data/Session-${session}/${sub}/${ses}/func/${sub}_${ses}_task-rest_run-01_bold_do.nii.gz \
  ${path}/data/Session-${session}/${sub}/${ses}/func/${sub}_${ses}_task-rest_run-01_bold.nii.gz

done

chmod -R 777 ${path}/data
