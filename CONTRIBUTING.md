# Contributing

Thanks for contributing to this repository.

## Scope

This repository is a Windows administration script library. It includes current PowerShell scripts and older legacy automation. Changes should improve clarity, safety, and usability without hiding script behavior.

## Before You Submit Changes

1. Test in a lab or non production environment first.
2. Confirm whether the script is read only or change making.
3. Document any required permissions.
4. Document any external dependencies such as Active Directory, ConfigMgr, Dell tools, SQL, MDT, or USMT.
5. Update the README catalog if you add, remove, rename, or materially change a script.

## Script Standards

1. Prefer clear verb noun naming.
2. Use comment based help when practical.
3. Include .SYNOPSIS, parameter descriptions, and at least one .EXAMPLE.
4. Prefer CmdletBinding() and explicit parameter blocks for newer scripts.
5. Keep Windows PowerShell 5.1 compatibility unless there is a deliberate reason not to.
6. Avoid UI prompts in scripts that are likely to be reused in automation.
7. Return useful exit codes for install, uninstall, and remediation scripts.
8. Do not hide destructive actions.

## Legacy Scripts

1. Do not modernize legacy VBScript or AutoIt in place unless the goal is an intentional replacement.
2. If replacing legacy automation, keep behavior changes explicit in the pull request.
3. Mark legacy items clearly in the README if their status changes.

## Pull Request Checklist

1. Tested in a lab.
2. Dependencies documented.
3. Admin requirement documented.
4. README updated if needed.
5. Legacy impact called out if applicable.