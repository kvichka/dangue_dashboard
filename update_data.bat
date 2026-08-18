@echo off
cd /d "%~dp0"
echo Checking for Python...
where python >nul 2>nul
if errorlevel 1 (
    echo.
    echo ERROR: Python was not found on this computer, or it's not on your PATH.
    echo Install it from https://python.org and try again.
    pause
    exit /b 1
)
echo Checking for openpyxl...
python -c "import openpyxl" >nul 2>nul
if errorlevel 1 (
    echo Installing openpyxl, one time only...
    python -m pip install openpyxl
)
python update_data.py
