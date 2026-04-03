# PowerShell Endpoint Automation Library

Windows focused admin scripts for software lifecycle, endpoint configuration, security, reporting, and ConfigMgr operations.

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

## Script Catalog by Category

Notes:

- Catalog below is built from files currently present in the repository.
- Requires admin is marked as Yes, No, or Likely.
- Legacy status uses Current, Legacy PowerShell Pattern, or Legacy Script Host.
- PowerShell version notes are conservative and based on observed patterns such as Get-WmiObject and classic module usage.

### Application Install and Uninstall

| Script name | Purpose | Category | Requires admin | External dependency | PowerShell version or Windows note | Legacy status |
|---|---|---|---|---|---|---|
| InstallChrome.ps1 | Uninstall old Chrome and install current package | Application install and uninstall | Yes | MSI installer content | Windows PowerShell oriented | Current |
| UninstallChrome.ps1 | Remove Google Chrome | Application install and uninstall | Yes | Chrome uninstall registry entries | Windows only | Current |
| InstallFirefox.ps1 | Install Mozilla Firefox | Application install and uninstall | Yes | Installer package | Windows only | Current |
| UninstallFirefox.ps1 | Remove Mozilla Firefox | Application install and uninstall | Yes | Uninstall registry entries | Windows only | Current |
| InstallJava.ps1 | Install Java package | Application install and uninstall | Yes | Java installer media | Windows only | Current |
| UninstallJava.ps1 | Remove Java package | Application install and uninstall | Yes | MSI or registry uninstall entries | Windows only | Current |
| InstallReader.ps1 | Install Adobe Reader | Application install and uninstall | Yes | Reader installer media | Windows only | Current |
| UninstallReader.ps1 | Remove Adobe Reader | Application install and uninstall | Yes | Uninstall registry entries | Windows only | Current |
| InstallAcrobat.ps1 | Install Adobe Acrobat | Application install and uninstall | Yes | Acrobat media | Windows only | Current |
| InstallDotNet47.ps1 | Install .NET Framework 4.7 | Application install and uninstall | Yes | .NET installer package | Windows only | Current |
| UninstallMSIByName.ps1 | Uninstall MSI by product name | Application install and uninstall | Yes | MSI product registration | Windows only | Current |
| UninstallMSIbyGUID.ps1 | Uninstall MSI by product GUID | Application install and uninstall | Yes | MSI GUID | Windows only | Current |
| Invoke-MSI.ps1 | Wrapper style MSI install or uninstall execution | Application install and uninstall | Likely | msiexec | Windows only | Current |
| 2013RevitBuildingPremiumUninstaller.ps1 | Remove Autodesk Revit 2013 suite components | Application install and uninstall | Yes | msiexec product codes | Windows only | Legacy PowerShell Pattern |
| 2014AutodeskUninstaller.ps1 | Remove Autodesk 2014 related software | Application install and uninstall | Yes | Autodesk product GUIDs | Windows only | Legacy PowerShell Pattern |

### BitLocker and TPM

| Script name | Purpose | Category | Requires admin | External dependency | PowerShell version or Windows note | Legacy status |
|---|---|---|---|---|---|---|
| BitlockerRecoveryKey.ps1 | Backup and compare BitLocker recovery keys with AD, SCCM, or share | BitLocker and TPM | Yes | ActiveDirectory module, SCCM optional, manage-bde | Windows PowerShell with WMI usage | Current |
| BackupBitlockerRecoverykey.ps1 | Clean stale AD recovery entries and back up current key | BitLocker and TPM | Yes | ActiveDirectory module, manage-bde | Windows only | Legacy PowerShell Pattern |
| BitlockerRecoveryPasswordADBackupCleanup.ps1 | Remove outdated AD recovery entries and back up current key | BitLocker and TPM | Yes | ActiveDirectory module, manage-bde | Windows only | Legacy PowerShell Pattern |
| RetrieveBitlockerRecoveryKey.ps1 | Retrieve recovery key data from AD and compare to local state | BitLocker and TPM | Yes | ActiveDirectory module, BitLocker tooling | Windows only | Current |
| MissingBitlockerKeys.ps1 | Report systems missing BitLocker key backup | BitLocker and TPM | Likely | ActiveDirectory module | Windows PowerShell likely | Current |
| EnableBitlocker.ps1 | Enable BitLocker on endpoint | BitLocker and TPM | Yes | BitLocker feature and TPM readiness | Windows only | Current |
| BitlockerSAK_CheckTPM.ps1 | Validate TPM and BitLocker encryption state | BitLocker and TPM | Likely | WMI TPM and volume encryption classes | Windows only | Legacy PowerShell Pattern |
| InitializeTPM.ps1 | Initialize TPM | BitLocker and TPM | Yes | TPM hardware and Windows TPM cmdlets | Windows only | Current |
| ClearTPM.ps1 | Clear TPM state | BitLocker and TPM | Yes | TPM hardware and policy allowances | Windows only | Current |
| TurnOnTPM.ps1 | Enable TPM functionality | BitLocker and TPM | Yes | TPM hardware and firmware support | Windows only | Current |

