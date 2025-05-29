import os
import subprocess
import sys
from PIL import Image, ImageEnhance

def convert_png_to_dds():
    """
    Converts all PNG files in the current directory to DDS format using texconv.exe
    Can darken images with '_FD' in their filename
    """
    script_dir = os.path.dirname(os.path.abspath(__file__))
    if not script_dir:
        script_dir = os.getcwd()
    
    texconv_path = os.path.join(script_dir, "texconv.exe")
    
    if not os.path.exists(texconv_path):
        print("ERROR: texconv.exe not found in the same directory as this script.")
        print("Please download texconv.exe from https://github.com/microsoft/DirectXTex/releases")
        print("and place it in the same directory as this script.")
        return False
    
    png_files = [f for f in os.listdir(script_dir) if f.lower().endswith('.png')]
    
    if not png_files:
        print("No PNG files found in the current directory.")
        return False
    
    print(f"Found {len(png_files)} PNG files to process:")
    for png in png_files:
        print(f"  - {png}")
    
    success_count = 0
    for png_file in png_files:
        png_path = os.path.join(script_dir, png_file)
        dds_file = os.path.splitext(png_file)[0] + '.dds'
        
        try:
            is_lightmap = '_FD' in png_file
            
            if is_lightmap:
                print(f"Processing lightmap {png_file}...")
                
                temp_png = os.path.join(script_dir, "_temp_" + png_file)
                
                with Image.open(png_path) as img:
                    darkness_factor = 1.0  # <-- CHANGE THIS VALUE TO ADJUST DARKNESS

                    enhancer = ImageEnhance.Brightness(img)
                    darkened = enhancer.enhance(darkness_factor)
                    
                    darkened.save(temp_png)
                
                source_png = temp_png
            else:
                source_png = png_path

            cmd = [
                texconv_path, 
                "-y", 
                "-f", "DXT5", 
                "-m", "1", 
                "-nologo", 
                "-o", script_dir, 
                source_png
            ]
            
            print(f"Converting {png_file} to DDS...")
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if is_lightmap and os.path.exists(temp_png):
                os.remove(temp_png)
                temp_dds = os.path.join(script_dir, "_temp_" + os.path.splitext(png_file)[0] + '.dds')
                final_dds = os.path.join(script_dir, dds_file)
                if os.path.exists(temp_dds) and temp_dds != final_dds:
                    if os.path.exists(final_dds):
                        os.remove(final_dds)
                    os.rename(temp_dds, final_dds)
            
            if result.returncode == 0:
                success_count += 1
                print(f"  Success: Created {dds_file}")
            else:
                print(f"  Error converting {png_file}: {result.stderr}")
        
        except Exception as e:
            print(f"  Error processing {png_file}: {str(e)}")
    
    print(f"\nConversion complete! Converted {success_count} of {len(png_files)} files.")
    print("Press Enter to exit...")
    
    return True

if __name__ == "__main__":
    convert_png_to_dds()
    input()