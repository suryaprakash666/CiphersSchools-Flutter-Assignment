# Copy the universal APK to the project's root directory
$sourcePath = ".\android\app\build\outputs\flutter-apk\app-release.apk"
$destPath = ".\release-app.apk"

# Check if source file exists
if (Test-Path $sourcePath) {
    # Copy the file
    Copy-Item -Path $sourcePath -Destination $destPath -Force
    Write-Host "APK copied successfully to $destPath" -ForegroundColor Green
    
    # Get file size in MB
    $fileSize = (Get-Item $destPath).Length / 1MB
    Write-Host "APK size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Cyan
} else {
    Write-Host "Error: Could not find the APK file at $sourcePath" -ForegroundColor Red
    
    # Try to find APKs in the project
    $apkFiles = Get-ChildItem -Path . -Filter *.apk -Recurse -ErrorAction SilentlyContinue
    
    if ($apkFiles.Count -gt 0) {
        Write-Host "Found these APK files instead:" -ForegroundColor Yellow
        foreach ($file in $apkFiles) {
            Write-Host "- $($file.FullName)" -ForegroundColor Yellow
        }
    }
}
