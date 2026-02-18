# Contributing to Sudmex_morphine

Thank you for your interest in contributing to this project! This document provides guidelines for contributing to the Sudmex morphine research codebase.

## Getting Started

1. **Fork the repository** - Create your own fork of the project
2. **Clone your fork** - Clone the repository to your local machine
3. **Set up the environment** - Follow the instructions in [code/Env_configuration.md](code/Env_configuration.md)
4. **Create a branch** - Create a new branch for your changes

```bash
git checkout -b feature/your-feature-name
```

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with:
- A clear, descriptive title
- Steps to reproduce the problem
- Expected vs actual behavior
- Screenshots if applicable
- Environment details (OS, Python version, etc.)

### Suggesting Enhancements

Enhancement suggestions are welcome! Please:
- Use a clear, descriptive title
- Provide a detailed description of the proposed enhancement
- Explain why this enhancement would be useful
- Include examples if applicable

### Code Contributions

#### Adding Analysis Code

1. Place analysis scripts in the appropriate directory:
   - Behavioral analyses → `code/Behavior_metrics.ipynb`
   - MRI analyses → `code/MRI_metrics.ipynb`
   - Statistical analyses → Update relevant notebooks

2. Follow the existing code structure and style
3. Include comments explaining complex sections
4. Add docstrings to functions

#### Adding Data

⚠️ **Important**: Do not commit large data files or sensitive data to the repository.

- Use `.gitignore` to exclude data files
- Provide sample data or instructions for obtaining data
- Document data formats and structure

#### Documentation

- Update README files when adding new features
- Keep documentation clear and concise
- Include examples where helpful

### Code Style Guidelines

#### Python
- Follow PEP 8 style guide
- Use meaningful variable names
- Add type hints where appropriate
- Write docstrings for functions

Example:
```python
def calculate_metric(data: pd.DataFrame, threshold: float = 0.5) -> float:
    """
    Calculate a specific behavioral metric.
    
    Parameters
    ----------
    data : pd.DataFrame
        Behavioral data
    threshold : float, default=0.5
        Threshold value for calculation
        
    Returns
    -------
    float
        Calculated metric value
    """
    # Implementation here
    pass
```

#### Jupyter Notebooks
- Clear markdown cells explaining each section
- Code cells should be concise and focused
- Include visualizations inline
- Clear all outputs before committing (unless necessary for documentation)

### Commit Messages

Write clear, descriptive commit messages:
- Use present tense ("Add feature" not "Added feature")
- Be specific about what changed
- Reference issues when applicable

Examples:
```
Add analysis for open field test locomotion

Update README with installation instructions

Fix bug in connectivity matrix calculation (#42)
```

### Pull Request Process

1. **Update documentation** - Ensure all documentation is updated
2. **Test your changes** - Run all relevant analyses to ensure nothing breaks
3. **Update the PR description** - Clearly describe your changes
4. **Request review** - Tag relevant reviewers
5. **Address feedback** - Make requested changes promptly

#### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Other (please describe):

## Testing
Describe how you tested your changes

## Checklist
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] Tests pass
- [ ] No merge conflicts
```

## Questions?

If you have questions, please:
1. Check existing documentation
2. Search existing issues
3. Create a new issue with the "question" label

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Accept constructive criticism gracefully
- Focus on what's best for the project
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discriminatory language
- Trolling or inflammatory comments
- Public or private harassment
- Publishing others' private information

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to advancing neuroscience research! 🧠🐀
