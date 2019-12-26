<#
	.SYNOPSIS
		Dell Manufacture Information
	
	.DESCRIPTION
		This script is deployed out to machines so the manufacture and ownership dates are populated as a WMI entry. This allows for easy query of this information for depreciation and lifecycle purposes.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	12/23/2019 8:31 AM
		Created by:   	Mick Pletcher
		Filename:		SystemInformationWMI.ps1
		===========================================================================
#>

function Invoke-Process {
	[CmdletBinding(SupportsShouldProcess)]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$FilePath,
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$ArgumentList
	)
	
	$ErrorActionPreference = 'Stop'
	
	try {
		$stdOutTempFile = "$env:TEMP\$((New-Guid).Guid)"
		$stdErrTempFile = "$env:TEMP\$((New-Guid).Guid)"
		
		$startProcessParams = @{
			FilePath				  = $FilePath
			ArgumentList			  = $ArgumentList
			RedirectStandardError	  = $stdErrTempFile
			RedirectStandardOutput    = $stdOutTempFile
			Wait					  = $true;
			PassThru				  = $true;
			NoNewWindow			      = $true;
		}
		if ($PSCmdlet.ShouldProcess("Process [$($FilePath)]", "Run with args: [$($ArgumentList)]")) {
			$cmd = Start-Process @startProcessParams
			$cmdOutput = Get-Content -Path $stdOutTempFile -Raw
			$cmdError = Get-Content -Path $stdErrTempFile -Raw
			if ($cmd.ExitCode -ne 0) {
				if ($cmdError) {
					throw $cmdError.Trim()
				}
				if ($cmdOutput) {
					throw $cmdOutput.Trim()
				}
			} else {
				if ([string]::IsNullOrEmpty($cmdOutput) -eq $false) {
					Write-Output -InputObject $cmdOutput
				}
			}
		}
	} catch {
		$PSCmdlet.ThrowTerminatingError($_)
	} finally {
		Remove-Item -Path $stdOutTempFile, $stdErrTempFile -Force -ErrorAction Ignore
	}
}

[string]$MFGDate = (((Invoke-Process -FilePath (${env:ProgramFiles(x86)} + '\Dell\Command Configure\X86_64\cctk.exe') -ArgumentList '--mfgdate').split('=')[1]).Trim())
[datetime]$MFGDate = [datetime]::ParseExact($MFGDate, 'yyyymmdd', $null)
[string]$FirstPowerOnDate = (((Invoke-Process -FilePath (${env:ProgramFiles(x86)} + '\Dell\Command Configure\X86_64\cctk.exe') -ArgumentList '--firstpowerondate').split('=')[1]).Trim())
[datetime]$FirstPowerOnDate = [datetime]::ParseExact($FirstPowerOnDate, 'yyyymmdd', $null)
[string]$SVCTag = (Invoke-Process -FilePath (${env:ProgramFiles(x86)} + '\Dell\Command Configure\X86_64\cctk.exe') -ArgumentList '--svctag').split('=')[1]
$newClass = New-Object System.Management.ManagementClass ('root\cimv2', [String]::Empty, $null)
$newClass["__CLASS"] = 'Dell_System_Info'
$newClass.Qualifiers.Add("Static", $true)
$newClass.Properties.Add("ServiceTag", [System.Management.CimType]::String, $false)
$newClass.Properties["ServiceTag"].Qualifiers.Add("Key", $true)
$newClass.Properties.Add("ManufactureDate", [System.Management.CimType]::DateTime, $false)
$newClass.Properties["ManufactureDate"].Qualifiers.Add("Key", $true)
$newClass.Properties.Add("FirstPowerOnDate", [System.Management.CimType]::DateTime, $false)
$newClass.Properties["FirstPowerOnDate"].Qualifiers.Add("Key", $true)
$newClass.Properties.Add("SystemName", [System.Management.CimType]::String, $false)
$newClass.Properties["SystemName"].Qualifiers.Add("Key", $true)
$newClass.Put()
$Properties =  @{
	ServiceTag = $SVCTag.Trim();`
	ManufactureDate = $MFGDate;`
	FirstPowerOnDate = $FirstPowerOnDate;`
	SystemName = $env:COMPUTERNAME
}
$Properties
Get-CimInstance -ClassName 'Dell_System_Info' -Namespace 'root\cimv2' | Remove-CimInstance
New-CimInstance -ClassName 'Dell_System_Info' -Namespace 'root\cimv2' -Property $Properties
