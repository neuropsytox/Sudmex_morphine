#!/bin/bash
#SBATCH --time=08:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=80
#SBATCH --account=rrg-mchakrav-ab

# load necessary modules
module load cobralab

path=/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/fmri
atlas_folder=${path}/Atlas/
TR=1.0

container=${path}/container/rabies_v051.sif

#define input/output folders
ses=$1
data_input=${path}/data/Session-${ses}
preproc_output=${path}/rabies/preproc_out/Session-${ses}
confound_out=${path}/rabies/confound_out/Session-${ses}
mkdir -p ${confound_out}

#RABIES call
singularity run -B /scratch:/scratch -B ${data_input}:/data_input:ro \
-B ${preproc_output}:/preproc_output -B ${confound_out}:/confound_out \
${container} -p Linear \
confound_correction /preproc_output /confound_out \
--read_datasink \
--TR ${TR} \
--highpass 0.01 \
--smoothing_filter 0.5 \
--lowpass 0.1 \
--edge_cutoff 30 \
--ica_aroma apply=true,dim=10,random_seed=1 \
--conf_list WM_signal CSF_signal mot_6

chmod -R 777 ${confound_out}
