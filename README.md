# PowerShell Endpoint Automation Library

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
![Platform: Windows](https://img.shields.io/badge/Platform-Windows-0078D4)
![Shell: PowerShell](https://img.shields.io/badge/Shell-PowerShell-5391FE?logo=powershell&logoColor=white)
![Repository Type: Script Library](https://img.shields.io/badge/Type-Script%20Library-5C2D91)
![Inventory: 176 PS1 and 34 VBS](https://img.shields.io/badge/Inventory-176%20PS1%20%7C%2034%20VBS-4B5563)

Windows focused admin scripts for software lifecycle, endpoint configuration, security, reporting, and ConfigMgr operations.

## Project Status

This is an actively useful Windows admin script library with a mix of current PowerShell scripts and older legacy automation.

Use it as a script repository, not as an installable PowerShell module or packaged application.

## What This Repository Contains

This repository is a large, mostly flat script collection used for enterprise Windows administration.

Current repository makeup from root:

- 176 PowerShell scripts (.ps1)
- 34 VBScript files (.vbs)
- 4 AutoIt scripts (.au3)
- 2 registry files (.reg)
- Additional support artifacts (.cmd, .xml, .ini, .mif, .xlsx, .mpt)

Most scripts are intended for Windows PowerShell on managed Windows endpoints.

## Start Here

If you are new to this repo:

1. Start with read only or low impact scripts first.
2. Review scripts by category before running anything in production.
3. Prefer scripts that only report state before scripts that install, uninstall, or modify BIOS, TPM, BitLocker, or ConfigMgr settings.
4. Treat .vbs and .au3 items as legacy tooling.
5. Run all scripts in a lab or pilot device group first.

Good low risk scripts to inspect first:

- GetDefaultPrinter.ps1
- GetPrinterList.ps1
- LastRebootTime.ps1
- SystemInformationWMI.ps1
- QueryEventViewerLogs.ps1

How to identify likely safer scripts:

- Names containing Report, List, Get, Verify are often read/report focused.
- Names containing Install, Uninstall, Set, Update, Enable, Disable, Clear are usually change making and higher risk.
- Scripts referencing SCCM, ConfigMgr, Dell, BitLocker, TPM, AD, or SQL are usually environment dependent.

## Quick Setup

There is no build step for this repository.

Recommended first run workflow:

1. Use Windows PowerShell 5.1 unless a specific script has been verified in PowerShell 7.
2. Clone the repository.
3. Open a PowerShell session in the repository root.
4. Start with a read only script.
5. Review script parameters and dependencies before running any change making script.

~~~powershell
git clone https://github.com/MicksITBlogs/PowerShell.git
cd PowerShell
powershell.exe -ExecutionPolicy Bypass -File .\LastRebootTime.ps1
~~~

## Repository Structure and Logical Categories

The repository is currently flat at the root. Files are not moved in this update.

Logical categories used in this README:

- Application install and uninstall
- BitLocker and TPM
- BIOS and vendor tools
- ConfigMgr and endpoint management
- Reporting and inventory
- Active Directory and user management
- Device and operating system utilities
- Legacy VBScript and older automation

### Recommended Future Cleanup Structure

This is a proposed structure for future cleanup only.

~~~text
/Applications
/BitLocker-TPM
/BIOS-Vendor
/ConfigMgr
/Reports
/ActiveDirectory
/Utilities
/Legacy-VBScript
/Legacy-AutoIt
/Artifacts
~~~

## Featured Scripts

The full index now lives in [docs/SCRIPT-CATALOG.md](docs/SCRIPT-CATALOG.md).

Start with these representative scripts if you want to understand the repository quickly:

| Script name | Why start here | Category | Risk level |
|---|---|---|---|
| GetPrinterList.ps1 | Simple read only inventory style script | Reporting and inventory | Low |
| LastRebootTime.ps1 | Good example of a focused utility script | Reporting and inventory | Low |
| AddRemovePrograms.ps1 | Shows older interactive local inventory workflow | Device and operating system utilities | Low |
| BitlockerRecoveryKey.ps1 | Good example of a dependency heavy enterprise security script | BitLocker and TPM | High |
| SCCMClientInstaller.ps1 | Clear ConfigMgr deployment workflow with explicit parameters | ConfigMgr and endpoint management | High |
| InstallConfigMgrModule.ps1 | Good example of environment specific setup automation | ConfigMgr and endpoint management | Medium |
| DellCommandUpdate.ps1 | Representative vendor tooling workflow | BIOS and vendor tools | High |
| MoveComputerToOU.ps1 | Representative AD change script | Active Directory and user management | High |

If you want the longer categorized index with admin, dependency, compatibility, and legacy notes, use [docs/SCRIPT-CATALOG.md](docs/SCRIPT-CATALOG.md).

## Requirements and Prerequisites

Common requirements across scripts:

- Windows endpoint administration context
- Windows PowerShell 5.1 (primary target based on widespread Get-WmiObject usage)
- Local administrator rights for most install, uninstall, BIOS, TPM, and OS change scripts
- Execution policy that allows trusted script execution
- Network access to package shares where applicable

Environment specific dependencies observed in script names and code:

- ActiveDirectory module and AD cmdlets (Get-ADUser, Get-ADComputer, Get-ADObject, Set-ADUser)
- ConfigMgr or SCCM client and server infrastructure
- Dell tooling such as Dell Command Update and CCTK
- BitLocker tooling (manage-bde, Win32_EncryptableVolume WMI classes)
- SQL Server connectivity for SQL report scripts
- MDT or USMT context for deployment and migration scripts
- No direct script names containing Intune were found in this root inventory

## Compatibility Notes

- Repository scripts are Windows focused.
- Many scripts rely on Windows specific features such as registry hives, WMI namespaces, COM objects, DISM, and executable paths under System32.
- PowerShell 7 compatibility is not assumed in this repository.
- Based on patterns such as Get-WmiObject and classic module paths, many scripts appear designed for Windows PowerShell 5.1.

## Legacy Scripts and VBScript Guidance

Legacy indicators found in this repository:

- 34 .vbs scripts that rely on Windows Script Host
- 4 .au3 AutoIt scripts
- Older PowerShell patterns such as heavy Get-WmiObject usage and script templates generated by older PowerShell Studio versions

Guidance:

1. Keep legacy scripts isolated from current production automation where possible.
2. Prefer PowerShell replacements for scripts that still require .vbs or .au3.
3. Test legacy scripts in dedicated lab VMs because they often depend on old installer behaviors and UI driven workflows.

## Usage Examples

Use Windows PowerShell for the broadest compatibility with this repository:

~~~powershell
powershell.exe -ExecutionPolicy Bypass -File .\GetPrinterList.ps1
~~~

Run a read/report script:

~~~powershell
powershell.exe -ExecutionPolicy Bypass -File .\LastRebootTime.ps1
~~~

Run Add or Remove Programs inventory script (interactive prompt):

~~~powershell
powershell.exe -ExecutionPolicy Bypass -File .\AddRemovePrograms.ps1
~~~

Back up BitLocker key to Active Directory:

~~~powershell
powershell.exe -ExecutionPolicy Bypass -File .\BitlockerRecoveryKey.ps1 -ActiveDirectory
~~~

Install SCCM client with explicit infrastructure values:

~~~powershell
powershell.exe -ExecutionPolicy Bypass -File .\SCCMClientInstaller.ps1 -MP "MP01.contoso.local" -FSP "FSP01.contoso.local" -SiteCode "ABC" -ClientPath "\\CM01\SMS_ABC\Client"
~~~

Install ConfigurationManager PowerShell module from UNC source:

~~~powershell
powershell.exe -ExecutionPolicy Bypass -File .\InstallConfigMgrModule.ps1 -ModuleSource "\\CM01\AdminConsole\bin\i386" -ModuleDirectoryName "ConfigurationManager"
~~~

Run Dell Command Update workflow:

~~~powershell
powershell.exe -ExecutionPolicy Bypass -File .\DellCommandUpdate.ps1 -ConsoleTitle "Dell Command Update"
~~~

## Screenshots

No screenshots are currently included in the repository.

For a more polished public presentation, add these images in a future docs or assets folder:

1. A console screenshot of a read only reporting script such as LastRebootTime.ps1 or GetPrinterList.ps1.
2. A screenshot showing categorized folders after any future repository cleanup.
3. A screenshot of comment based help output from one of the better documented scripts.

Until screenshots are added, keep this section so visitors know the omission is intentional and temporary.

## Safety and Testing Guidance

1. Read the script before execution and verify parameter defaults.
2. Run in a lab or pilot collection first.
3. Use least privilege for report only scripts and elevation only when required.
4. Snapshot or back up targets before BIOS, TPM, BitLocker, or uninstall operations.
5. Avoid running legacy .vbs or .au3 scripts directly in production without validation.
6. Capture execution logs and exit codes for change tracking.
7. For ConfigMgr and AD integrated scripts, validate permissions and target scopes before run.

## Repository Guidance

Additional repository guidance is available here:

1. CONTRIBUTING.md for contribution and script standards.
2. SECURITY.md for reporting security issues responsibly.

## Contributing

Contributions are welcome.

Practical guidelines:

1. Keep script names action oriented and specific.
2. Add comment based help with synopsis, parameters, and at least one example.
3. Prefer idempotent behavior where possible.
4. Include safe defaults and clear failure messages.
5. If adding a new script, update this README catalog section.
6. Keep legacy script host automation separated from modern PowerShell where possible.
7. Avoid adding new root level clutter when a category folder would be clearer.

See CONTRIBUTING.md for the full contribution guide.

## License

This project is licensed under the MIT License.

See LICENSE for details.
