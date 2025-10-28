# Quick Launch Script for Generated Presentations
# Run this to open the most recent presentation in your browser

$outputDir = "outputs"
$latestFile = Get-ChildItem -Path $outputDir -Filter "*.html" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1

if ($latestFile) {
    Write-Host "🚀 Opening latest presentation: $($latestFile.Name)" -ForegroundColor Green
    Start-Process $latestFile.FullName
} else {
    Write-Host "❌ No presentations found. Run 'python enterprise_deck_generator.py' first." -ForegroundColor Red
}
