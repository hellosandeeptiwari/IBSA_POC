# Quick PowerPoint Generation Script
# Generates enterprise PPTX presentation with one command

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Enterprise PowerPoint Generator" -ForegroundColor White
Write-Host "  NL2Q Analytics" -ForegroundColor Gray
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

Write-Host "🎨 Generating PowerPoint presentation..." -ForegroundColor Yellow
Write-Host ""

python pptx_generator.py

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Generation successful!" -ForegroundColor Green
    Write-Host ""
    
    $choice = Read-Host "Would you like to open the presentation now? (Y/N)"
    
    if ($choice -eq 'Y' -or $choice -eq 'y') {
        .\open-latest-pptx.ps1
    }
} else {
    Write-Host ""
    Write-Host "❌ Generation failed. Check errors above." -ForegroundColor Red
    Write-Host ""
}

Read-Host "Press Enter to exit"
