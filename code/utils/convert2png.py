import os
from PIL import Image
from tkinter import Tk, filedialog
import subprocess

# Prompt the user to select a folder containing the SVG images using a file dialog
root = Tk()
root.withdraw()
folder_path = filedialog.askdirectory(title="Select a folder containing the SVG images")

# Wrap the folder path in double quotes to handle spaces in the path
folder_path = f'"{folder_path}"'

# Create a folder named "png" in the same directory as the SVG images
png_folder_path = os.path.join(folder_path, "png")
os.makedirs(png_folder_path, exist_ok=True)

# Iterate over all files in the folder
for filename in os.listdir(folder_path):
    if filename.endswith(".svg"):
        # Construct the full path to the SVG file
        svg_path = os.path.join(folder_path, filename)

        # Convert SVG to PNG using ImageMagick
        png_filename = os.path.splitext(filename)[0] + ".png"
        png_path = os.path.join(png_folder_path, png_filename)
        subprocess.run(["convert", svg_path, "-background", "none", png_path])

        print(f"Converted {svg_path} to {png_path}")
