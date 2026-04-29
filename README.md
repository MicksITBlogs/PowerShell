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

## Script Index

For detailed metadata including admin requirements, external dependencies, PowerShell version notes, and legacy status, see [docs/SCRIPT-CATALOG.md](docs/SCRIPT-CATALOG.md).

### Application Install and Uninstall

| Script | Description |
|---|---|
| 2013RevitBuildingPremiumUninstaller.ps1 | Remove Autodesk Revit 2013 suite components using msiexec product codes |
| 2014AutodeskUninstaller.ps1 | Remove Autodesk 2014 related software by product GUID |
| ActivateOfficeWindows.ps1 | Activate Microsoft Office and Windows licenses online using provided product keys |
| AdobeReaderAutomaticUpdate.ps1 | Disable Adobe Reader automatic updates by setting iCheck registry values |
| ApplicationUninstallScript.ps1 | Uninstall applications using their WMI Product GUIDs via msiexec |
| AutodeskBDSUninstaller.ps1 | Uninstall multiple Autodesk BDS and Visual C++ redistributable packages using product GUIDs |
| DisableWindowsMediaCenter.ps1 | Disable Windows Media Center and create an uninstall entry in Add/Remove Programs |
| InstallAcrobat.ps1 | Install Adobe Acrobat from the script directory |
| InstallChrome.ps1 | Uninstall old Chrome and install current package |
| InstallDotNet47.ps1 | Install .NET Framework 4.7 |
| InstallEndPoint_build.ps1 | Install the endpoint protection security agent during golden image generation |
| InstallFirefox.ps1 | Install Mozilla Firefox |
| InstallFlash.ps1 | Uninstall old Adobe Flash Player versions and install the current version |
| InstallFonts.ps1 | Install OpenType and TrueType fonts from the same directory as the script |
| InstallJava.ps1 | Install Java package |
| InstallOnlineUpdates.ps1 | Install EXE and MSU updates found in the script directory |
| InstallPowerShellGallery.ps1 | Install prerequisites and package providers for accessing the PowerShell Gallery |
| InstallReader.ps1 | Install Adobe Reader |
| Invoke-MSI.ps1 | Wrapper for MSI install or uninstall execution via msiexec |
| OfficeUpdater.ps1 | Keep an Office Updates folder populated with the latest SCCM-downloaded updates |
| PingInstall.ps1 | Kill Office processes, uninstall old Ping versions, and install new Ping timekeeping software |
| PingUninstall.ps1 | Kill Office processes and uninstall old versions of Ping timekeeping software |
| Revit2013Hotfix.ps1 | Replace Revit 2013 DLL files with hotfix versions for 64-bit systems |
| Uninstall-InnoSetup.ps1 | Uninstall applications that were installed using the Inno Setup installer |
| UninstallChrome.ps1 | Remove Google Chrome |
| UninstallFirefox.ps1 | Remove Mozilla Firefox |
| UninstallJava.ps1 | Remove Java package |
| UninstallMSIByName.ps1 | Uninstall MSI application by product name |
| UninstallMSIbyGUID.ps1 | Uninstall MSI application by product GUID |
| UninstallQuicktime.ps1 | Uninstall Apple QuickTime |

### BitLocker and TPM

| Script | Description |
|---|---|
| BackupBitlockerRecoverykey.ps1 | Clean stale AD recovery entries and back up the current BitLocker recovery key |
| BitlockerEncryptionReporting.ps1 | Query the ConfigMgr SQL database and report machines not encrypted with BitLocker |
| BitlockerRecoveryKey.ps1 | Back up BitLocker recovery keys to Active Directory, SCCM, or a network share |
| BitlockerRecoveryPasswordADBackupCleanup.ps1 | Remove outdated AD recovery entries and back up the current BitLocker key |
| BitlockerSAK_CheckTPM.ps1 | Validate TPM state and BitLocker encryption status |
| BitlockerSystem.ps1 | Wait for BitLocker encryption to begin and monitor progress until completion |
| ClearTPM.ps1 | Clear TPM state |
| EnableBitlocker.ps1 | Enable BitLocker on an endpoint |
| InitializeTPM.ps1 | Initialize TPM |
| MissingBitlockerKeys.ps1 | Report systems with no BitLocker key backup in Active Directory |
| RetrieveBitlockerRecoveryKey.ps1 | Retrieve recovery key data from AD and compare to local BitLocker state |
| TurnOnTPM.ps1 | Enable TPM functionality |

