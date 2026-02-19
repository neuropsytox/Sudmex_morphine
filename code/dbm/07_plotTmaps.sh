#!/bin/bash
#SBATCH --time=1:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --account=rrg-mchakrav-ab

module load cobralab
### Usage example: sbatch code/07_plotTmaps.sh smooth###
smooth=$1

path=/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/smri/DBM_invivo
cd $path

if [ ! -f ${path}/DBM/tomodel/template_sharpen_shapeupdate_brain.mnc ]; then

 echo "sending template to atlas space"
fslmaths ${path}/jacobians/output/secondlevel/final/average/template_sharpen_shapeupdate.nii.gz \
 -mul ${path}/jacobians/output/secondlevel/final/average/mask_shapeupdate.nii.gz \
 ${path}/DBM/tomodel/template_sharpen_shapeupdate_brain.nii.gz

nii2mnc ${path}/DBM/tomodel/template_sharpen_shapeupdate_brain.nii.gz \
    ${path}/DBM/tomodel/template_sharpen_shapeupdate_brain.mnc

else

 echo "template already extracted"

fi  

Rscript code/07_plotTmaps.R ${smooth} --save
