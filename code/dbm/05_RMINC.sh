#!/bin/bash
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=80
#SBATCH --account=rrg-mchakrav-ab

module load cobralab
### Usage example: sbatch code/05_RMINC.sh smooth###

path=/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/smri/DBM_invivo
path_atlas=/scratch/m/mchakrav/jrasgado/neuropsytox_utils
atlas_model=${path_atlas}/Atlas/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_InVivo_Template/SIGMA_InVivo_Brain_Template.nii
atlas_masked=${path_atlas}/Atlas/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_InVivo_Template/SIGMA_InVivo_Brain_Template_Masked.nii
atlas_mask=${path_atlas}/Atlas/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_InVivo_Template/SIGMA_InVivo_Brain_Mask.nii
atlas_label=${path_atlas}/Atlas/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Brain_Atlases/SIGMA_Anatomical_Atlas/InVivo_Atlas/SIGMA_InVivo_Anatomical_Brain_Atlas.nii
template_model=${path}/jacobians/output/secondlevel/final/average/template_sharpen_shapeupdate.nii.gz
template_mask=${path}/jacobians/output/secondlevel/final/average/mask_shapeupdate.nii.gz
smooth=$1
mkdir -p ${path}/DBM/tomodel
cd ${path}/DBM

if [ ! -f ${path}/DBM/tomodel/atlas_registered.mnc ]; then

 echo "sending template to atlas space"

 antsRegistration_affine_SyN.sh \
  --float \
  --clobber \
  --moving-mask ${atlas_mask} \
  --fixed-mask ${template_mask} \
  ${atlas_model} \
  ${template_model} \
  ${path}/DBM/tomodel/atlas_registered

 antsApplyTransforms -d 3 -i ${atlas_model} -t ${path}/DBM/tomodel/atlas_registered0GenericAffine.mat \
  -t ${path}/DBM/tomodel/atlas_registered1InverseWarp.nii.gz \
  -r ${template_model} \
  -o ${path}/DBM/tomodel/atlas_registered.nii.gz -n GenericLabel --verbose

 nii2mnc ${path}/DBM/tomodel/atlas_registered.nii.gz \
  ${path}/DBM/tomodel/atlas_registered.mnc

else

 echo "template and mask already in atlas space"

fi

if [ ! -f ${path}/DBM/tomodel/atlas_mask_registered.mnc ]; then

 echo "sending template mask to atlas space"

 antsApplyTransforms -d 3 -i ${atlas_mask} -t ${path}/DBM/tomodel/atlas_registered0GenericAffine.mat \
  -t ${path}/DBM/tomodel/atlas_registered1InverseWarp.nii.gz \
  -r ${template_model} \
  -o ${path}/DBM/tomodel/atlas_mask_registered.nii.gz -n GenericLabel --verbose

 nii2mnc ${path}/DBM/tomodel/atlas_mask_registered.nii.gz \
  ${path}/DBM/tomodel/atlas_mask_registered.mnc

else

 echo "mask already in atlas space"

fi

if [ ! -f ${path}/DBM/tomodel/atlas_labels_registered.mnc ]; then

 echo "sending labels mask to atlas space"

 antsApplyTransforms -d 3 -i ${atlas_label} -t ${path}/DBM/tomodel/atlas_registered0GenericAffine.mat \
  -t ${path}/DBM/tomodel/atlas_registered1InverseWarp.nii.gz \
  -r ${template_model} \
  -o ${path}/DBM/tomodel/atlas_labels_registered.nii.gz -n GenericLabel --verbose

 nii2mnc ${path}/DBM/tomodel/atlas_labels_registered.nii.gz \
  ${path}/DBM/tomodel/atlas_labels_registered.mnc

else

 echo "template and mask already in atlas space"

fi

if [ ${smooth} == "none" ]; then
  echo "running conversion without smoothing"
  mkdir -p ${path}/DBM/smooth_${smooth}

  sed 's/\/smooth//g; s/_fwhm_4vox//g' ${path}/DBM/data/DBM_dataset.csv >> ${path}/DBM/data/DBM_dataset_${smooth}.csv
  for i in ${path}/jacobians/output/secondlevel/resampled-dbm/jacobian/relative/sub-*.nii.gz ; do

  id=$(basename ${i} .nii.gz)
  dir_path=$(dirname ${i})
  
 if [ ! -f ${dir_path}/${id}.mnc ]; then

  echo "converting nifti files to minc"
  nii2mnc ${i} ${dir_path}/${id}.mnc

 else

  echo " ${id} already in minc"

 fi
  done
  
  Rscript ../code/05_RMINC.R ${smooth} --save
  for i in $(ls -d smooth_${smooth}/tmaps/*mnc); do su=$(basename $i .mnc); mnc2nii -nii $i smooth_${smooth}/tmaps/${su}.nii.gz; done

else
  
  echo "running conversion with ${smooth} of smoothing"
  mkdir -p ${path}/DBM/smooth_${smooth}
  sed "s/4vox/$smooth/g" ${path}/DBM/data/DBM_dataset.csv >> ${path}/DBM/data/DBM_dataset_${smooth}.csv
  for i in ${path}/jacobians/output/secondlevel/resampled-dbm/jacobian/relative/smooth/sub-*${smooth}.nii.gz ; do

  id=$(basename ${i} .nii.gz)
  dir_path=$(dirname ${i})
  
 if [ ! -f ${dir_path}/${id}.mnc ]; then

  echo "converting nifti files to minc"
  nii2mnc ${i} ${dir_path}/${id}.mnc

 else

  echo " ${id} already in minc"

 fi

  done
  
  Rscript ../code/05_RMINC.R ${smooth} --save
  for i in $(ls -d smooth_${smooth}/tmaps/*mnc); do su=$(basename $i .mnc); mnc2nii -nii $i smooth_${smooth}/tmaps/${su}.nii.gz; done

fi


chmod 777 -R ${path}/DBM
