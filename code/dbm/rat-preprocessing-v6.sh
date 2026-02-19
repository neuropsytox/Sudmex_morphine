#!/bin/bash
#Preprocessing script for rat brains, using Fischer template and MINC files


set -euo pipefail
set -x

calc(){ awk "BEGIN { print "$*" }"; }

tmpdir=$(mktemp -d)

input=$1
output=$2

minimum_resolution=$(python -c "print(min([abs(x) for x in [float(x) for x in \"$(PrintHeader ${input} 1)\".split(\"x\")]]))")

#Clamp negatives
mincmath -clamp -const2 0 $(mincstats -max -quiet ${input}) ${input} ${tmpdir}/clamp.mnc

input=${tmpdir}/clamp.mnc

mnc2nii ${input} ${tmpdir}/input.nii

mrdegibbs -axes 0,2 -force ${tmpdir}/input.nii ${tmpdir}/degibbs.nii

nii2mnc ${tmpdir}/degibbs.nii ${tmpdir}/degibbs.mnc

input=${tmpdir}/degibbs.mnc

minc_anlm --mt $(nproc) ${input} ${tmpdir}/denoise.mnc

ThresholdImage 3 ${tmpdir}/denoise.mnc ${tmpdir}/weight1.mnc Otsu 2
ThresholdImage 3 ${tmpdir}/weight1.mnc ${tmpdir}/weight1.mnc 0.5 Inf 1 0

minccalc -clobber -unsigned -byte -expression '1' ${tmpdir}/denoise.mnc ${tmpdir}/initmask.mnc

N4BiasFieldCorrection -d 3 -i ${tmpdir}/denoise.mnc -o [ ${tmpdir}/N4_1.mnc,${tmpdir}/bias.mnc ] -s $(calc "int(4*0.1/${minimum_resolution}+0.5)") -b [ 30 ] -c [ 50x50x50x50,1e-6 ] -w ${tmpdir}/weight1.mnc -x ${tmpdir}/initmask.mnc --verbose

ImageMath 3 ${tmpdir}/bias.mnc / ${tmpdir}/bias.mnc $(mincstats -quiet -mean -mask ${tmpdir}/weight1.mnc -mask_binvalue 1 ${tmpdir}/bias.mnc)

ImageMath 3 ${tmpdir}/N4_1.mnc / ${input} ${tmpdir}/bias.mnc

minc_anlm --mt $(nproc) ${tmpdir}/N4_1.mnc ${tmpdir}/N4_denoise.mnc
mv -f ${tmpdir}/N4_denoise.mnc ${tmpdir}/N4_1.mnc

ThresholdImage 3 ${tmpdir}/N4_1.mnc ${tmpdir}/weight2.mnc Otsu 2
ThresholdImage 3 ${tmpdir}/weight2.mnc ${tmpdir}/weight2.mnc 0.5 Inf 1 0

cp -f ${tmpdir}/weight2.mnc ${tmpdir}/weight3.mnc

#Model for brainmask
fixedfile=/scratch/m/mchakrav/jrasgado/sudmex_alcohol_rat/Atlas/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_ExVivo_Template/SIGMA_ExVivo_Brain_Template_Masked.mnc
movingfile=${tmpdir}/N4_1.mnc
fixedmask=/scratch/m/mchakrav/jrasgado/sudmex_alcohol_rat/Atlas/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.2.1/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_ExVivo_Template/SIGMA_ExVivo_Brain_Mask.mnc
movingmask=NOMASK

#Optimized multi-stage affine registration
antsRegistration --dimensionality 3 --verbose --minc \
--use-histogram-matching 0 \
--output [ ${tmpdir}/reg ] \
--initial-moving-transform [${fixedfile},${movingfile},1 ] \
--winsorize-image-intensities [ 0.005,0.995 ] \
--transform Translation[ 0.1 ] \
        --metric Mattes[ ${fixedfile},${movingfile},1,43,None ] \
        --convergence [ 2025x2025x2025x2025x1350,1e-6,10 ] \
        --shrink-factors 6x6x6x5x4 \
        --smoothing-sigmas 0.407674464138x0.356715156121x0.305755848104x0.254796540086x0.203837232069mm \
        --masks [ NOMASK,NOMASK ] \
--transform Rigid[ 0.1 ] \
        --metric Mattes[ ${fixedfile},${movingfile},1,51,None ] \
        --convergence [ 2025x1350x450,1e-6,10 ] \
        --shrink-factors 5x4x3 \
        --smoothing-sigmas 0.254796540086x0.203837232069x0.152877924052mm \
        --masks [ NOMASK,NOMASK ] \
--transform Similarity[ 0.1 ] \
        --metric Mattes[ ${fixedfile},${movingfile},1,64,None ] \
        --convergence [ 1350x450x150,1e-6,10 ] \
        --shrink-factors 4x3x2 \
        --smoothing-sigmas 0.203837232069x0.152877924052x0.101918616035mm \
        --masks [ NOMASK,NOMASK ] \
--transform Similarity[ 0.1 ] \
        --metric Mattes[ ${fixedfile},${movingfile},1,64,None ] \
        --convergence [ 1350x450x150,1e-6,10 ] \
        --shrink-factors 4x3x2 \
        --smoothing-sigmas 0.203837232069x0.152877924052x0.101918616035mm \
        --masks [ ${fixedmask},${movingmask} ] \
