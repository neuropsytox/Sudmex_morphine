#!/bin/bash

# Dependencies: ANTs & MINC tools.

# Convert Bruker files to NIFTI using BRKRAW in BIDS format.
# Terminal window should be in the project's main folder.
# This script needs the modified antsMultivariateTemplateConstruction2.sh. You can get it here: https://github.com/GarzaLab/scripts/rodent_dbm

# USAGE
# bash rat-invivo-average.sh subject session modality. 
# I.e. bash rat-invivo-average.sh sub-5 ses-1 T1w

if [ $# -eq 0 ];then

	echo "usage: "$0" subject session modality";

	exit 0;

else

tmpdir=$(mktemp -d)
project=/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/smri/DBM_invivo/preproc
path=/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/smri/DBM_invivo

subject=$1
session=$2
modality=$3

## Create derivatives directory 
##
if [ ! -d ${project} ] ; then
mkdir -p ${project};
fi

##########################################################################
#Prepare and average volumes
##########################################################################


# Split 4D file (2 3D volumes)

if [ ! -d ${project}/${subject}/${session}/anat ] ; then
mkdir -p ${project}/${subject}/${session}/anat;
fi

ImageMath 4 ${project}/${subject}/${session}/anat/split.nii.gz TimeSeriesDisassemble ${path}/data/${subject}/${session}/anat/${subject}_${session}_${modality}.nii.gz

# Average 
${path}/code/antsMultivariateTemplateConstruction2_rigidaverage.sh -d 3 -a 0 -e 0 -n 0 -m MI -t Rigid -o ${project}/${subject}/${session}/anat/average ${project}/${subject}/${session}/anat/split*.nii.gz

cp -v ${project}/${subject}/${session}/anat/averagetemplate0.nii.gz ${project}/${subject}/${session}/anat/average.nii.gz

nii2mnc ${project}/${subject}/${session}/anat/average.nii.gz ${project}/${subject}/${session}/anat/average.mnc

# QC picture
mincpik -scale 20 -t ${project}/${subject}/${session}/anat/average.mnc ${project}/${subject}/${session}/anat/${subject}_${session}_average.jpg

rm -rf $tmpdir

fi
