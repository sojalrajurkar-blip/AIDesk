# PowerShell Packaging Script for Windows Desktop Installer and Portable Bundle
param (
    [switch]$BuildRelease = $true
)

$ErrorActionPreference = "Stop"
$FrontendDir = $PSScriptRoot
Set-Location $FrontendDir

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " Building & Packaging DeskAI Windows Desktop App     " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

if ($BuildRelease) {
    Write-Host "`n[1/3] Compiling Flutter Windows Release..." -ForegroundColor Yellow
    flutter build windows --release
}

$ReleaseDir = "$FrontendDir\build\windows\x64\runner\Release"
$OutputDir = "$FrontendDir\build\installer"

if (-not (Test-Path $ReleaseDir)) {
    Write-Error "Release directory not found at $ReleaseDir. Build may have failed."
    exit 1
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Write-Host "`n[2/3] Checking for Inno Setup Compiler (ISCC.exe)..." -ForegroundColor Yellow
$InnoPaths = @(
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe",
    "C:\Program Files (x86)\Inno Setup 5\ISCC.exe"
)

$ISCC = $null
foreach ($path in $InnoPaths) {
    if (Test-Path $path) {
        $ISCC = $path
        break
    }
}

if ($ISCC) {
    Write-Host "Found Inno Setup at: $ISCC" -ForegroundColor Green
    Write-Host "Compiling standalone setup installer (.exe)..." -ForegroundColor Green
    & $ISCC "$FrontendDir\windows\inno_setup.iss"
    Write-Host "`n Setup Installer created: $OutputDir\DeskAI_Operations_Setup_v1.0.exe" -ForegroundColor Green
} else {
    Write-Host "Inno Setup not detected on PATH. Creating Standalone Portable Package (.zip)..." -ForegroundColor Yellow
    $ZipPath = "$OutputDir\DeskAI_Operations_Windows_x64.zip"
    if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
    Compress-Archive -Path "$ReleaseDir\*" -DestinationPath $ZipPath -Force
    Write-Host "`n Standalone Portable Bundle created: $ZipPath" -ForegroundColor Green
    Write-Host "To create an installer wizard .exe, install Inno Setup 6 (free from jrsoftware.org) and re-run this script." -ForegroundColor Gray
}

Write-Host "`n[3/3] Packaging Complete!" -ForegroundColor Cyan
