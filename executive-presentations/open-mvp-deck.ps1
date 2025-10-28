# Quick launcher for NL2Q MVP Deck
# Opens the most recently generated MVP presentation

$outputsDir = "outputs"
$latestPptx = Get-ChildItem -Path $outputsDir -Filter "nl2q_analyst_mvp_conexus_*.pptx" | 
              Sort-Object LastWriteTime -Descending | 
              Select-Object -First 1

if ($latestPptx) {
    Write-Host "🎯 Opening latest MVP deck: $($latestPptx.Name)" -ForegroundColor Green
    Write-Host "📊 Size: $([math]::Round($latestPptx.Length/1MB, 2)) MB" -ForegroundColor Cyan
    Write-Host "📅 Created: $($latestPptx.LastWriteTime)" -ForegroundColor Cyan
    Start-Process $latestPptx.FullName
} else {
    Write-Host "❌ No MVP deck found in outputs folder" -ForegroundColor Red
    Write-Host "💡 Run: python nl2q_mvp_deck_generator.py" -ForegroundColor Yellow
}
