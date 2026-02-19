#!/bin/bash
#SBATCH --time=10:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=80
#SBATCH --account=rrg-mchakrav-ab

module load cobralab

size=$1

path=/scratch/m/mchakrav/jrasgado/sudmexmor/analysis
ROIs_folder=${path}/fmri/Atlas/ROIs
mkdir -p $ROIs_folder
ROIs_path=${path}/fmri/Atlas/ROIs/ROI_${size}

Template_smri=${path}/smri/DBM_invivo/DBM/tomodel/template_sharpen_shapeupdate_brain.nii.gz
cp $Template_smri ${path}/fmri/Atlas/
Template_fmri=${path}/fmri/Atlas/template_sharpen_shapeupdate_brain.nii.gz
ras2voxel=6.09 # change this value to the one in your template
ras2voxel_x=59.5
ras2voxel_y=95.5
ras2voxel_z=41.5

mkdir -p ${ROIs_path}

CELESTE="\e[;36m"
RESET='\e[0m'
YELLOW='\e[33m'

echo -e "${YELLOW} ## Creating ROIs based on smri in-vivo results ## ${RESET}"
	
vector_x=$(cut -d ',' -f 4 ${path}/smri/DBM_invivo/DBM/smooth_1mm/Trayectories/ROIs.csv)
vector_y=$(cut -d ',' -f 5 ${path}/smri/DBM_invivo/DBM/smooth_1mm/Trayectories/ROIs.csv)
vector_z=$(cut -d ',' -f 6 ${path}/smri/DBM_invivo/DBM/smooth_1mm/Trayectories/ROIs.csv)
vector_names=$(cut -d ',' -f 11 ${path}/smri/DBM_invivo/DBM/smooth_1mm/Trayectories/ROIs.csv)

nrow=$(cat ${path}/smri/DBM_invivo/DBM/smooth_1mm/Trayectories/ROIs.csv | wc -l)

for i in $(seq 2 ${nrow} ); do

names_o=$(echo $vector_names | cut -d ' ' -f $i)
echo -e "${CELESTE} $names_o ${RESET}"

if [ -f ${ROIs_path}/${names_o}_sphere_bin_tagged.nii.gz ]; then
    echo "Seed already created"
else
    echo -e "## Converting mm2RAS ##"
    x_o=$(echo $vector_x | cut -d ' ' -f $i)
    y_o=$(echo $vector_y| cut -d ' ' -f $i)
    z_o=$(echo $vector_z | cut -d ' ' -f $i)

    x=`echo "${x_o} * (${ras2voxel}) + ${ras2voxel_x}" | bc`
    y=`echo "${y_o} * (${ras2voxel}) + ${ras2voxel_y}" | bc`
    z=`echo "${z_o} * (${ras2voxel}) + ${ras2voxel_z}" | bc`

    echo -e "## Rounding ##"
    round_x=$(printf "%.${precision}f" $x)
    round_y=$(printf "%.${precision}f" $y)
    round_z=$(printf "%.${precision}f" $z)

    echo -e "## Creating the ROIs ##"

    echo fslmaths $Template_fmri -mul 0 -add 1 -roi $x_o 1 $y_o 1 $z_o 1 0 1 ${ROIs_path}/${names_o} -odt float
    echo fslmaths $Template_fmri -mul 0 -add 1 -roi $round_x 1 $round_y 1 $round_z 1 0 1 ${ROIs_path}/${names_o} -odt float

    fslmaths $Template_fmri -mul 0 -add 1 -roi $round_x 1 $round_y 1 $round_z 1 0 1 ${ROIs_path}/${names_o} -odt float

    echo -e "## Inflate to an sphere ##"
    fslmaths ${ROIs_path}/${names_o} -kernel sphere ${size} -fmean ${ROIs_path}/${names_o}_sphere -odt float

    fslmaths ${ROIs_path}/${names_o}_sphere -bin ${ROIs_path}/${names_o}_sphere_bin 

    fslmaths ${ROIs_path}/${names_o}_sphere_bin -mul ${i} ${ROIs_path}/${names_o}_sphere_bin_tagged
fi

done

## Select only the ROIs for NBR ##
# fslmaths ${Template_fmri} -mul 0 ${ROIs_folder}/ROI_fmri_mask_${size}
# for i in $(cat ${ROIs_folder}/rois_seed.txt); do fslmaths ${ROIs_folder}/ROI_fmri_mask_${size}.nii.gz \
#  -add ${ROIs_path}/${i}_sphere_bin_tagged.nii.gz ${ROIs_folder}/ROI_fmri_mask_${size}.nii.gz ; done

# chmod -R 777 ${ROIs_path}

# Registering to rabies output using ants

ROIs_reg_folder=${path}/fmri/Atlas/ROIs_registered2templatesmri
ROIs_reg_path=${path}/fmri/Atlas/ROIs_registered2templatesmri/ROI_${size}
mkdir -p $ROIs_reg_path

template_mask=${path}/smri/DBM_invivo/jacobians/output/secondlevel/final/average/mask_shapeupdate.nii.gz

path_atlas=/scratch/m/mchakrav/jrasgado/neuropsytox_utils
atlas_model=${path_atlas}/Atlas/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_InVivo_Template/SIGMA_InVivo_Brain_Template.nii
atlas_masked=${path_atlas}/Atlas/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_InVivo_Template/SIGMA_InVivo_Brain_Template_Masked.nii
atlas_mask=${path_atlas}/Atlas/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_InVivo_Template/SIGMA_InVivo_Brain_Mask.nii

if [ ! -f ${ROIs_reg_folder}/template_update_registered.mnc ]; then 

antsRegistration_affine_SyN.sh \
--float \
--clobber \
--moving-mask ${template_mask} \
--fixed-mask ${atlas_mask} \
${Template_fmri} \
${atlas_model} \
${ROIs_reg_folder}/rois_registered

antsApplyTransforms -d 3 -i ${Template_fmri} -t ${ROIs_reg_folder}/rois_registered0GenericAffine.mat \
-t ${ROIs_reg_folder}/rois_registered1InverseWarp.nii.gz \
-r ${atlas_model} \
-o ${ROIs_reg_folder}/template_update_registered -n GenericLabel --verbose

nii2mnc ${ROIs_reg_folder}/template_update_registered.nii.gz ${ROIs_reg_folder}/template_update_registered.mnc

else

echo "warp in atlas space (rabies output)"

fi

for i in $(ls ${ROIs_path}/*_sphere_bin.nii.gz); do

    roi=$(basename ${i})
    echo $i

    if [ ! -f ${ROIs_reg_path}/${roi%.*}.mnc ]; then  

    antsApplyTransforms -d 3 -i ${i} -t ${ROIs_reg_folder}/rois_registered0GenericAffine.mat \
    -t ${ROIs_reg_folder}/rois_registered1InverseWarp.nii.gz \
    -r ${atlas_model} \
    -o ${ROIs_reg_path}/${roi} -n GenericLabel --verbose

    nii2mnc ${ROIs_reg_path}/${roi} ${ROIs_reg_path}/${roi%.*}.mnc

    else

    echo "rois already in atlas space (rabies output)"

    fi

done
