#!/bin/bash
#SBATCH --time=18:00:00
#SBATCH --nodes=2
#SBATCH --ntasks=50
#SBATCH --account=rrg-mchakrav-ab

### Usage example: sbatch code/02_rat_preproc.sh T1 sub-* ###

module load cobralab/2019b
module load  minc-toolkit-extras
#module load eigen/3.3.7
#module load fftw/3.3.8
#module load mrtrix/3.0.0

export PSILANTRO_PATH=/scratch/m/mchakrav/dangeles/PSILANTRO

ses=$1
sub=$2
path=/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/smri/DBM_invivo
input=${path}/data
preproc=${path}/preproc

for i in $(ls -d ${preproc}/${sub}); do 

 mkdir -p ${preproc}/$(basename $i)/ses-${ses}/anat/

 bash ${path}/code/rat-preprocessing-v7.sh \
  ${preproc}/$(basename $i)/ses-${ses}/anat/average.mnc \
  ${preproc}/$(basename $i)/ses-${ses}/anat/$(basename $i)_ses-${ses}_pp.mnc

 mnc2nii -nii ${preproc}/$(basename $i)/ses-${ses}/anat/$(basename $i)_ses-${ses}_pp.mnc \
  ${preproc}/$(basename $i)/ses-${ses}/anat/$(basename $i)_ses-${ses}_pp.nii

 mincpik -scale 20 -t ${preproc}/$(basename $i)/ses-${ses}/anat/$(basename $i)_ses-${ses}_pp.mnc \
  ${preproc}/$(basename $i)/ses-${ses}/anat/$(basename $i)_ses-${ses}_pp.jpg

 chmod -R 777 ${preproc}/

done