### BIOS and Vendor Tools

| Script | Description |
|---|---|
| BIOSSettings.ps1 | Install CCTK and configure Dell BIOS settings |
| ClearDellBIOSPassword.ps1 | Clear Dell BIOS password |
| DCSU.ps1 | Run Dell Command software update workflow |
| DellBIOSDriverUpdate.ps1 | Update Dell BIOS and related drivers |
| DellBIOSReportingTool.ps1 | Report BIOS settings or version information on Dell hardware |
| DellBIOSUpdater.ps1 | Update Dell BIOS |
| DellBIOSVerifier.ps1 | Verify a BIOS update succeeded by comparing installed version to expected version |
| DellCommandUpdate.ps1 | Apply Dell BIOS, driver, and app updates using Dell Command Update |
| DellDriverUpdate.ps1 | Apply Dell driver updates |
| PPI.ps1 | Configure TPM Physical Presence Interface settings on Dell systems via BIOS |
| SetDellBIOSPassword.ps1 | Set Dell BIOS password |
| UpdateBIOSWinPE.ps1 | Copy Dell Command Update to WinPE and apply BIOS updates from XML configuration |
| UpdateDriversBIOS.ps1 | Combined BIOS and driver update workflow |
| WakeOnLAN.ps1 | Configure Wake-On-LAN BIOS setting to LanOnly using Dell BIOS Provider |
| WOL.ps1 | Configure Wake-On-LAN in BIOS on Dell systems via DellBIOSProvider module |
| ZTIDellDriverUpdate.ps1 | Run Dell Command Update up to five times via MDT task sequence to install drivers with reboots |

### ConfigMgr and Endpoint Management

| Script | Description |
|---|---|
| ConfigMgrRebootReport.ps1 | Report pending reboot information in ConfigMgr context |
| ConfigMgrSQLFirewallSettings.ps1 | Configure SQL firewall settings for ConfigMgr |
| ConfigMgrUpgrade.ps1 | ConfigMgr environment upgrade helper |
| DPCleanup.ps1 | Remove ConfigMgr Distribution Point remnants from a server after DP deletion |
| ImportSCCMModule.ps1 | Discover and import the SCCM module from the server |
| InactiveSCCMSystemsReport.ps1 | Query SCCM for inactive systems and search Active Directory for last logon dates |
| InstallConfigMgrModule.ps1 | Copy and install the ConfigurationManager module locally from a UNC source |
| InstallSCCMClient_Standalone.ps1 | Standalone SCCM client install workflow |
| LicensedSoftwareVerification.ps1 | Compare SCCM inventory against a collection to verify licensed software on systems |
| MECMADCleanup.ps1 | Clean up stale AD device entries connected to MECM workflows |
| MSIAnalyzer.ps1 | Uninstall previous SCCM client versions and install a new client version |
| PowerShellSCCMConnect1.ps1 | Demonstrate connecting to SCCM and retrieving all systems |
| RebootManagement.ps1 | Query SCCM SQL for systems not rebooted in the specified number of days and deploy reboot package |
| SCCMActions.ps1 | Trigger SCCM client actions |
| SCCMADCleanup.ps1 | Clean up AD records with SCCM context |
| SCCMADReport.ps1 | Report on SCCM and AD system relationships |
| SCCMBootImage.ps1 | Boot image related ConfigMgr tasking |
| SCCMClientInstaller.ps1 | Install SCCM client using management point, FSP, site code, and client path |
| SCCMDuplicateCleanup.ps1 | Query SCCM for duplicate systems and remove them from the database |
| SCCMHardwareInventory.ps1 | Trigger or verify SCCM hardware inventory |
| SoftwareUpdateGroupCreator.ps1 | Build ConfigMgr software update groups |
| ValidateSystems.ps1 | Validate system existence across Active Directory, SCCM, and antivirus |
| VMWareConfigMgr.ps1 | Query VMware for VMs, verify them in ConfigMgr, and add to distribution point collections |
| ZTIConditionalReboot.ps1 | Check four reboot flag indicators and trigger a reboot if any are set |
| ZTIWindowsUpdates.ps1 | Install latest Windows updates via PSWindowsUpdate with SCCM task sequence integration |

