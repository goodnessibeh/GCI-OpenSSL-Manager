# GCI-OpenSSL-Manager

## Overview
This PowerShell script automates the process of updating OpenSSL library files across Windows systems. It's designed to be deployed via Microsoft Intune to ensure consistent security updates for OpenSSL libraries on managed devices.

## Features
- Downloads the latest OpenSSL installer from official sources
- Silently installs OpenSSL without user interaction
- Scans the entire system for existing OpenSSL DLL files
- Replaces outdated DLL files with the latest versions
- Handles files that are in use by scheduling them for replacement on next reboot
- Creates detailed logs and summary reports for monitoring and troubleshooting
- Automatically elevates permissions if needed

## Prerequisites
- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or higher
- Administrator privileges
- Internet connection to download the installer

## Installation
1. Download the `systemWideOpenSSLupdate.ps1` script from the GCI-OpenSSL-Manager repository
2. Deploy via Microsoft Intune as a PowerShell script:
   - In the Microsoft Endpoint Manager admin center, navigate to **Devices** > **Windows** > **PowerShell scripts**
   - Add the script with "Run this script using the logged-on credentials" set to No and "Run script in 64-bit PowerShell" set to Yes
   - Assign the script to your desired device groups

## Manual Execution
To run the script manually:

```powershell
.\OpenSSL_Update.ps1
```

The script will automatically request elevation if not running with administrator privileges.

## Configuration
You can customize the script by modifying these variables at the top:

```powershell
$logFile = "C:\ProgramData\OpenSSL_Update.log"
$opensslDownloadUrl = "https://slproweb.com/download/Win64OpenSSL-3_4_1.msi"
$downloadPath = "$env:USERPROFILE\Downloads\Win64OpenSSL-3_4_1.msi"
$tempExtractDir = "$env:USERPROFILE\Downloads\ExtractedDllFiles"
$installDir = "C:\Program Files\OpenSSL-Win64"
```

- `$logFile`: Path where logs will be stored
- `$opensslDownloadUrl`: URL to download the OpenSSL installer
- `$downloadPath`: Local path to save the downloaded installer
- `$tempExtractDir`: Temporary directory for extraction
- `$installDir`: Installation directory for OpenSSL

## Monitoring and Reporting
The script generates two key files for monitoring:

1. **Detailed Log File**: Located at `C:\ProgramData\OpenSSL_Update.log`
   - Contains step-by-step information about the execution process
   - Includes timestamps, progress updates, and any errors encountered

2. **Summary Report**: Located at `C:\ProgramData\OpenSSL_Update_Summary.txt`
   - Provides a concise summary of the update operation
   - Shows file counts, success rates, and per-DLL statistics

## Troubleshooting

### Common Issues
1. **Download Failures**
   - Check internet connectivity
   - Verify the download URL is current and accessible
   - Review proxy settings if applicable

2. **Installation Errors**
   - Ensure there are no conflicting OpenSSL installations
   - Verify the system has sufficient disk space
   - Check for pending reboots that might interfere with installation

3. **File Replacement Errors**
   - Some files may be locked by running processes
   - These will be scheduled for replacement on next reboot
   - Check the log file for specific file paths and error messages

### Log Analysis
For detailed troubleshooting, examine the log file at `C:\ProgramData\OpenSSL_Update.log`. Critical errors are highlighted in red within the console output and logged with timestamps.

## Security Considerations
- The script downloads files from trusted sources (slproweb.com)
- All downloaded files are verified before installation
- Original DLL files are backed up before replacement
- The script uses proper error handling and cleanup procedures

## Author
Goodness Caleb Ibeh

- GitHub: [github.com/goodnessibeh](https://github.com/goodnessibeh)
- LinkedIn: [linkedin.com/in/caleb-ibeh](https://linkedin.com/in/caleb-ibeh)

## License
[Specify your license information here]

## Version History
- 1.0.0: Initial release
- 1.0.1: Fixed parameter handling in error logs
- 1.1.0: Added improved progress reporting and status summary