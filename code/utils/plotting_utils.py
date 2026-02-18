"""
Visualization utilities for creating consistent plots.

This module contains functions for generating publication-quality figures
with consistent styling across all analyses.
"""

import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import seaborn as sns
import numpy as np


# Default color schemes
COLORS = {
    'control': '#4A90E2',
    'morphine': '#E24A4A',
    'male': '#7E57C2',
    'female': '#FF7043',
    'neutral': '#757575'
}


def set_publication_style():
    """
    Set matplotlib parameters for publication-quality figures.
    """
    plt.rcParams.update({
        'figure.dpi': 300,
        'savefig.dpi': 300,
        'font.size': 10,
        'font.family': 'Arial',
        'axes.linewidth': 1.5,
        'axes.labelsize': 11,
        'axes.titlesize': 12,
        'xtick.labelsize': 10,
        'ytick.labelsize': 10,
        'xtick.major.width': 1.5,
        'ytick.major.width': 1.5,
        'xtick.major.size': 5,
        'ytick.major.size': 5,
        'legend.fontsize': 10,
        'legend.frameon': False,
        'figure.facecolor': 'white',
        'axes.facecolor': 'white'
    })
    
    # Set seaborn style
    sns.set_style('ticks')


def add_panel_label(ax, label, x=-0.1, y=1.05, fontsize=14):
    """
    Add panel label (A, B, C, etc.) to subplot.
    
    Parameters
    ----------
    ax : matplotlib.axes.Axes
        The axes to add the label to
    label : str
        Panel label (e.g., 'A', 'B', 'C')
    x, y : float
        Position of label in axes coordinates
    fontsize : int
        Font size for the label
    """
    ax.text(x, y, label, transform=ax.transAxes,
            fontsize=fontsize, fontweight='bold', va='top', ha='right')


def add_significance_bar(ax, x1, x2, y, height, p_value, fontsize=12):
    """
    Add significance bar with asterisks to plot.
    
    Parameters
    ----------
    ax : matplotlib.axes.Axes
        The axes to add the bar to
    x1, x2 : float
        X coordinates of the two groups
    y : float
        Y coordinate for the bar
    height : float
        Height of the bar bracket
    p_value : float
        P-value to determine number of asterisks
    fontsize : int
        Font size for the asterisks
    """
    # Draw horizontal line
    ax.plot([x1, x1, x2, x2], [y, y+height, y+height, y], 
            lw=1.5, c='black')
    
    # Determine significance level
    if p_value < 0.001:
        text = '***'
    elif p_value < 0.01:
        text = '**'
    elif p_value < 0.05:
        text = '*'
    else:
        text = 'n.s.'
    
    # Add text
    ax.text((x1+x2)*0.5, y+height, text, 
            ha='center', va='bottom', fontsize=fontsize)


def format_axis(ax, remove_top=True, remove_right=True):
    """
    Apply consistent axis formatting.
    
    Parameters
    ----------
    ax : matplotlib.axes.Axes
        The axes to format
    remove_top : bool
        Whether to remove top spine
    remove_right : bool
        Whether to remove right spine
    """
    if remove_top:
        ax.spines['top'].set_visible(False)
    if remove_right:
        ax.spines['right'].set_visible(False)
    
    ax.tick_params(direction='out')
    ax.grid(False)


def create_bar_plot(ax, data, groups, colors=None, ylabel='', title='', 
                   show_points=True, show_error=True):
    """
    Create a bar plot with individual data points.
    
    Parameters
    ----------
    ax : matplotlib.axes.Axes
        The axes to plot on
    data : dict
        Dictionary with group names as keys and data arrays as values
    groups : list
        Order of groups to plot
    colors : dict, optional
        Colors for each group
    ylabel : str
        Y-axis label
    title : str
        Plot title
    show_points : bool
        Whether to overlay individual data points
    show_error : bool
        Whether to show error bars (SEM)
    """
    if colors is None:
        colors = COLORS
    
    x_pos = np.arange(len(groups))
    means = [np.mean(data[g]) for g in groups]
    sems = [np.std(data[g]) / np.sqrt(len(data[g])) for g in groups]
    
    # Create bars
    bars = ax.bar(x_pos, means, 
                  color=[colors.get(g, COLORS['neutral']) for g in groups],
                  alpha=0.7, width=0.6)
    
    # Add error bars
    if show_error:
        ax.errorbar(x_pos, means, yerr=sems, fmt='none', 
                   c='black', capsize=5, linewidth=1.5)
    
    # Add individual points
    if show_points:
        for i, group in enumerate(groups):
            x_scatter = np.random.normal(i, 0.04, size=len(data[group]))
            ax.scatter(x_scatter, data[group], 
                      c='black', alpha=0.4, s=20, zorder=3)
    
    # Format
    ax.set_xticks(x_pos)
    ax.set_xticklabels(groups)
    ax.set_ylabel(ylabel)
    ax.set_title(title)
    format_axis(ax)


def create_scatter_plot(ax, x, y, groups=None, colors=None, 
                       xlabel='', ylabel='', title='',
                       add_regression=True):
    """
    Create a scatter plot with optional grouping and regression line.
    
    Parameters
    ----------
    ax : matplotlib.axes.Axes
        The axes to plot on
    x, y : array-like
        X and Y data
    groups : array-like, optional
        Group labels for each point
    colors : dict, optional
        Colors for each group
    xlabel, ylabel : str
        Axis labels
    title : str
        Plot title
    add_regression : bool
        Whether to add regression line
    """
    if groups is None:
        # Single group
        ax.scatter(x, y, c=COLORS['neutral'], alpha=0.6, s=50)
        
        if add_regression:
            # Calculate and plot regression line
            z = np.polyfit(x, y, 1)
            p = np.poly1d(z)
            ax.plot(x, p(x), 'r--', linewidth=2, alpha=0.7)
            
            # Add correlation coefficient
            r = np.corrcoef(x, y)[0, 1]
            ax.text(0.05, 0.95, f'r = {r:.3f}', 
                   transform=ax.transAxes, va='top', ha='left',
                   bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))
    else:
        # Multiple groups
        if colors is None:
            colors = COLORS
        
        unique_groups = np.unique(groups)
        for group in unique_groups:
            mask = groups == group
            ax.scatter(x[mask], y[mask], 
                      c=colors.get(group, COLORS['neutral']),
                      label=group, alpha=0.6, s=50)
        
        ax.legend()
    
    # Format
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    ax.set_title(title)
    format_axis(ax)


def save_figure(fig, filename, output_dir, formats=['png', 'pdf']):
    """
    Save figure in multiple formats.
    
    Parameters
    ----------
    fig : matplotlib.figure.Figure
        Figure to save
    filename : str
        Base filename (without extension)
    output_dir : str or Path
        Output directory
    formats : list
        List of file formats to save
    """
    from pathlib import Path
    
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    for fmt in formats:
        filepath = output_dir / f"{filename}.{fmt}"
        fig.savefig(filepath, dpi=300, bbox_inches='tight')
        print(f"Saved: {filepath}")


if __name__ == '__main__':
    print("Visualization utilities loaded")
    print(f"Default colors: {COLORS}")
