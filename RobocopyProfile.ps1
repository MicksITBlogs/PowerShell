<#
	.SYNOPSIS
		Robocopy profile to designated UNC path
	
	.DESCRIPTION
		This script will robocopy a user profile from a remote machine to a specified UNC path. It is intended to be used when a profile is either corrupt or a new operating system is being deployed that is a different architecture. 
	
	.PARAMETER DirectoryExclusionsFile
		File containing a list of directories to exclude
	
	.PARAMETER FileExclusionsFile
		File containing a list of files to exclude
	
	.PARAMETER RobocopySwitches
		Switches for controlling the robocopy process
	
	.PARAMETER DestinationUNC
		UNC path where the profile backup will be written to
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
		Created on:   	9/6/2018 9:05 AM
		Created by:   	Mick Pletcher
		Filename:		RobocopyProfile.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[string]$DirectoryExclusionsFile = 'DirectoryExclusions.txt',
	[string]$FileExclusionsFile = 'FileExclusions.txt',
	[string]$RobocopySwitches = '/e /eta /r:1 /w:0 /TEE /MIR',
	[ValidateNotNullOrEmpty()][string]$DestinationUNC = '\\profiles\userprofiles'
)
function Get-RelativePath {
<#
	.SYNOPSIS
		Get the relative path
	
	.DESCRIPTION
		Returns the location of the currently running PowerShell script
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Invoke-RoboCopy {
<#
	.SYNOPSIS
		Backup User profile
	
	.DESCRIPTION
		This function will initiate robocopy to backup the defined contents of the user profile to the designated UNC path.
	
	.PARAMETER ComputerName
		A description of the ComputerName parameter.
	
	.PARAMETER UserName
		A description of the UserName parameter.
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([string])]
	param
	(
		[ValidateNotNullOrEmpty()][string]$ComputerName,
		[ValidateNotNullOrEmpty()][string]$UserName
	)
	
	#Get Relative Path this script is being executed from
	$RelativePath = Get-RelativePath
	$Executable = $Env:windir + "\system32\robocopy.exe"
	#PSEXEC remote execution parameters
	$DirectoryExclusions = Get-Content ($RelativePath + $DirectoryExclusionsFile)
	IF ($DirectoryExclusions -ne $null) {
		$ExcludeDir = "/xd"
		#Add each exclusion from the file to the /xd command line
		foreach ($Exclusion in $DirectoryExclusions) {
			$ExcludeDir += [char]32 + $Exclusion
		}
	}
	#Read the contents in of all file exclusions
	$FileExclusions = Get-Content ($RelativePath + $FileExclusionsFile)
	IF ($FileExclusions -ne $null) {
		$ExcludeFiles = "/xf"
		#Add each exclusion from the file to the /xd command line
		foreach ($Exclusion in $FileExclusions) {
			$ExcludeFiles += [char]32 + $Exclusion
		}
	}
	#Include all subdirectories, give an estimated time for each file, retry once, and do not wait if file transfer fails
	If ($DestinationUNC.Substring($DestinationUNC.Length - 1) -ne '\') {
		$Arguments = [char]34 + '\\' + $ComputerName + '\c$\users\' + $UserName + [char]34 + [char]32 + [char]34 + $DestinationUNC + '\' + $ComputerName + [char]34 + [char]32 + $RobocopySwitches + [char]32 + $ExcludeDir + [char]32 + $ExcludeFiles + [char]32 + '/LOG:' + [char]34 + $DestinationUNC + '\0RobocopyLogs\' + $ComputerName + '.log' + [char]34
	} else {
		$Arguments = [char]34 + '\\' + $ComputerName + '\c$\users\' + $UserName + [char]34 + [char]32 + [char]34 + $DestinationUNC + $ComputerName + [char]34 + [char]32 + $RobocopySwitches + [char]32 + $ExcludeDir + [char]32 + $ExcludeFiles + [char]32 + '/LOG:' + [char]34 + $DestinationUNC + '0RobocopyLogs\' + $ComputerName + '.log' + [char]34
	}
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Arguments -WindowStyle Minimized -Wait -Passthru).ExitCode
	Return $ErrCode
}

$ComputerName = Read-Host -Prompt 'Input computer name'
$UserName = Read-Host -Prompt 'Input user name'
#Check if Computername and username are correct
If ((Get-Item -Path ('\\' + $ComputerName + '\c$') -ErrorAction SilentlyContinue) -eq $null) {
	Write-Host "Computer not reachable or incorrect computer name"
	Exit 1
}
If ((Get-Item -Path ('\\' + $Computername + '\c$\users\' + $Username) -ErrorAction SilentlyContinue) -eq $null) {
	Write-Host "Username is incorrect"
	Exit 1
}
$ErrCode = Invoke-RoboCopy -ComputerName $ComputerName -UserName $UserName
switch ($ErrCode) {
	0 { Write-Host '0 - No Changes' }
	1 { Write-Host '1 - OK Copy' }
	2 { Write-Host '2 - Extra content deleted' }
	3 { Write-Host '3 - OK Copy & Extra content deleted' }
	4 { Write-Host '4 - Mismatches' }
	5 { Write-Host '5 - OK Copy & mismatches'}
	6 { Write-Host '6 - Mismatches & Extra content deleted'}
	7 { Write-Host '7 - OK Copy & Mismatches & Extra content deleted'}
	8 { Write-Host '8 - Failed'}
	9 { Write-Host '9 - OK Copy & Failed'}
	10 { Write-Host '10 - Failed & Extra content deleted'}
	11 { Write-Host '11 - OK Copy & Failed & Extra content deleted'}
	12 { Write-Host '12 - Failed & Mismatches'}
	13 { Write-Host '13 - OK Copy & Failed & Mismatches'}
	14 { Write-Host '14 - Failed & Mismatches & Extra content deleted'}
	15 { Write-Host '15 - OK Copy & Failed & Mismatches & Extra content deleted'}
	16 { Write-Host '16 - Fatal Error'}
}