--transform Affine[ 0.1 ] \
        --metric Mattes[ ${fixedfile},${movingfile},1,64,None ] \
        --convergence [ 1350x450x150x50x50,1e-6,10 ] \
        --shrink-factors 4x3x2x1x1 \
        --smoothing-sigmas 0.203837232069x0.152877924052x0.101918616035x0.0509593080173x0mm \
        --masks [ ${fixedmask},${movingmask} ]

#Resample mask
antsApplyTransforms -d 3 -i ${fixedmask} -r ${movingfile} -t [${tmpdir}/reg0_GenericAffine.xfm,1] \
  -n GenericLabel --verbose -o ${tmpdir}/mask.mnc

ImageMath 3 ${tmpdir}/weight3.mnc m ${tmpdir}/weight3.mnc ${tmpdir}/mask.mnc
ImageMath 3 ${tmpdir}/weight3.mnc GetLargestComponent ${tmpdir}/weight3.mnc
iMath 3 ${tmpdir}/weight3.mnc ME ${tmpdir}/weight3.mnc 2 1 ball 1
ImageMath 3 ${tmpdir}/weight3.mnc GetLargestComponent ${tmpdir}/weight3.mnc
iMath 3 ${tmpdir}/weight3.mnc MD ${tmpdir}/weight3.mnc 2 1 ball 1

#Redo bias field correction
N4BiasFieldCorrection -d 3 -i ${tmpdir}/denoise.mnc -b [ 30 ] -c [ 300x300x300x300,1e-6 ] -r 0 -w ${tmpdir}/weight3.mnc -x ${tmpdir}/initmask.mnc \
  -o [ ${tmpdir}/N4.mnc, ${tmpdir}/bias.mnc ] -s $(calc "int(4*0.1/${minimum_resolution}+0.5)") --verbose --histogram-sharpening [ 0.05,0.01,256 ]

ImageMath 3 ${tmpdir}/bias.mnc / ${tmpdir}/bias.mnc $(mincstats -quiet -mean -mask ${tmpdir}/mask.mnc -mask_binvalue 1 ${tmpdir}/bias.mnc)

ImageMath 3 ${tmpdir}/N4.mnc / ${input} ${tmpdir}/bias.mnc

pctTlow=$(mincstats -quiet -pctT 0.01 -mask ${tmpdir}/weight3.mnc -mask_binvalue 1 ${tmpdir}/N4.mnc)
pctThigh=$(mincstats -quiet -pctT 99 -mask ${tmpdir}/weight3.mnc -mask_binvalue 1 ${tmpdir}/N4.mnc)

minccalc -unsigned -short -expression "clamp(clamp(A[0]-${pctTlow},0,65535)/${pctThigh}*65535,0,65535)" ${tmpdir}/N4.mnc ${tmpdir}/N4.norm.mnc
mv -f ${tmpdir}/N4.norm.mnc ${tmpdir}/N4.mnc

minc_anlm --mt $(nproc) ${tmpdir}/N4.mnc $(dirname ${output})/$(basename ${output} .mnc)_uncropped.mnc

ImageMath 3 ${tmpdir}/N4.mnc PadImage ${tmpdir}/N4.mnc 50
antsApplyTransforms -d 3 -i ${tmpdir}/weight3.mnc -o ${tmpdir}/cropmask.mnc -r ${tmpdir}/N4.mnc --verbose

ExtractRegionFromImageByMask 3 ${tmpdir}/N4.mnc ${tmpdir}/N4.crop.mnc ${tmpdir}/cropmask.mnc 1 10

iMath 3 ${tmpdir}/weight3.mnc MD ${tmpdir}/weight3.mnc 1 1 ball 1
ImageMath 3 ${tmpdir}/weight3.mnc FillHoles ${tmpdir}/weight3.mnc 2
iMath 3 ${tmpdir}/weight3.mnc ME ${tmpdir}/weight3.mnc 1 1 ball 1

antsApplyTransforms -d 3 -i ${tmpdir}/weight3.mnc -r ${tmpdir}/N4.crop.mnc -o ${tmpdir}/weight3.mnc -n GenericLabel

minc_anlm --mt $(nproc) ${tmpdir}/N4.crop.mnc ${output}
cp -f ${tmpdir}/weight3.mnc $(dirname ${output})/$(basename ${output} .mnc)_mask.mnc

param2xfm $(xfm2param ${tmpdir}/reg0_GenericAffine.xfm | grep -E 'scale|shear') ${tmpdir}/scaleshear.xfm
xfminvert ${tmpdir}/scaleshear.xfm ${tmpdir}/unscaleshear.xfm
xfmconcat ${tmpdir}/reg0_GenericAffine.xfm ${tmpdir}/unscaleshear.xfm ${tmpdir}/lsq6.xfm
xfminvert ${tmpdir}/lsq6.xfm ${tmpdir}/lsq6_invert.xfm

mincresample -tfm_input_sampling -transform ${tmpdir}/lsq6_invert.xfm ${output} ${tmpdir}/lsq6.mnc

mincmath -clamp -const2 0 $(mincstats -quiet -max ${tmpdir}/lsq6.mnc) ${tmpdir}/lsq6.mnc $(dirname ${output})/$(basename ${output} .mnc)_lsq6.mnc

mincresample -transform ${tmpdir}/lsq6_invert.xfm  -like $(dirname ${output})/$(basename ${output} .mnc)_lsq6.mnc -keep -near -labels ${tmpdir}/weight3.mnc $(dirname ${output})/$(basename ${output} .mnc)_lsq6_mask.mnc

rm -rf ${tmpdir}

