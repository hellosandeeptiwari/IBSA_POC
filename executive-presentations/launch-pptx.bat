@echo off
title Enterprise PowerPoint Generator
color 0A

echo.
echo ============================================
echo   Enterprise PowerPoint (PPTX) Generator
echo   NL2Q Analytics - Executive Presentations
echo ============================================
echo.

:MENU
echo.
echo Please select an option:
echo.
echo [1] Generate New PowerPoint Presentation
echo [2] Open Latest PPTX File
echo [3] Open Outputs Folder
echo [4] Exit
echo.

set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" goto GENERATE
if "%choice%"=="2" goto OPEN_LATEST
if "%choice%"=="3" goto OPEN_FOLDER
if "%choice%"=="4" goto EXIT

echo Invalid choice. Please try again.
goto MENU

:GENERATE
echo.
echo Generating PowerPoint presentation...
echo.
python pptx_generator.py
echo.
echo Generation complete!
pause
goto MENU

:OPEN_LATEST
echo.
echo Opening latest PPTX file...
powershell -ExecutionPolicy Bypass -File "open-latest-pptx.ps1"
goto MENU

:OPEN_FOLDER
echo.
echo Opening outputs folder...
start "" "outputs"
goto MENU

:EXIT
echo.
echo Thank you for using Enterprise PPTX Generator!
echo.
timeout /t 2 >nul
exit
