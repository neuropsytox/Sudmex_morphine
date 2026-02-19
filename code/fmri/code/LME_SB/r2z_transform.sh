#!/bin/bash
#SBATCH --time=05:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=30
#SBATCH --account=rrg-mchakrav-ab

# load modules and containers
module load cobralab
lv_path=/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/fmri
container=${lv_path}/container/afni.sif
path=/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/fmri/rabies/analysis_out

echo ## Converting r-corr to z-values ##
for ses in 1 2 3; do
  for input in $(ls ${path}/Session-T${ses}/analysis_datasink/seed_correlation_maps/_split_name_sub-*_ses-T${ses}_task-rest_bold/_seed_name_*_sphere_bin/sub-*_ses-*_map.nii.gz); do
 
  id=$(basename ${input} | cut -d '_' -f 1)
  output=$(basename ${input})
  mkdir -p Seed_based/ses-T${ses}/${id}

  echo 

  if [ ! -f ${lv_path}/Seed_based/ses-T${ses}/${id}/${output} ]; then
    singularity exec -B /scratch:/scratch ${container} 3dcalc -a ${input} -expr 'fizt_t2z(a)' -prefix ${lv_path}/Seed_based/ses-T${ses}/${id}/${output}
  else
    echo ${lv_path}/Seed_based/ses-T${ses}/${id}/${output} "exist"
  fi

  done
 done

chmod 777 -R ${lv_path}/Seed_based
