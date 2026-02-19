import os
import subprocess
import tkinter as tk
from tkinter import filedialog
from rembg import remove
from PIL import Image

import importlib.util

if importlib.util.find_spec('rembg') is None:
    subprocess.check_call(["python", '-m', 'pip', 'install', 'rembg'])

root = tk.Tk()
root.withdraw()

input_folder = filedialog.askdirectory(title="Select Input Folder")

output_folder = input_folder + "_png"
os.makedirs(output_folder, exist_ok=True)

for filename in os.listdir(input_folder):
    if filename.endswith('.svg') or filename.endswith('.png'):
        input_path = os.path.join(input_folder, filename)
        output_path = os.path.join(output_folder, filename.split('.')[0] + '.png')

        input_image = Image.open(input_path)
        input_resized = input_image.resize((900, 900))
        output_image = remove(input_resized)
        
        imageBox = output_image.getbbox()
        cropped = output_image.crop(imageBox)
        cropped.save(output_path.split('.')[0] + '_cropped.png')

        print(f"Removed background from {filename}")