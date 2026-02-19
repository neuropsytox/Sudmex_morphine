import os
import pandas as pd # type: ignore
import pyls
from pyls import behavioral_pls
import numpy as np
import sys

smooth = str(sys.argv[1])
num_boot = int(sys.argv[2])
num_perm = int(sys.argv[3])
num_split = 100

# Set parameters
number_of_desired_processors = 40
print({smooth})
print({num_boot})
print({num_perm})
print({num_split})

# Set paths
path = f"/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/smri/DBM_invivo"
output_dir = f"/scratch/m/mchakrav/jrasgado/sudmexmor/analysis/smri/DBM_invivo/PLS/outputs_{num_boot}/"
os.makedirs(output_dir, exist_ok = True)

# Load the brain matrix
X = np.loadtxt(f"{path}/DBM/smooth_{smooth}/data/Brain_matrix4pls.csv", delimiter=',', skiprows=1)

if not isinstance(X, np.ndarray) or X.ndim != 2:
    raise ValueError("brain matrix should be a 2-dimensional numpy array (matrix).")

print({"loaded brain matrix"})
# Load the behavior metrics
# Load the behavior metrics
Y = np.loadtxt(f"{path}/DBM/smooth_{smooth}/data/Behavior_metrics4pls.csv", delimiter=',',skiprows=1)

# print(Y)
if not isinstance(Y, np.ndarray) or Y.ndim != 2:
    raise ValueError("behavior matrix should be a 2-dimensional numpy array (matrix).")

# Verify that all columns are numeric
if not np.issubdtype(Y.dtype, np.number):
    raise ValueError("All columns in the behavior matrix should be numeric.")

print("Running PLS")
# Run plsc
bpls = behavioral_pls(X,Y, n_perm = num_perm, n_boot = num_boot, n_split = num_split, rotate = False, seed = 42, n_proc = number_of_desired_processors)
# n_proc can be set on niagara (make sure that joblib is installed)

print("Saving results")

np.savetxt(f'{output_dir}/x_weights.csv', bpls['x_weights'], delimiter=',') # p x m
np.savetxt(f'{output_dir}/y_weights.csv', bpls['y_weights'], delimiter=',') # m x m
np.savetxt(f'{output_dir}/x_scores.csv', bpls['x_scores'], delimiter=',') # n x m
np.savetxt(f'{output_dir}/y_scores.csv', bpls['y_scores'], delimiter=',') # n x m
np.savetxt(f'{output_dir}/y_loadings.csv', bpls['y_loadings'], delimiter=',') # m x m 
np.savetxt(f'{output_dir}/sinvals.csv', bpls['singvals'], delimiter=',') # (m,)
np.savetxt(f'{output_dir}/varexp.csv', bpls['varexp'], delimiter=',') # (m,)
np.savetxt(f'{output_dir}/permres_pvals.csv', bpls['permres']['pvals'], delimiter=',') # shape: (m,)
np.savetxt(f'{output_dir}/permres_permsamples.csv', bpls['permres']['permsamples'], delimiter=',') 
np.savetxt(f'{output_dir}/bootres_x_weights_normed.csv', bpls['bootres']['x_weights_normed'], delimiter=',') 
np.savetxt(f'{output_dir}/bootres_x_weights_stderr.csv', bpls['bootres']['x_weights_stderr'], delimiter=',')
np.savetxt(f'{output_dir}/bootres_bootsamples.csv', bpls['bootres']['bootsamples'], delimiter=',')
np.savetxt(f'{output_dir}/bootres_y_loadings.csv', bpls['bootres']['y_loadings'], delimiter=',')

# to save your bootstrapped samples
os.mkdir(f'{output_dir}/y_loadings_boot')
for i in range(bpls['bootres']['y_loadings_boot'].shape[0]):
    np.savetxt(f'{output_dir}/y_loadings_boot/bootres_y_loadings_boot_{i}.csv', bpls['bootres']['y_loadings_boot'][i], delimiter=',')

# saving your confidence intervals 
os.mkdir(f'{output_dir}/y_loadings_ci')
for i in range(bpls['bootres']['y_loadings_ci'].shape[0]):
    np.savetxt(f'{output_dir}/y_loadings_ci/bootres_y_loadings_ci_behaviour_{i}.csv', bpls['bootres']['y_loadings_ci'][i], delimiter=',')

np.savetxt(f'{output_dir}/cvres_pearson_r.csv', bpls['cvres']['pearson_r'], delimiter=',') 
np.savetxt(f'{output_dir}/cvres_r_squared.csv', bpls['cvres']['r_squared'], delimiter=',')

# Saving your input information (makes the code longer, but quite valuable when trouble shooting, or if you've done several runs and want to keep track of the parameters of each):
#np.savetxt(f'{output_dir}/inputs_X.csv', bpls['inputs']['X'], delimiter=',')
np.savetxt(f'{output_dir}/inputs_Y.csv', bpls['inputs']['Y'], delimiter=',')
f=open(f'{output_dir}/input_info.txt','w')
f.write(f"Groups: {bpls['inputs']['groups']}\n") # [n]
f.write(f"Num of conditions: {bpls['inputs']['n_cond']}\n") # 1
f.write(f"Num of permutations: {bpls['inputs']['n_perm']}\n") # perm
f.write(f"Bootstrapping: {bpls['inputs']['n_boot']}\n") # boot
f.write(f"Bootstrapping: {bpls['inputs']['test_split']}\n") # default=100
f.write(f"Bootstrapping: {bpls['inputs']['test_size']}\n") # default=0.25
f.write(f"Bootstrapping: {bpls['inputs']['covariance']}\n") # default=False
f.write(f"Rotations: {bpls['inputs']['rotate']}\n") # True
f.write(f"Confidence Intervals: {bpls['inputs']['ci']}\n") # default=95
f.write(f"Verbose: {bpls['inputs']['verbose']}\n") # True
f.close()

os.makedirs(f'{output_dir}/splitres/', exist_ok=True)
np.savetxt(f'{output_dir}/splitres/splitres_u-vcorr.csv', np.column_stack((bpls['splitres']['ucorr'], bpls['splitres']['vcorr'])), delimiter=',')
np.savetxt(f'{output_dir}/splitres/splitres_u-vcorr_pvals.csv', np.column_stack((bpls['splitres']['ucorr_pvals'], bpls['splitres']['vcorr_pvals'])), delimiter=',')
np.savetxt(f'{output_dir}/splitres/splitres_ucorr_lo-uplim.csv', np.column_stack((bpls['splitres']['ucorr_lolim'], bpls['splitres']['ucorr_uplim'])),delimiter=',')
np.savetxt(f'{output_dir}/splitres/splitres_vcorr_lo-uplim.csv', np.column_stack((bpls['splitres']['vcorr_lolim'], bpls['splitres']['vcorr_uplim'])),delimiter=',')

