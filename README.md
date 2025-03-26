# GCI-OpenSSL-Manager

## Author
Goodness Caleb Ibeh

## Overview
**GCI-OpenSSL-Manager** is a PowerShell script designed to automatically update OpenSSL libraries on Windows systems. The script Downloads the latest version of the Open SSL installer, installs silently and scans the system for existing OpenSSL library files and replaces them with the latest version. It can be used as a **Platform Script in Microsoft Intune** for enterprise deployments or executed **locally on a Windows machine** with administrative privileges.

## Features
- Ensures the script runs with administrative privileges.
- Downloads the latest OpenSSL installer from a trusted source.
- Installs OpenSSL silently without user intervention.
- Scans the system for outdated OpenSSL library files.
- Replaces old library files with the latest versions.
- Generates detailed logs for auditing and troubleshooting.
- Cleans up temporary files after installation.

## Prerequisites
Before running the script, ensure the following requirements are met:

- Windows 10, Windows 11, or Windows Server.
- PowerShell with administrative privileges.
- Internet access to download the OpenSSL installer.
- Microsoft Intune (for deployment as a Platform Script).

## Installation & Usage

### 1. Running Locally on Windows

1. **Clone the repository:**
   ```sh
   git clone https://github.com/yourusername/GCI-OpenSSL-Manager.git
   cd GCI-OpenSSL-Manager
   ```

2. **Get the latest OpenSSL MSI file download link from the URL and parse it to the variable `$opensslDownloadUrl`:**
   ```sh
   https://slproweb.com/products/Win32OpenSSL.html
   ```

3. **Run the script with administrator privileges:**
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   .\OpenSSL_Update.ps1
   ```

### 2. Deploying via Microsoft Intune
This script can be used as a **Platform Script** in Intune for automated enterprise-wide deployment.

#### Steps to Deploy:
1. Sign in to the **Microsoft Intune Admin Center**.
2. Navigate to **Devices > Scripts**.
3. Click **Add > Windows 10 and later**.
4. Upload the `OpenSSL_Update.ps1` script.
5. Configure execution settings:
   - Run this script using the **System context**.
   - Enforce script execution with **Bypass execution policy**.
   - Enable script logging for troubleshooting.
6. Assign the script to the appropriate device groups.
7. Click **Save** and deploy the script.

## Log File
All script activities are logged to:
```
C:\ProgramData\OpenSSL_Update.log
```
This file can be reviewed for troubleshooting purposes.

## Troubleshooting
| Issue | Possible Cause | Solution |
|--------|----------------|-----------|
| Script does not run | Lack of admin privileges | Right-click PowerShell and select "Run as Administrator" |
| Download failure | Internet connection issues | Check network connectivity and retry |
| Installation failure | MSI extraction issue | Ensure enough disk space and rerun script |
| Cleanup failure | Files in use | Manually delete `Downloads\ExtractedDllFiles` and MSI file |

## License
This project is licensed under the MIT License.

## Disclaimer
This script downloads OpenSSL from `https://slproweb.com`. Always verify the URL and check the official OpenSSL website for the latest releases.

## Author Contact
For support or inquiries, contact Goodness Caleb Ibeh via [LinkedIn](https://www.linkedin.com/in/caleb-ibeh) or [GitHub](https://github.com/goodnessibeh).

---
Feel free to contribute, suggest improvements, or report issues!

