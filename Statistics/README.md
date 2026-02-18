# Statistics Directory

This directory contains statistical analysis outputs and reports.

## Structure

### Behavior/
Statistical results from behavioral analyses:
- ANOVA/t-test results
- Effect sizes
- Post-hoc comparisons
- Multiple comparison corrections

### MRI/
Statistical outputs from imaging analyses:
- Voxel-wise statistics
- ROI-based comparisons
- Connectivity statistics
- Network metrics comparisons

## File Types

- **CSV files**: Tables of statistical results
- **TXT files**: Detailed statistical reports
- **RData files**: R statistical objects
- **LOG files**: Analysis logs and parameters

## Statistical Methods

### Commonly Used Tests
- Independent samples t-tests
- Repeated measures ANOVA
- Mixed-effects models
- Permutation testing
- Bootstrap resampling
- Multiple comparison corrections (FDR, Bonferroni)

### Effect Sizes
- Cohen's d for t-tests
- Partial eta-squared for ANOVA
- Correlation coefficients

## Reporting Guidelines

All statistical results should include:
1. Test statistic
2. Degrees of freedom
3. P-value
4. Effect size
5. Confidence intervals (when applicable)
6. Multiple comparison corrections applied

## Software Used

- Python: scipy.stats, statsmodels, pingouin
- R: stats, lme4, emmeans
- FSL/AFNI: for neuroimaging statistics