### BIOS and Vendor Tools

| Script name | Purpose | Category | Requires admin | External dependency | PowerShell version or Windows note | Legacy status |
|---|---|---|---|---|---|---|
| DellCommandUpdate.ps1 | Apply Dell BIOS, driver, and app updates using DCU | BIOS and vendor tools | Yes | Dell Command Update and optional CCTK | Windows only | Legacy PowerShell Pattern |
| DCSU.ps1 | Dell Command software update workflow | BIOS and vendor tools | Yes | Dell Command tooling | Windows only | Current |
| BIOSSettings.ps1 | Install CCTK and configure Dell BIOS settings | BIOS and vendor tools | Yes | Dell CCTK | Windows only | Legacy PowerShell Pattern |
| ClearDellBIOSPassword.ps1 | Clear Dell BIOS password | BIOS and vendor tools | Yes | Dell BIOS tooling | Windows only | Current |
| SetDellBIOSPassword.ps1 | Set Dell BIOS password | BIOS and vendor tools | Yes | Dell BIOS tooling | Windows only | Current |
| DellBIOSUpdater.ps1 | Update Dell BIOS | BIOS and vendor tools | Yes | Dell BIOS updater package | Windows only | Current |
| DellBIOSDriverUpdate.ps1 | Update Dell BIOS and related drivers | BIOS and vendor tools | Yes | Dell update packages | Windows only | Current |
| DellDriverUpdate.ps1 | Apply Dell driver updates | BIOS and vendor tools | Yes | Dell driver package source | Windows only | Current |
| DellBIOSReportingTool.ps1 | Report BIOS settings or version information | BIOS and vendor tools | Likely | Dell BIOS interfaces | Windows only | Current |
| UpdateDriversBIOS.ps1 | Combined BIOS and driver update workflow | BIOS and vendor tools | Yes | OEM update packages | Windows only | Current |

### ConfigMgr and Endpoint Management

| Script name | Purpose | Category | Requires admin | External dependency | PowerShell version or Windows note | Legacy status |
|---|---|---|---|---|---|---|
| InstallConfigMgrModule.ps1 | Copy and install ConfigurationManager module locally | ConfigMgr and endpoint management | Yes | ConfigMgr server module files via UNC | Windows PowerShell module path | Current |
| ImportSCCMModule.ps1 | Discover and import SCCM module from server | ConfigMgr and endpoint management | Likely | Remote registry and SCCM server access | Windows only | Current |
| SCCMClientInstaller.ps1 | Install SCCM client using MP, FSP, SiteCode, and client path | ConfigMgr and endpoint management | Yes | ccmsetup.exe and ConfigMgr infra | Windows only | Current |
| InstallSCCMClient_Standalone.ps1 | Standalone SCCM client install flow | ConfigMgr and endpoint management | Yes | SCCM client source | Windows only | Current |
| SCCMActions.ps1 | Trigger SCCM client actions | ConfigMgr and endpoint management | Likely | SCCM client WMI namespaces | Windows only | Current |
| ConfigMgrUpgrade.ps1 | ConfigMgr environment upgrade helper script | ConfigMgr and endpoint management | Likely | ConfigMgr infrastructure | Windows only | Current |
| ConfigMgrSQLFirewallSettings.ps1 | Configure SQL firewall settings for ConfigMgr paths | ConfigMgr and endpoint management | Yes | SQL Server host access | Windows only | Current |
| SCCMBootImage.ps1 | Boot image related ConfigMgr tasking | ConfigMgr and endpoint management | Likely | ConfigMgr console or module | Windows only | Current |
| SCCMHardwareInventory.ps1 | Trigger or verify SCCM hardware inventory | ConfigMgr and endpoint management | Likely | SCCM client | Windows only | Current |
| SoftwareUpdateGroupCreator.ps1 | Build ConfigMgr software update groups | ConfigMgr and endpoint management | Likely | ConfigMgr module and WSUS metadata | Windows only | Current |
| MECMADCleanup.ps1 | Cleanup stale AD device entries connected to MECM workflows | ConfigMgr and endpoint management | Likely | AD and ConfigMgr data context | Windows only | Current |
| SCCMADCleanup.ps1 | Cleanup AD records with SCCM context | ConfigMgr and endpoint management | Likely | ActiveDirectory module and SCCM data | Windows only | Current |
| SCCMADReport.ps1 | Report on SCCM and AD relationships | ConfigMgr and endpoint management | No | ActiveDirectory module, SCCM data source | Windows only | Current |

