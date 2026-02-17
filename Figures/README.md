# Figures Directory

This directory contains all generated figures and visualizations.

## Structure

### Behavior/
Figures from behavioral analyses:
- Open Field Test plots
- Elevated Plus Maze results
- Novel Object Recognition graphs
- Conditioned Place Preference visualizations

### MRI/
Brain imaging visualizations:
- Structural MRI results
- DBM statistical maps
- Functional connectivity matrices
- Network graphs

### PLS/
Partial Least Squares analysis figures:
- Latent variable scores
- Brain and behavioral loadings
- Correlation plots
- Statistical maps

### Final_Figures/
Publication-ready figures for manuscript:
- Figure 1: Experimental design
- Figure 2: Behavioral results
- Figure 3: Structural MRI
- Figure 4: Functional connectivity
- Figure 5: PLS analysis
- Figure 6: Summary model
- Supplementary figures

## Figure Guidelines

### File Formats
- PNG files (300 DPI) for presentations and web
- PDF files for publication submissions
- SVG files for vector graphics when needed

### Naming Conventions
- Use descriptive names: `behavioral_oft_control_vs_morphine.png`
- Include figure numbers for manuscript figures: `Figure_1.png`
- Date stamp exploratory figures: `exploratory_connectivity_20260217.png`

### Style Guide
- Use consistent color schemes across figures
- Include scale bars and labels
- Add statistical annotations (*, **, ***)
- Use high-quality fonts (Arial, Helvetica)
- Ensure axes are properly labeled with units

## Figure Generation

All figures should be generated using the Jupyter notebooks in the `code/` directory:
- `Behavior_metrics.ipynb` → `Figures/Behavior/`
- `MRI_metrics.ipynb` → `Figures/MRI/`
- `PLS.ipynb` → `Figures/PLS/`
- `Figures.ipynb` → `Figures/Final_Figures/`
