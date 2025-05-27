import os
from PIL import Image
import pillow_avif
from multiprocessing import Pool, cpu_count

# pip install imageconvert pillow pillow_avif (dependency)

def convert_image(args):
    input_path, output_path, quality = args
    try:
        img = Image.open(input_path)
        img.save(output_path, format="AVIF", quality=quality)
        print(f"Converted {input_path} to {output_path}")
    except Exception as e:
        print(f"Error converting {input_path}: {e}")

def batch_convert(input_folder, output_folder, prefix="YOURPREFIX-", quality=80):
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    files = [
        (os.path.join(input_folder, f),
         os.path.join(output_folder, f"{prefix}{os.path.splitext(f)[0]}.avif"),
         quality)
        for f in os.listdir(input_folder)
        if f.lower().endswith(('.jpg', '.jpeg', '.png'))
    ]

    pool = Pool(processes=cpu_count())
    pool.map(convert_image, files)
    pool.close()
    pool.join()

if __name__ == "__main__":
    input_dir = r"C:\put\your\image\dir\here"
    output_dir = r"C:\your\output\directory"

    batch_convert(input_dir, output_dir)