@echo off
echo ========================================
echo  NL2Q Analyst - Presentation Generator
echo ========================================
echo.
echo Choose an option:
echo  [1] Generate new presentation
echo  [2] Open latest presentation
echo  [3] Exit
echo.
set /p choice="Enter your choice (1-3): "

if "%choice%"=="1" (
    echo.
    echo Generating presentation...
    python enterprise_deck_generator.py
    pause
) else if "%choice%"=="2" (
    echo.
    echo Opening latest presentation...
    powershell -ExecutionPolicy Bypass -File open-latest.ps1
) else if "%choice%"=="3" (
    exit
) else (
    echo Invalid choice!
    pause
)