### Reporting and Inventory

| Script | Description |
|---|---|
| AntiVirusScan.ps1 | Initiate a full or quick antimalware scan and log the result to Windows event viewer |
| AntiVirusScanEmail.ps1 | Run antivirus scans and email a report of the scan completion status |
| AppChecker.ps1 | Check if a specified application appears in Programs and Features and log the result |
| ApplicationList.ps1 | Output a list of installed applications |
| ApplicationVirusDetectionMethod.ps1 | Detect infections by comparing last antimalware scan timestamp to last infection timestamp in event logs |
| ApplicationVirusDetectionMethodEmail.ps1 | Detect infections by comparing scan and infection timestamps and email results |
| DefaultPrinterReport.ps1 | Retrieve all user profiles and report their default printer to a CSV file |
| ExchangeModeReporting.ps1 | Analyze Exchange RPC logs to report which users are in cached or online mode |
| FindRegistryUninstall.ps1 | Retrieve x86 and x64 uninstall registry keys for a specified application |
| GetDefaultPrinter.ps1 | Retrieve the default printer and write it to a text file in the user AppData folder |
| GetFileProperties.ps1 | Extract file metadata properties using Shell.Application COM object |
| GetPrinterList.ps1 | Generate a report of all configured printers including the default printer |
| GetSoftwareNameGUID.ps1 | List installed software names and their uninstall GUIDs from the registry |
| HWInventory.ps1 | Gather hardware inventory details via WMI and CIM |
| InstalledApplications.ps1 | Enumerate installed applications via registry or WMI |
| LastReboot.ps1 | Query Windows servers for last reboot time and generate a CSV report |
| LastRebootTime.ps1 | Report last system reboot or shutdown time from event logs and publish to WMI |
| LocalAdministratorsReport.ps1 | Report local administrator group membership |
| LocalAdministratorsReporting.ps1 | Expanded local admin reporting using SCCM and remote registry |
| LogonTimes.ps1 | Query event logs for user logon times and generate CSV or TXT reports by logon type |
| MappedDriveReport.ps1 | Scan user profiles for mapped drives and report to WMI and text files |
| MaxResolution.ps1 | Retrieve maximum monitor resolution by reading monitor driver INF files |
| MDTBuildReportingTool.ps1 | Send email notifications about MDT build status and duration to IT staff |
| MicrosoftSpectrePatchCompatibility.ps1 | Check if the system processor is compatible with Spectre and Meltdown security patches |
| MSPInfo.ps1 | Extract metadata information from MSP patch files |
| PendingRebootReporting.ps1 | Report pending reboot status |
| ProfileSizeReporting.ps1 | Report user profile sizes |
| QueryEventViewerLogs.ps1 | Query event viewer logs for specific messages and report matching systems to a centralized file |
| RebootReporting.ps1 | Reboot reporting with SCCM server queries |
| SMARTReporting.ps1 | Report storage SMART state via WMI storage classes |
| SQLBackupVerification.ps1 | Verify SQL backup jobs or outputs |
| SystemInformationWMI.ps1 | Collect system information via WMI |
| TrustedSitesReport.ps1 | Report browser trusted sites from registry |
| UpdateList.ps1 | Extract KB article numbers of newly installed updates from MDT BDD.log |
| WhosLoggedOn.ps1 | Scan systems for currently logged on and logged off users using PsLoggedon.exe |
| WindowsUpdatesReport.ps1 | Report Windows Update status |
| ZertoUnprotectedSystems.ps1 | Report systems not protected in Zerto, excluding desktop operating systems |

### Active Directory and User Management

