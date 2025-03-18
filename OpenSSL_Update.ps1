# OpenSSL Update Script for Intune
# Author: Goodness Caleb Ibeh
# Description: This script searches for OpenSSL libraries and updates them with the latest version.

# Configuration
$logFile = "C:\ProgramData\OpenSSL_Update.log"
$opensslDownloadUrl = "https://slproweb.com/download/Win64OpenSSL-3_4_1.msi" # Get latest MSI download link from https://slproweb.com/products/Win32OpenSSL.html
$downloadPath = "$env:USERPROFILE\Downloads\Win64OpenSSL-3_4_1.msi"
$installDir = "$env:ProgramFiles\OpenSSL-Win64"
$opensslLibNames = @("libcrypto-3-x64.dll", "libssl-3-x64.dll", "libssl-3.dll", "libcrypto-3.dll", "libssl32.dll")

# Custom request headers
$headers = @{
    "Host" = "slproweb.com"
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
}

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

# Step 1: Download and Install OpenSSL
Log-Message "Downloading OpenSSL installer..."
try {
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
    
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("Host", "slproweb.com")
    $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
    $webClient.DownloadFile($opensslDownloadUrl, $downloadPath)
    
    Log-Message "OpenSSL installer downloaded successfully."
} catch {
    Log-Message "Error downloading OpenSSL: $_" -color "Red"
    exit 2
} finally {
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
}

# Step 2: Install OpenSSL
try {
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$downloadPath`" /quiet /norestart" -Wait
    Log-Message "OpenSSL installed successfully."
} catch {
    Log-Message "Error installing OpenSSL: $_" -color "Red"
    exit 3
}

# Step 3: Search for OpenSSL libraries
Log-Message "Searching for OpenSSL libraries..."
$foundLibs = Get-ChildItem -Path "C:\" -Recurse -Include $opensslLibNames -ErrorAction SilentlyContinue

if ($foundLibs.Count -eq 0) {
    Log-Message "No OpenSSL libraries found on the system." -color "Red"
    exit 4
}

# Log the number of found/discovered library files in yellow
Log-Message "Found $($foundLibs.Count) OpenSSL libraries on the system." -color "Yellow"

# Log found libraries
Log-Message "Found the following OpenSSL libraries:"
foreach ($lib in $foundLibs) {
    Log-Message "  - $($lib.FullName)" -color "Yellow"
}

# Step 4: Replace each found library with the latest version
$replacedLibs = @()
$notReplacedLibs = @()
foreach ($lib in $foundLibs) {
    $libName = $lib.Name
    $libPath = $lib.FullName
    $latestLibPath = Join-Path -Path $installDir -ChildPath $libName

    try {
        # Replace with the latest version (forcefully)
        if (Test-Path $latestLibPath) {
            Copy-Item -Path $latestLibPath -Destination $libPath -Force
            Log-Message "Updated $libPath with the latest version from $latestLibPath." -color "Green"
            $replacedLibs += $libPath
        } else {
            Log-Message "Latest version of $libName not found at $latestLibPath. Skipping replacement." -color "Red"
            $notReplacedLibs += $libPath
        }
    } catch {
        Log-Message "Error updating $libPath : $_" -color "Red"
        $notReplacedLibs += $libPath
    }
}

# Log replaced libraries
if ($replacedLibs.Count -gt 0) {
    Log-Message "Replaced the following OpenSSL libraries:" -color "Green"
    foreach ($lib in $replacedLibs) {
        Log-Message "  - $lib" -color "Green"
    }
} else {
    Log-Message "No OpenSSL libraries were replaced." -color "Yellow"
}

# Log libraries not replaced
if ($notReplacedLibs.Count -gt 0) {
    Log-Message "The following OpenSSL libraries were not replaced:" -color "Red"
    foreach ($lib in $notReplacedLibs) {
        Log-Message "  - $lib" -color "Red"
    }
}

# Step 5: Clean up downloaded installer
try {
    Remove-Item -Path $downloadPath -Force
    Log-Message "Downloaded installer cleaned up successfully."
} catch {
    Log-Message "Error cleaning up installer: $_" -color "Red"
    exit 6
}

Log-Message "OpenSSL library update process completed successfully."
exit 0