### Reporting and Inventory

| Script name | Purpose | Category | Requires admin | External dependency | PowerShell version or Windows note | Legacy status |
|---|---|---|---|---|---|---|
| ApplicationList.ps1 | Output installed application list | Reporting and inventory | No | Registry reads | Windows only | Current |
| InstalledApplications.ps1 | Enumerate installed applications | Reporting and inventory | No | Registry or WMI reads | Windows only | Current |
| HWInventory.ps1 | Gather hardware inventory details | Reporting and inventory | No | WMI/CIM classes | Windows only | Legacy PowerShell Pattern |
| SystemInformationWMI.ps1 | Collect system information via WMI | Reporting and inventory | No | WMI classes | Windows only | Legacy PowerShell Pattern |
| WindowsUpdatesReport.ps1 | Report Windows Update status | Reporting and inventory | No | Windows Update agent data | Windows only | Current |
| ConfigMgrRebootReport.ps1 | Report pending reboot information in ConfigMgr context | Reporting and inventory | No | ConfigMgr context | Windows only | Current |
| PendingRebootReporting.ps1 | Report pending reboot status | Reporting and inventory | No | Registry and reboot indicators | Windows only | Current |
| RebootReporting.ps1 | Reboot reporting with SCCM server queries | Reporting and inventory | No | SCCM server access | Windows only | Current |
| ProfileSizeReporting.ps1 | Report user profile sizes | Reporting and inventory | No | File system profile paths | Windows only | Current |
| LocalAdministratorsReport.ps1 | Report local administrator membership | Reporting and inventory | Likely | Local SAM and possibly AD lookups | Windows only | Current |
| LocalAdministratorsReporting.ps1 | Expanded local admin reporting | Reporting and inventory | Likely | SCCM and remote registry access | Windows only | Current |
| TrustedSitesReport.ps1 | Report browser trusted sites | Reporting and inventory | No | Registry reads | Windows only | Current |
| SMARTReporting.ps1 | Report storage SMART state | Reporting and inventory | No | WMI storage classes | Windows only | Current |
| SQLBackupVerification.ps1 | Verify SQL backup jobs or outputs | Reporting and inventory | No | SQL Server connectivity | Windows only | Current |
| ZertoUnprotectedSystems.ps1 | Report systems not protected in Zerto | Reporting and inventory | No | Zerto environment access | Windows only | Current |

### Active Directory and User Management

| Script name | Purpose | Category | Requires admin | External dependency | PowerShell version or Windows note | Legacy status |
|---|---|---|---|---|---|---|
| InstallActiveDirectoryModule.ps1 | Copy ActiveDirectory module into WinPE or target image context | Active Directory and user management | Yes | Network share, AD module files, robocopy | Windows only | Legacy PowerShell Pattern |
| ImportADExtensions.ps1 | Import AD extension attributes from records | Active Directory and user management | Yes | ActiveDirectory module | Windows only | Current |
| MoveComputerToOU.ps1 | Move computer objects to target OU | Active Directory and user management | Yes | ActiveDirectory module | Windows only | Current |
| AddUserToLocalAdminGroup.ps1 | Add user to local Administrators group | Active Directory and user management | Yes | Local security context, domain account optional | Windows only | Current |
| ADGroupUserInfo.ps1 | Query AD group membership and last modified data | Active Directory and user management | No | ActiveDirectory module | Windows PowerShell likely | Current |
| AdministratorReport.ps1 | Report AD admin memberships and account age | Active Directory and user management | No | ActiveDirectory module | Windows only | Current |
| EmailEnvVariable.ps1 | Read AD mail attribute and write environment variable | Active Directory and user management | No | ActiveDirectory module | Windows only | Current |
| GetLocalAdministrators.ps1 | Enumerate local administrator members | Active Directory and user management | No | Local SAM, optional AD resolution | Windows only | Current |
| LocalAdmins.ps1 | Local admin enumeration or management helper | Active Directory and user management | Likely | Local security APIs | Windows only | Legacy PowerShell Pattern |

### Device and Operating System Utilities

