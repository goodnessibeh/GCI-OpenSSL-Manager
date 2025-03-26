# OpenSSL Update Script for Intune
# Author: Goodness Caleb Ibeh
# Description: This script downloads OpenSSL, extracts it, and runs the installer silently.

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires administrative privileges. Restarting with elevated permissions..."
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Configuration
$logFile = "C:\ProgramData\OpenSSL_Update.log"
$opensslDownloadUrl = "https://slproweb.com/download/Win64OpenSSL-3_4_1.msi"
$downloadPath = "$env:USERPROFILE\Downloads\Win64OpenSSL-3_4_1.msi"
$tempExtractDir = "$env:USERPROFILE\Downloads\ExtractedDllFiles"
$installDir = "C:\Program Files\OpenSSL-Win64"

# Function to log messages
function Log-Message {
    param (
        [string]$message,
        [string]$color = "White"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$timestamp] $message"
    Write-Host "[$timestamp] $message" -ForegroundColor $color
}

# Start logging
Log-Message "Starting OpenSSL library update process."

# Step 1: Download OpenSSL installer
Log-Message "Downloading OpenSSL installer..."
try {
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
    
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("Host", "slproweb.com")
    $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0.0 Safari/537.36")
    $webClient.DownloadFile($opensslDownloadUrl, $downloadPath)
    
    Log-Message "OpenSSL installer downloaded successfully."
} catch {
    Log-Message "Error downloading OpenSSL: $_" -color "Red"
    exit 2
} finally {
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
}

# Step 2: Extract OpenSSL to a temporary folder
Log-Message "Extracting OpenSSL files to $tempExtractDir..."
try {
    New-Item -Path $tempExtractDir -ItemType Directory -Force
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/a `"$downloadPath`" TARGETDIR=`"$tempExtractDir`" /quiet" -Wait
    Log-Message "OpenSSL files extracted successfully."
} catch {
    Log-Message "Error extracting OpenSSL files: $_" -color "Red"
    exit 3
}

# Step 3: Run the extracted installer to install OpenSSL silently
Log-Message "Running the extracted installer to install OpenSSL silently..."
try {
    $installerPath = Get-ChildItem -Path $tempExtractDir -Include "setup-*.exe" -Recurse -ErrorAction Stop | Select-Object -First 1
    if ($installerPath) {
        Start-Process -FilePath $installerPath.FullName -ArgumentList "/silent /norestart" -Wait -NoNewWindow
        Log-Message "OpenSSL installed successfully."
    } else {
        Log-Message "Installer not found in the extracted folder." -color "Red"
        exit 7
    }
} catch {
    Log-Message "Error installing OpenSSL: $_" -color "Red"
    exit 4
}

# Step 4: Clean up downloaded installer and extracted files
try {
    Remove-Item -Path $tempExtractDir -Recurse -Force
    Remove-Item -Path $downloadPath -Force
    Log-Message "Downloaded installer and extracted files cleaned up successfully."
} catch {
    Log-Message "Error cleaning up installer and extracted files: $_" -color "Red"
    exit 5
}

Log-Message "OpenSSL library update process completed successfully."
exit 0