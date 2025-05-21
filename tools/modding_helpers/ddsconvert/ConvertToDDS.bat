@echo off
echo PNG to DDS Converter (with _FD darkening)
echo =======================================
echo This script will convert all PNG files in this directory to DDS format
echo Files with "_FD" in the name can be darkened before conversion
echo.

rem Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed or not in the PATH.
    echo Please install Python from https://www.python.org/downloads/
    echo.
    pause
    exit /b 1
)

rem Check if PIL/Pillow is installed
python -c "from PIL import Image" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python Imaging Library PIL/Pillow is not installed.
    echo.
    echo Installing Pillow...
    python -m pip install pillow
    if %errorlevel% neq 0 (
        echo Failed to install Pillow. Please install it manually with:
        echo python -m pip install pillow
        pause
        exit /b 1
    )
    echo Pillow installed successfully!
    echo.
)

rem Check if texconv.exe exists
if not exist texconv.exe (
    echo WARNING: texconv.exe is not in the current directory.
    echo.
    echo Please download texconv.exe from:
    echo https://github.com/microsoft/DirectXTex/releases
    echo.
    echo You need to download the latest "texconv.exe" and place it in this folder.
    echo.
    pause
    exit /b 1
)

echo Running conversion script...
python png_to_dds.py