| Script name | Purpose | Category | Requires admin | External dependency | PowerShell version or Windows note | Legacy status |
|---|---|---|---|---|---|---|
| AddRemovePrograms.ps1 | Interactive Add or Remove Programs inventory from registry | Device and operating system utilities | No | Windows Forms and registry | Windows only | Legacy PowerShell Pattern |
| AddRemoveProgramEntries.ps1 | Enumerate uninstall registry entries | Device and operating system utilities | No | Registry reads | Windows only | Current |
| ClearPrintSpooler.ps1 | Stop spooler, clear queue, and restart | Device and operating system utilities | Yes | Print Spooler service | Windows only | Current |
| RestartComputer.ps1 | Restart endpoint | Device and operating system utilities | Yes | Local restart rights | Windows only | Current |
| ResetNetworkAdaptor.ps1 | Reset network adapter stack | Device and operating system utilities | Yes | Net adapter cmdlets or netsh | Windows only | Current |
| NICAdvancedProperties.ps1 | Manage NIC advanced settings | Device and operating system utilities | Yes | NIC driver exposing advanced properties | Windows only | Current |
| NICPowerManagement.ps1 | Update NIC power settings | Device and operating system utilities | Yes | NIC driver support | Windows only | Current |
| Set-PowerScheme.ps1 | Set power profile policy | Device and operating system utilities | Yes | powercfg | Windows only | Current |
| SecureBoot.ps1 | Query or validate secure boot status | Device and operating system utilities | No | UEFI secure boot support | Windows only | Current |
| VerifyWindowsFeature.ps1 | Validate Windows feature state and optionally call DISM | Device and operating system utilities | Likely | DISM | Windows only | Current |
| WindowsFeatures.ps1 | Enable or disable Windows features | Device and operating system utilities | Yes | DISM or optional feature tooling | Windows only | Current |
| UninstallBuilt-InApps.ps1 | Remove built in Windows apps | Device and operating system utilities | Yes | AppX provisioning commands | Windows 10 or later | Current |
| Windows10AppDeprovisioning.ps1 | Deprovision Windows 10 apps | Device and operating system utilities | Yes | AppX provisioning commands | Windows 10 specific | Current |

### Legacy VBScript and Older Automation

| Script name | Purpose | Category | Requires admin | External dependency | PowerShell version or Windows note | Legacy status |
|---|---|---|---|---|---|---|
| InstallOffice.vbs | Legacy Office installation automation | Legacy VBScript and older automation | Yes | Office installer media | Windows Script Host | Legacy Script Host |
| InstallOfficeUpdates.vbs | Legacy Office update install workflow | Legacy VBScript and older automation | Yes | Office update packages | Windows Script Host | Legacy Script Host |
| InstallJava.vbs | Legacy Java install wrapper | Legacy VBScript and older automation | Yes | Java installer media | Windows Script Host | Legacy Script Host |
| InstallReaderX.vbs | Legacy Adobe Reader X installer | Legacy VBScript and older automation | Yes | Reader installer package | Windows Script Host | Legacy Script Host |
| InstallCCTK.vbs | Legacy Dell CCTK installation helper | Legacy VBScript and older automation | Yes | Dell CCTK package | Windows Script Host | Legacy Script Host |
| FlashBIOS.vbs | Legacy BIOS flash execution wrapper | Legacy VBScript and older automation | Yes | OEM BIOS package | Windows Script Host | Legacy Script Host |
| SMSCache.vbs | Legacy SCCM cache operation script | Legacy VBScript and older automation | Likely | SCCM client | Windows Script Host | Legacy Script Host |
| Sysprep.vbs | Legacy sysprep launcher workflow | Legacy VBScript and older automation | Yes | Sysprep binaries | Windows Script Host | Legacy Script Host |
| USMT_Capture.vbs | Legacy USMT capture automation | Legacy VBScript and older automation | Yes | USMT toolkit | Windows Script Host | Legacy Script Host |
| USMT PC-to-PC.vbs | Legacy USMT migration automation | Legacy VBScript and older automation | Yes | USMT toolkit | Windows Script Host | Legacy Script Host |
| ZTIBIOS.vbs | MDT style BIOS automation | Legacy VBScript and older automation | Likely | MDT or deployment share tooling | Windows Script Host | Legacy Script Host |
| ListUpdates.vbs | Legacy updates listing helper | Legacy VBScript and older automation | No | Windows update interfaces | Windows Script Host | Legacy Script Host |

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

## Safety and Testing Guidance

1. Read the script before execution and verify parameter defaults.
2. Run in a lab or pilot collection first.
3. Use least privilege for report only scripts and elevation only when required.
4. Snapshot or back up targets before BIOS, TPM, BitLocker, or uninstall operations.
5. Avoid running legacy .vbs or .au3 scripts directly in production without validation.
6. Capture execution logs and exit codes for change tracking.
7. For ConfigMgr and AD integrated scripts, validate permissions and target scopes before run.

## Contributing

Contributions are welcome.

Practical guidelines:

1. Keep script names action oriented and specific.
2. Add comment based help with synopsis, parameters, and at least one example.
3. Prefer idempotent behavior where possible.
4. Include safe defaults and clear failure messages.
5. If adding a new script, update this README catalog section.

## License

This project is licensed under the MIT License.

See LICENSE for details.
