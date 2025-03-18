# GCI-OpenSSL-Manager
# GCI-OpenSSL-Manager

## Overview
**GCI-OpenSSL-Manager** is a PowerShell script designed to automatically update OpenSSL libraries on Windows systems. The script scans the system for existing OpenSSL library files and replaces them with the latest version. It can be used as a **Platform Script in Microsoft Intune** for enterprise deployments or executed **locally on a Windows machine** with administrative privileges.

## Features
- Downloads the latest OpenSSL installer from a trusted source.
- Installs OpenSSL silently without user intervention.
- Scans the system for outdated OpenSSL library files.
- Replaces old library files with the latest versions.
- Generates detailed logs for auditing and troubleshooting.

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

2. **Run the script with administrator privileges:**
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

## Logging & Troubleshooting
The script logs all activities to:
```
C:\ProgramData\OpenSSL_Update.log
```
If any errors occur, review the log file for detailed information.

## License
This project is licensed under the MIT License.

## Author
**Goodness Caleb Ibeh** – [GCI Cyber LLC](https://yourcompanywebsite.com)

---
Feel free to contribute, suggest improvements, or report issues!

