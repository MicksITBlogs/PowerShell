# PowerShell Script Library

PowerShell automation scripts for endpoint management, software lifecycle tasks, reporting, security, and system maintenance.

## Overview

This repository contains practical scripts used across real world Windows administration workflows, including:

* Microsoft Intune and ConfigMgr support tasks
* Device compliance and inventory reporting
* Software install and uninstall automation
* BIOS, TPM, and BitLocker operations
* Utility scripts for printers, services, registry, and environment checks

## Typical Script Categories

Scripts in this repo generally fall into these groups:

* Application deployment and removal
* Endpoint configuration and remediation
* Security and encryption workflows
* Hardware and firmware management
* Operational reporting and audit exports

## Prerequisites

Depending on the script, you may need:

* Windows PowerShell 5.1 or PowerShell 7+
* Local administrator rights
* RSAT or ConfigMgr modules
* Access to Active Directory or Azure tenant resources
* Execution policy that allows running signed or trusted scripts

## Usage

Run from a PowerShell console in the repository folder:

```powershell
pwsh .\ScriptName.ps1
```

If a script is intended for Windows PowerShell:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\ScriptName.ps1
```

## Safe Execution Notes

Before running any script in production:

* Review the script content and parameters
* Test in a lab or pilot device group
* Confirm any environment specific values
* Validate permissions and target scope
* Capture logs when possible for rollback and audit

## Contributing

When adding or updating scripts:

* Keep script names clear and action oriented
* Prefer simple and readable logic
* Avoid unnecessary abstractions
* Keep behavior explicit and predictable

## License

No license is currently defined in this repository.