| Script | Description |
|---|---|
| ADGroupUserInfo.ps1 | Query AD group membership and last modified data |
| AddUserToLocalAdminGroup.ps1 | Add a user account to the local Administrators group |
| AdministratorReport.ps1 | Report AD admin memberships and account age |
| EmailEnvVariable.ps1 | Read AD mail attribute and write it to an environment variable |
| GetLocalAdministrators.ps1 | Enumerate local administrator group members |
| ImportADExtensions.ps1 | Import AD extension attributes from source records |
| InstallActiveDirectoryModule.ps1 | Copy the ActiveDirectory module into WinPE or a target image context |
| LocalAdmins.ps1 | Local administrator enumeration and management helper |
| LocalAdministrators.ps1 | Report local administrator group members that are not in an exclusion list |
| LocalAdministratorsDetection.ps1 | Detection method that verifies local administrators comply with exclusion policy |
| LogonLogoff.ps1 | Report computer name, username, IP address, and logon timestamp to a CSV file |
| MoveComputerToOU.ps1 | Move computer objects to a target organizational unit |
| SCCMADCleanup.ps1 | Clean up AD records with SCCM context |

### Device and Operating System Utilities

| Script | Description |
|---|---|
| ActiveSetup.ps1 | Generate active setup registry entries for deploying applications that execute once per user logon |
| AddRemoveProgramEntries.ps1 | Enumerate uninstall registry entries |
| AddRemovePrograms.ps1 | Interactive Add or Remove Programs inventory from registry using Windows Forms |
| ApplicationShortcuts.ps1 | Add or remove applications from the Windows taskbar based on a text file list |
| BootEnvironment.ps1 | Determine if the system is BIOS or UEFI by reading the setupact.log file |
| CachedMode.ps1 | Report whether Microsoft Outlook is running in cached exchange mode or online mode |
| CiscoJabberChat.ps1 | Disable Cisco Jabber chat history by setting the database file to read-only |
| CiscoJabberChatCleanup.ps1 | Delete Cisco Jabber chat history files and folders with optional secure deletion |
| ClearPrintSpooler.ps1 | Stop the print spooler service, clear the queue, and restart it |
| ConfigurePowerShell.ps1 | Configure PowerShell execution policy and install necessary modules |
| CopyProfile.ps1 | Robocopy user profile data from one machine or profile path to another |
| Get-MSUFileInfo.ps1 | Extract metadata from MSU Windows update files |
| IEActiveX.ps1 | Enable or disable Internet Explorer ActiveX controls by GUID |
| LGPO.ps1 | Apply Local Group Policy Objects from registry.pol files using ImportRegPol.exe |
| MandatoryReboot.ps1 | Enforce mandatory system reboots after a configurable threshold of days since last reboot |
| MandatoryRebootCustomDetection.ps1 | Custom detection method for mandatory reboot SCCM application deployments |
| MouseMover.ps1 | Move the mouse cursor periodically to prevent screen saver and machine lockout |
| NICAdvancedProperties.ps1 | Manage NIC advanced driver settings |
| NICPowerManagement.ps1 | Update NIC power management settings |
| OnlineUpdate.ps1 | Install Windows updates |
| OperatingSystemDetection.ps1 | Detect the OS version and create a named marker file for task sequence use |
| Permissioning.ps1 | Replicate file and folder permissions from source to destination using robocopy |
| PrinterInstaller.ps1 | Allow non-admin users to install printers from specified print servers via Software Center |
| RemoveOutlookDataFiles.ps1 | Remove Outlook data folders by deleting specific registry binary key values |
| ResetNetworkAdaptor.ps1 | Reset the network adapter stack |
| RestartComputer.ps1 | Restart an endpoint |
| RobocopyProfile.ps1 | Robocopy user profiles from remote machines to a specified UNC path with optional exclusions |
| SecureBoot.ps1 | Query or validate secure boot status |
| SecureScreenStopper.ps1 | Launch MouseMover to keep the screen active, then kill related processes when done |
| Set-PowerScheme.ps1 | Set the active Windows power profile |
| TakeOwnership.ps1 | Grant ownership of files and folders to the current user |
| UninstallBuilt-InApps.ps1 | Remove built-in Windows apps using AppX provisioning commands |
| UninstallPrinters.ps1 | Remove all configured printers from a system |
| UpdateWIM.ps1 | Mount a WIM image, apply updates, and unmount it |
| VerifyBuild.ps1 | Check for required installed applications during build verification using WMI |
| VerifyGUID.ps1 | Verify application GUIDs during build validation |
| VerifyReboot.ps1 | Verify a system rebooted by checking for NotRebooted.log and renaming it with a timestamp |
| VerifyWindowsFeature.ps1 | Validate Windows feature state and optionally invoke DISM |
| Windows10AppDeprovisioning.ps1 | Deprovision Windows 10 built-in apps |
| WindowsFeatures.ps1 | Enable or disable Windows features via DISM or optional feature tooling |

