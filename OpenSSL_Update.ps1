# OpenSSL Update Script for Intune
# Author: Goodness Caleb Ibeh
# Description: This script downloads OpenSSL, extracts it, runs the installer silently, and replaces matching DLLs across the system.

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

# Function to display a progress bar
function Show-Progress {
    param (
        [string]$activity,
        [int]$percentComplete,
        [string]$status = ""
    )
    
    Write-Progress -Activity $activity -Status $status -PercentComplete $percentComplete
    
    # Also add a visual terminal-based progress bar for non-GUI environments
    $progressBarWidth = 50
    $completedWidth = [math]::Floor(($progressBarWidth * $percentComplete) / 100)
    $remainingWidth = $progressBarWidth - $completedWidth
    
    $progressBar = "[" + ("=" * $completedWidth) + (" " * $remainingWidth) + "]"
    $progressDisplay = "$progressBar $percentComplete% $status"
    
    Write-Host "`r$progressDisplay" -NoNewline
    
    if ($percentComplete -eq 100) {
        Write-Host ""  # Add a newline at 100%
    }
    
    # Also log the progress to the log file
    if (($percentComplete -eq 0) -or ($percentComplete -eq 100) -or ($percentComplete % 20 -eq 0)) {
        Log-Message "Progress: $activity - $percentComplete% complete - $status"
    }
}

# Start logging
Log-Message "Starting OpenSSL library update process."

# Step 1: Download OpenSSL installer
Log-Message "Downloading OpenSSL installer..."
try {
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
    
    # Create a temporary file for tracking download progress
    $progressFile = "$env:TEMP\openssl_download_progress.txt"
    
    # PowerShell 5.1 compatible download with progress
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("Host", "slproweb.com")
    $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0.0 Safari/537.36")
    
    # Get file size first to calculate progress
    $request = [System.Net.WebRequest]::Create($opensslDownloadUrl)
    $request.Method = "HEAD"
    try {
        $response = $request.GetResponse()
        $totalBytes = [long]$response.Headers["Content-Length"]
        $response.Close()
    } catch {
        Log-Message "Unable to determine file size, proceeding with download without progress indication." -color "Yellow"
        $totalBytes = 0
    }
    
    # Start download in background
    $job = Start-Job -ScriptBlock {
        param($url, $path, $progressFile, $totalBytes)
        
        try {
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("Host", "slproweb.com")
            $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0.0 Safari/537.36")
            
            if ($totalBytes -gt 0) {
                # Simple download with file writing
                "0" | Out-File -FilePath $progressFile -Force
                $webClient.DownloadFile($url, $path)
                "100" | Out-File -FilePath $progressFile -Force
            } else {
                # Simple download without progress tracking
                $webClient.DownloadFile($url, $path)
                "100" | Out-File -FilePath $progressFile -Force
            }
        } catch {
            "Error: $_" | Out-File -FilePath $progressFile -Force
            throw $_
        }
    } -ArgumentList $opensslDownloadUrl, $downloadPath, $progressFile, $totalBytes
    
    # Show progress while waiting for download
    $lastProgress = 0
    $downloadError = $null
    
    while ($true) {
        Start-Sleep -Milliseconds 500
        
        if (Test-Path $progressFile) {
            $content = Get-Content -Path $progressFile -Raw
            
            if ($content -match "^Error:") {
                $downloadError = $content
                break
            }
            
            if ($content -match "^\d+$") {
                $progress = [int]$content
                
                if ($progress -ne $lastProgress) {
                    $lastProgress = $progress
                    
                    if ($totalBytes -gt 0) {
                        $downloadedBytes = [math]::Round(($progress / 100) * $totalBytes)
                        $status = "$([math]::Round($downloadedBytes / 1MB, 2)) MB of $([math]::Round($totalBytes / 1MB, 2)) MB"
                    } else {
                        $status = "$progress% complete"
                    }
                    
                    Show-Progress -Activity "Downloading OpenSSL installer" -Status $status -PercentComplete $progress
                }
                
                if ($progress -eq 100) {
                    break
                }
            }
        }
        
        # Check if job has completed or failed
        if ($job.State -eq "Completed") {
            Show-Progress -Activity "Downloading OpenSSL installer" -Status "Complete" -PercentComplete 100
            break
        } elseif ($job.State -eq "Failed") {
            $downloadError = $job.ChildJobs[0].Error.ToString()
            break
        }
    }
    
    # Cleanup job and progress file
    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $progressFile -Force -ErrorAction SilentlyContinue
    
    if ($downloadError) {
        throw $downloadError
    }
    
    if (Test-Path $downloadPath) {
        Log-Message "OpenSSL installer downloaded successfully."
    } else {
        throw "Download completed but file not found at $downloadPath"
    }
} catch {
    # Safely handle the error message
    $errorMsg = $_.ToString() -replace '&', '`&'
    Log-Message "Error downloading OpenSSL: $errorMsg" -color "Red"
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
    # Safely handle the error message
    $errorMsg = $_.ToString() -replace '&', '`&'
    Log-Message "Error extracting OpenSSL files: $errorMsg" -color "Red"
    exit 3
}

