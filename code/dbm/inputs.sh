#!/bin/bash

cd /scratch/m/mchakrav/jrasgado/sudmexmor/analysis/smri/DBM_invivo/preproc
for i in $(ls -d sub-*/); do echo $PWD/$(basename $i)/ses-T1/anat/$(basename $i)_ses-T1_pp.nii,$PWD/$(basename $i)/ses-T2/anat/$(basename $i)_ses-T2_pp.nii,$PWD/$(basename $i)/ses-T3/anat/$(basename $i)_ses-T3_pp.nii >> ../code/inputs.txt; done
