"""
Helper functions for data loading and preprocessing.

This module contains utility functions used across multiple analysis notebooks.
"""

import pandas as pd
import numpy as np
from pathlib import Path


def load_behavioral_data(filepath, subject_col='subject_id'):
    """
    Load and validate behavioral data from file.
    
    Parameters
    ----------
    filepath : str or Path
        Path to the behavioral data file (CSV or Excel)
    subject_col : str, default='subject_id'
        Name of the subject identifier column
        
    Returns
    -------
    pd.DataFrame
        Loaded behavioral data
    """
    filepath = Path(filepath)
    
    if filepath.suffix in ['.csv', '.txt']:
        data = pd.read_csv(filepath)
    elif filepath.suffix in ['.xlsx', '.xls']:
        data = pd.read_excel(filepath)
    else:
        raise ValueError(f"Unsupported file format: {filepath.suffix}")
    
    # Validate that subject column exists
    if subject_col not in data.columns:
        raise ValueError(f"Subject column '{subject_col}' not found in data")
    
    return data


def standardize_data(data, columns=None):
    """
    Standardize data (z-score normalization).
    
    Parameters
    ----------
    data : pd.DataFrame or np.ndarray
        Data to standardize
    columns : list, optional
        Specific columns to standardize (for DataFrame input)
        
    Returns
    -------
    pd.DataFrame or np.ndarray
        Standardized data
    """
    if isinstance(data, pd.DataFrame):
        if columns is None:
            columns = data.select_dtypes(include=[np.number]).columns
        
        standardized = data.copy()
        standardized[columns] = (data[columns] - data[columns].mean()) / data[columns].std()
        return standardized
    else:
        return (data - np.mean(data, axis=0)) / np.std(data, axis=0)


def remove_outliers(data, columns, n_std=3):
    """
    Remove outliers based on standard deviation threshold.
    
    Parameters
    ----------
    data : pd.DataFrame
        Input data
    columns : list
        Columns to check for outliers
    n_std : float, default=3
        Number of standard deviations for outlier threshold
        
    Returns
    -------
    pd.DataFrame
        Data with outliers removed
    """
    data_clean = data.copy()
    
    for col in columns:
        mean = data[col].mean()
        std = data[col].std()
        threshold = n_std * std
        
        mask = (data[col] >= mean - threshold) & (data[col] <= mean + threshold)
        data_clean = data_clean[mask]
    
    return data_clean


def calculate_effect_size(group1, group2, method='cohen'):
    """
    Calculate effect size for two groups.
    
    Parameters
    ----------
    group1, group2 : array-like
        Data from two groups
    method : str, default='cohen'
        Method for calculating effect size ('cohen' for Cohen's d)
        
    Returns
    -------
    float
        Effect size value
    """
    if method == 'cohen':
        # Cohen's d
        pooled_std = np.sqrt((np.std(group1)**2 + np.std(group2)**2) / 2)
        return (np.mean(group1) - np.mean(group2)) / pooled_std
    else:
        raise ValueError(f"Unknown method: {method}")


def get_project_paths():
    """
    Get standard project directory paths.
    
    Returns
    -------
    dict
        Dictionary with paths to main project directories
    """
    # Get repository root (two levels up from code/utils/)
    repo_root = Path(__file__).parent.parent.parent
    
    return {
        'root': repo_root,
        'data': repo_root / 'Data',
        'figures': repo_root / 'Figures',
        'code': repo_root / 'code',
        'statistics': repo_root / 'Statistics',
        'utils': repo_root / 'utils'
    }


def validate_group_labels(data, group_col, expected_groups):
    """
    Validate that group labels match expected values.
    
    Parameters
    ----------
    data : pd.DataFrame
        Input data
    group_col : str
        Name of the group column
    expected_groups : list
        Expected group labels
        
    Raises
    ------
    ValueError
        If unexpected group labels are found
    """
    actual_groups = set(data[group_col].unique())
    expected_set = set(expected_groups)
    
    if not actual_groups.issubset(expected_set):
        unexpected = actual_groups - expected_set
        raise ValueError(f"Unexpected group labels found: {unexpected}")
    
    if not actual_groups:
        raise ValueError("No group labels found in data")


if __name__ == '__main__':
    # Example usage
    print("Data loading and preprocessing utilities")
    print(f"Available functions: {[name for name in dir() if not name.startswith('_')]}")
