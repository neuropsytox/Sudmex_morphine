# Environment Installation and Configuration
---

## Instructions

This guide will help you set up the computational environment required for reproducing the analyses in the Sudmex_morphine project.

### Prerequisites

- [Anaconda](https://www.anaconda.com/products/distribution) or [Miniconda](https://docs.conda.io/en/latest/miniconda.html) installed
- Git (for cloning the repository)
- Sufficient disk space for data and analysis outputs

---

## Step-by-Step Installation

### 1. Launch a Terminal

Open a conda or bash terminal on your system.

### 2. Clone the Repository

Clone this repository and navigate into it:

```bash
# Clone the repository
git clone https://github.com/neuropsytox/Sudmex_morphine.git

# Navigate into the directory
cd Sudmex_morphine
```

### 3. Create the Conda Environment

Create a new conda environment with the required packages:

```bash
# Create environment from specification file
conda create --name sudmex_morphine python=3.9 -y

# Activate the environment
conda activate sudmex_morphine
```

### 4. Install Required Packages

Install the necessary Python packages:

```bash
# Install core scientific computing packages
conda install -c conda-forge numpy pandas scipy matplotlib seaborn -y

# Install Jupyter for notebooks
conda install -c conda-forge jupyter jupyterlab -y

# Install neuroimaging packages
conda install -c conda-forge nibabel nilearn -y

# Install statistical packages
conda install -c conda-forge scikit-learn statsmodels -y
```

### 5. Install R and R Kernel (Optional)

If you need to run R code in Jupyter notebooks:

```bash
# Install R
conda install -c conda-forge r-base r-essentials -y

# Install R kernel for Jupyter
conda install -c conda-forge r-irkernel -y
```

### 6. Additional Packages

Install any additional packages specific to your analysis:

```bash
# Install additional Python packages
pip install pyls pingouin

# For advanced neuroimaging analysis
pip install nitime
```

---

## Verifying Installation

To verify that your environment is set up correctly:

```bash
# Activate the environment
conda activate sudmex_morphine

# Start Jupyter Lab
jupyter lab

# Or start Jupyter Notebook
jupyter notebook
```

Navigate to the `code/` directory and open any of the analysis notebooks to ensure all packages load correctly.

---

## Environment Export

To save your environment configuration:

```bash
# Export to a YAML file
conda env export > utils/sudmex_morphine_environment.yml

# Export to a requirements file
pip freeze > utils/requirements.txt
```

---

## Troubleshooting

### Common Issues

1. **Package conflicts**: If you encounter package conflicts, try creating a fresh environment and installing packages one at a time.

2. **Jupyter kernel not found**: Make sure to install ipykernel in your environment:
   ```bash
   conda install ipykernel
   python -m ipykernel install --user --name sudmex_morphine --display-name "Python (sudmex_morphine)"
   ```

3. **Memory issues**: For large datasets, ensure you have sufficient RAM and consider using data chunking or streaming methods.

---

## Updating the Environment

To update packages in your environment:

```bash
# Activate the environment
conda activate sudmex_morphine

# Update all packages
conda update --all -y

# Or update specific packages
conda update numpy pandas matplotlib
```

---

## Deactivating and Removing

To deactivate the environment:

```bash
conda deactivate
```

To remove the environment (if needed):

```bash
conda env remove --name sudmex_morphine
```

---

## Notes

- Always activate the `sudmex_morphine` environment before running any analysis scripts
- Keep your environment specification files updated in the `utils/` directory
- Document any additional packages or dependencies you add

---

## Support

For environment setup issues, please check:
- [Conda documentation](https://docs.conda.io/)
- [Jupyter documentation](https://jupyter.org/documentation)
- Repository issues page

---
