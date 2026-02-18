# Code Directory

This directory contains all analysis code for the Sudmex morphine project.

## Analysis Workflow

Follow these notebooks in order:

1. **[Env_configuration.md](Env_configuration.md)** - Set up the computational environment
2. **[Morphine_protocol.ipynb](Morphine_protocol.ipynb)** - Document experimental protocol
3. **[Behavior_metrics.ipynb](Behavior_metrics.ipynb)** - Analyze behavioral data
4. **[MRI_metrics.ipynb](MRI_metrics.ipynb)** - Analyze MRI data
5. **[PLS.ipynb](PLS.ipynb)** - Perform multivariate brain-behavior analysis
6. **[Figures.ipynb](Figures.ipynb)** - Generate publication figures

## Notebooks

### Morphine_protocol.ipynb
Documents the experimental design, morphine administration protocol, and timeline.

### Behavior_metrics.ipynb
Analyzes behavioral test data including:
- Open Field Test
- Elevated Plus Maze
- Novel Object Recognition
- Conditioned Place Preference

### MRI_metrics.ipynb
Processes and analyzes MRI data:
- Structural MRI (volumes, morphometry)
- Functional MRI (connectivity)
- Deformation-based morphometry (DBM)

### PLS.ipynb
Performs Partial Least Squares analysis to identify brain-behavior relationships.

### Figures.ipynb
Generates all manuscript figures with publication-quality formatting.

## Helper Scripts

The `utils/` subdirectory contains helper functions and utility scripts used across notebooks.

## Running the Code

### Prerequisites
Make sure you have completed the environment setup:
```bash
conda activate sudmex_morphine
```

### Starting Jupyter
```bash
cd code/
jupyter lab
# or
jupyter notebook
```

### Execution Order
Run notebooks in the order listed above for reproducibility.

## Code Style

- Use descriptive variable names
- Comment complex sections
- Include docstrings for functions
- Follow PEP 8 style guidelines (Python)
- Use consistent naming conventions

## Version Control

All code changes should be committed to Git with descriptive commit messages.

## Dependencies

See `../utils/` for environment specification files.