# Step 3: Run the installer to install OpenSSL completely silently
Log-Message "Running the installer to install OpenSSL silently in the background..."
try {
    # First option: Direct MSI installation (more reliable for silent installation)
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$downloadPath`" /qn /norestart INSTALLDIR=`"$installDir`"" -Wait -WindowStyle Hidden
    
    # Check if installation was successful by verifying key files
    if ((Test-Path "$installDir\libcrypto-3-x64.dll") -and (Test-Path "$installDir\libssl-3-x64.dll")) {
        Log-Message "OpenSSL installed successfully using direct MSI installation."
    } else {
        Log-Message "Direct MSI installation may not have completed. Trying alternative method..." -color "Yellow"
        
        # Alternative method: Find and run the extracted installer if available
        $installerPath = Get-ChildItem -Path $tempExtractDir -Include "setup-*.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($installerPath) {
            # Use hidden window and verysilent parameter to ensure no UI appears
            Start-Process -FilePath $installerPath.FullName -ArgumentList "/verysilent /suppressmsgboxes /norestart /sp- /nocancel" -Wait -WindowStyle Hidden
            
            if ((Test-Path "$installDir\libcrypto-3-x64.dll") -and (Test-Path "$installDir\libssl-3-x64.dll")) {
                Log-Message "OpenSSL installed successfully using extracted installer."
            } else {
                Log-Message "Installation could not be verified. Files may not be in expected location." -color "Yellow"
            }
        } else {
            Log-Message "Installer not found in the extracted folder." -color "Red"
            exit 7
        }
    }
} catch {
    # Safely handle the error message
    $errorMsg = $_.ToString() -replace '&', '`&'
    Log-Message "Error installing OpenSSL: $errorMsg" -color "Red"
    exit 4
}

# Step 4: Clean up downloaded installer and extracted files
try {
    Remove-Item -Path $tempExtractDir -Recurse -Force
    Remove-Item -Path $downloadPath -Force
    Log-Message "Downloaded installer and extracted files cleaned up successfully."
} catch {
    # Safely handle the error message
    $errorMsg = $_.ToString() -replace '&', '`&'
    Log-Message "Error cleaning up installer and extracted files: $errorMsg" -color "Red"
    exit 5
}

# Step 5: Replace all matching DLL files on the system with the new versions
Log-Message "Starting replacement of DLL files across the system..."

$dllsToReplace = @(
    "libcrypto-3-x64.dll",
    "libssl-3-x64.dll"
)

# Initialize counters for summary
$totalFilesFound = 0
$filesReplaced = 0
$filesScheduledForReboot = 0
$filesWithErrors = 0
$filesByDll = @{}

