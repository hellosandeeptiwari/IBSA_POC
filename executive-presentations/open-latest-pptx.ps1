# Open Latest PowerPoint Presentation
# Finds and opens the most recently created PPTX file

$outputPath = Join-Path $PSScriptRoot "outputs"

if (-not (Test-Path $outputPath)) {
    Write-Host "❌ Outputs folder not found. Generate a presentation first." -ForegroundColor Red
    Read-Host "Press Enter to continue"
    exit
}

$latestPPTX = Get-ChildItem -Path $outputPath -Filter "*.pptx" | 
              Sort-Object LastWriteTime -Descending | 
              Select-Object -First 1

if ($null -eq $latestPPTX) {
    Write-Host "❌ No PPTX files found in outputs folder." -ForegroundColor Red
    Write-Host "💡 Run the generator first to create a presentation." -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
    exit
}

Write-Host "🚀 Opening: $($latestPPTX.Name)" -ForegroundColor Green
Write-Host "📅 Created: $($latestPPTX.LastWriteTime)" -ForegroundColor Cyan

Start-Process $latestPPTX.FullName

Write-Host "✅ PowerPoint should open shortly..." -ForegroundColor Green
