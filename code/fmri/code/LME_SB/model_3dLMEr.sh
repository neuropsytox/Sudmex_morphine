#!/bin/bash

module load cobralab

#################################
## 2023-09-14
## Created by JalilRT

path=/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/fmri
mkdir -p ${path}/code/LME_SB/models
mkdir -p ${path}/Seed_based/models/M1
container=${path}/container/afni.sif
cd ${path}
fc=$(ls ${path}/code/LME_SB/datasets/fc_dataset_*)

#################################
for i in ${fc}; do
rois=$(basename ${i} .txt)

cat << EOF > ${path}/code/LME_SB/models/M1_${rois}.sh
#!/bin/bash
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=40
#SBATCH --account=rrg-mchakrav-ab

singularity exec -B /scratch:/scratch ${container} \
 3dLMEr -prefix /scratch/m/mchakrav/jrasgado/sudmexmor/analysis/fmri/Seed_based/models/M1/M1_${rois}.nii.gz -jobs 80 \
	-mask /scratch/m/mchakrav/jrasgado/sudmexmor/analysis/fmri/Seed_based/mask_registered.nii.gz \
        -model 'Age*Group+Batch+(1|Subj)' \
        -qVars 'Age' \
        -qVarCenters 0 \
        -gltCode MvS 'Group : 1*Mor -1*Sham' \
        -dataTable @/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/fmri/code/LME_SB/datasets/${rois}.txt

EOF

sbatch ${path}/code/LME_SB/models/M1_${rois}.sh
done
