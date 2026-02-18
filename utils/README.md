# Utility Files

This directory contains environment configuration and utility files.

## Files

### Environment Specifications

Create environment specification files to ensure reproducibility:

**requirements.txt** - Python package requirements
```bash
# Generate with:
pip freeze > requirements.txt
```

**environment.yml** - Conda environment specification
```bash
# Generate with:
conda env export > environment.yml
```

**sudmex_morphine_spec.txt** - Explicit conda spec file
```bash
# Generate with:
conda list --explicit > sudmex_morphine_spec.txt
```

## Usage

### Creating Environment from Specification

Using requirements.txt:
```bash
pip install -r requirements.txt
```

Using environment.yml:
```bash
conda env create -f environment.yml
```

Using spec file:
```bash
conda create --name sudmex_morphine --file sudmex_morphine_spec.txt
```

## Package Versions

It's important to maintain version information for reproducibility. Update these files whenever packages are added or updated.

## Custom Utilities

If you create custom Python modules or R packages for this project, document them here with:
- Installation instructions
- Usage examples
- API documentation

## Notes

- Keep environment files updated
- Test environment creation on a fresh installation
- Document any system-specific dependencies
- Include versions for all critical packages
