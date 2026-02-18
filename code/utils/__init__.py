"""
Utility modules for Sudmex morphine project.

This package contains helper functions for data processing, 
analysis, and visualization.
"""

from .data_utils import (
    load_behavioral_data,
    standardize_data,
    remove_outliers,
    calculate_effect_size,
    get_project_paths,
    validate_group_labels
)

from .plotting_utils import (
    set_publication_style,
    add_panel_label,
    add_significance_bar,
    format_axis,
    create_bar_plot,
    create_scatter_plot,
    save_figure,
    COLORS
)

__all__ = [
    # Data utilities
    'load_behavioral_data',
    'standardize_data',
    'remove_outliers',
    'calculate_effect_size',
    'get_project_paths',
    'validate_group_labels',
    # Plotting utilities
    'set_publication_style',
    'add_panel_label',
    'add_significance_bar',
    'format_axis',
    'create_bar_plot',
    'create_scatter_plot',
    'save_figure',
    'COLORS'
]

__version__ = '1.0.0'
