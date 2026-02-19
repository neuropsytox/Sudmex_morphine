singularity exec -B /scratch:/scratch container/afni.sif \
 3dMVM -prefix Seed_based_glcer -jobs 42 \
	-bsVars 'Intake*Age' \
	-wsVars 'Subj' \
	-qVars 'Age' \
	-num_glt 3 \
	-gltCode 1 model2H 'Intake : 1*High -1*Ctrl' \
	-gltCode 2 model2L 'Intake : 1*Low -1*Ctrl' \
	-gltCode 3 model5 'Intake : 1*High -1*Low' \
	-dataTable @/scratch/m/mchakrav/jrasgado/sudmex_alcohol_rat/analysis/fmri/code/LME_SB/fc_dataset_left_granule_cell_level_of_the_cerebellum_left_2.txt
