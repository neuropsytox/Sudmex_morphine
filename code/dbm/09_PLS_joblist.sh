#!/bin/bash
#SBATCH --time=09:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=80
#SBATCH --account=rrg-mchakrav-ab

### Usage example: sbatch code/09_PLS.sh smooth n_boot n_perm###

module load cobralab
module load NiaEnv/2019b intelpython3
module load gnu-parallel qbatch

source ~/.virtualenvs/PLS_venv/bin/activate

path=/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/smri/DBM_invivo/
cd $path

smooth=$1
num_boot=$2
n_perm=$3

python code/PLS_script.py $smooth $num_boot $n_perm