### Security and Compliance

| Script | Description |
|---|---|
| BootEnvironment.ps1 | Determine BIOS or UEFI boot mode for pre-deploy security checks |
| MicrosoftSpectrePatchCompatibility.ps1 | Check processor compatibility with Spectre and Meltdown security patches |
| SecureBoot.ps1 | Query or validate UEFI secure boot state |

### Utilities and GitHub

| Script | Description |
|---|---|
| MouseMover.ps1 | Move the mouse cursor on a timer to prevent screen saver activation |
| MSPInfo.ps1 | Extract metadata from MSP patch files |
| Sync-GitHubRepos.ps1 | Clone missing GitHub repositories from a user account to a local directory |

### Legacy VBScript

| Script | Description |
|---|---|
| Bldg_Premium_Full.vbs | Legacy Autodesk Building Design Suite full install wrapper |
| CreateUSB.vbs | Legacy USB creation automation |
| EnableDisableOfflineFiles.vbs | Legacy toggle for Windows offline files feature |
| FlashBIOS.vbs | Legacy BIOS flash execution wrapper |
| InstallAutodeskRevit.vbs | Legacy Autodesk Revit installation automation |
| InstallCCTK.vbs | Legacy Dell CCTK installation helper |
| InstallCCTK_old.vbs | Older legacy Dell CCTK installation helper |
| InstallFlash.vbs | Legacy Adobe Flash Player install wrapper |
| InstallFonts.vbs | Legacy font installation script |
| InstallOffice.vbs | Legacy Microsoft Office installation automation |
| InstallOfficeUpdates.vbs | Legacy Office update install workflow |
| InstallJava.vbs | Legacy Java install wrapper |
| InstallQuickTime.vbs | Legacy Apple QuickTime install wrapper |
| InstallReaderX.vbs | Legacy Adobe Reader X installer |
| ListUpdates.vbs | Legacy installed updates listing helper |
| LoggedOffSystems.vbs | Legacy scan for systems with no logged-on users |
| ModifyINI.vbs | Legacy INI file modification helper |
| MountWIM.vbs | Legacy WIM mount automation |
| Pause.vbs | Legacy pause script for use in batch or deployment sequences |
| ProfileRobocopy.vbs | Legacy profile copy automation using robocopy |
| SetPageFileSize.vbs | Legacy page file size configuration script |
| SMSCache.vbs | Legacy SCCM cache operation script |
| Sysprep.vbs | Legacy sysprep launcher workflow |
| TrimbleSketchupInstaller.vbs | Legacy Trimble SketchUp installation wrapper |
| UninstallCS3.vbs | Legacy Adobe Creative Suite 3 uninstall automation |
| UnmountWIM.vbs | Legacy WIM unmount automation |
| USMT_Capture.vbs | Legacy USMT capture automation |
| USMTCapture.vbs | Legacy USMT capture workflow |
| USMT PC-to-PC.vbs | Legacy USMT PC-to-PC migration automation |
| UserLoggedOn.vbs | Legacy check for currently logged-on user |
| VerifyBaseBuild.vbs | Legacy base build verification helper |
| ZTIBIOS.vbs | MDT-style BIOS automation for task sequences |

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