foreach ($dllFile in $dllsToReplace) {
    $sourcePath = Join-Path -Path $installDir -ChildPath $dllFile
    $filesByDll[$dllFile] = @{
        Found = 0
        Replaced = 0
        Scheduled = 0
        Errors = 0
    }
    
    if (Test-Path $sourcePath) {
        Log-Message "Finding all instances of $dllFile to replace..."
        Show-Progress -Activity "Searching for $dllFile files" -Status "Scanning C: drive" -PercentComplete 0
        
        # Find all instances of the DLL file on C: drive, excluding the OpenSSL installation directory
        try {
            $filesToReplace = Get-ChildItem -Path "C:\" -Filter $dllFile -Recurse -ErrorAction SilentlyContinue -Force | 
                              Where-Object { $_.FullName -notlike "$installDir*" }
            
            $fileCount = $filesToReplace.Count
            $filesByDll[$dllFile].Found = $fileCount
            $totalFilesFound += $fileCount
            
            Log-Message "Found $fileCount instances of $dllFile to replace."
            Show-Progress -Activity "Searching for $dllFile files" -Status "Found $fileCount files" -PercentComplete 100
            
            # Process each file
            for ($i = 0; $i -lt $fileCount; $i++) {
                $file = $filesToReplace[$i]
                $percentComplete = [math]::Round(($i / $fileCount) * 100)
                $currentFile = $file.FullName
                Show-Progress -Activity "Replacing $dllFile files" -Status "Processing $($i+1) of $fileCount - $currentFile" -PercentComplete $percentComplete
                
                try {
                    # Check if we have write access to the file
                    $fileInfo = New-Object System.IO.FileInfo($file.FullName)
                    if ($fileInfo.IsReadOnly) {
                        # Remove read-only attribute
                        Set-ItemProperty -Path $file.FullName -Name IsReadOnly -Value $false
                        Log-Message "Removed read-only attribute from $($file.FullName)"
                    }
                    
                    # Check if file is in use
                    $inUse = $false
                    try {
                        $fileStream = [System.IO.File]::Open($file.FullName, 'Open', 'ReadWrite', 'None')
                        $fileStream.Close()
                        $fileStream.Dispose()
                    } catch {
                        $inUse = $true
                    }
                    
                    if ($inUse) {
                        Log-Message "File $($file.FullName) is in use. Marking for replacement on next reboot." -color "Yellow"
                        # Use the MoveFileEx API to replace on reboot
                        $source = $sourcePath
                        $destination = $file.FullName
                        $MOVEFILE_REPLACE_EXISTING = 0x1
                        $MOVEFILE_DELAY_UNTIL_REBOOT = 0x4
                        
                        # Define the P/Invoke method
                        Add-Type -TypeDefinition @"
                        using System;
                        using System.Runtime.InteropServices;
                        
                        public class MoveFileUtil {
                            [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
                            public static extern bool MoveFileEx(string lpExistingFileName, string lpNewFileName, int dwFlags);
                        }
"@
                        
                        # Schedule the file replacement on next reboot
                        [MoveFileUtil]::MoveFileEx($source, $destination, $MOVEFILE_REPLACE_EXISTING -bor $MOVEFILE_DELAY_UNTIL_REBOOT)
                        Log-Message "Scheduled replacement of $destination with $source on next reboot"
                        
                        $filesScheduledForReboot++
                        $filesByDll[$dllFile].Scheduled++
                    } else {
                        # Backup the original file
                        $backupPath = "$($file.FullName).backup"
                        Copy-Item -Path $file.FullName -Destination $backupPath -Force
                        Log-Message "Created backup at $backupPath"
                        
                        # Replace the file
                        Copy-Item -Path $sourcePath -Destination $file.FullName -Force
                        Log-Message "Successfully replaced $($file.FullName)" -color "Green"
                        
                        $filesReplaced++
                        $filesByDll[$dllFile].Replaced++
                    }
                } catch {
                    # Safely handle the error message
                    $errorMsg = $_.ToString() -replace '&', '`&'
                    Log-Message "Error replacing $($file.FullName): $errorMsg" -color "Red"
                    $filesWithErrors++
                    $filesByDll[$dllFile].Errors++
                }
            }
            
            # Show 100% completion for this DLL
            Show-Progress -Activity "Replacing $dllFile files" -Status "Completed $fileCount files" -PercentComplete 100
        } catch {
            # Safely handle the error message
            $errorMsg = $_.ToString() -replace '&', '`&'
            Log-Message "Error searching for $dllFile - $errorMsg" -color "Red"
        }
    } else {
        Log-Message "Source file $sourcePath not found. Skipping replacement." -color "Yellow"
    }
}

# Generate detailed results summary
Log-Message "===== OpenSSL Update Results Summary =====" -color "Cyan"
Log-Message "Total DLL files found across system: $totalFilesFound" -color "White"
Log-Message "Files successfully replaced: $filesReplaced" -color "Green"
Log-Message "Files scheduled for replacement at next reboot: $filesScheduledForReboot" -color "Yellow"
Log-Message "Files with errors during replacement: $filesWithErrors" -color "Red"
Log-Message "" 

# Per-DLL breakdown
foreach ($dll in $dllsToReplace) {
    if ($filesByDll.ContainsKey($dll)) {
        $stats = $filesByDll[$dll]
        Log-Message "$dll Summary:" -color "Cyan"
        Log-Message "  - Found: $($stats.Found)" -color "White"
        Log-Message "  - Successfully replaced: $($stats.Replaced)" -color "Green"
        Log-Message "  - Scheduled for reboot: $($stats.Scheduled)" -color "Yellow"
        Log-Message "  - Errors: $($stats.Errors)" -color "Red"
    }
}

Log-Message "" 
Log-Message "OpenSSL library update process completed successfully."

# Create a summary file that can be read by Intune
$summaryFile = "C:\ProgramData\OpenSSL_Update_Summary.txt"
try {
    $summaryContent = @"
OPENSSL UPDATE SUMMARY
=====================
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Total files found: $totalFilesFound
Files replaced: $filesReplaced
Files scheduled for reboot: $filesScheduledForReboot
Files with errors: $filesWithErrors

DLL-SPECIFIC RESULTS
===================
"@

    foreach ($dll in $dllsToReplace) {
        if ($filesByDll.ContainsKey($dll)) {
            $stats = $filesByDll[$dll]
            $summaryContent += @"
$dll
  Found: $($stats.Found)
  Replaced: $($stats.Replaced)
  Scheduled: $($stats.Scheduled)
  Errors: $($stats.Errors)

"@
        }
    }
    
    Set-Content -Path $summaryFile -Value $summaryContent
    Log-Message "Results summary saved to $summaryFile"
} catch {
    # Safely handle the error message
    $errorMsg = $_.ToString() -replace '&', '`&'
    Log-Message "Error saving summary: $errorMsg" -color "Red"
}

exit 0