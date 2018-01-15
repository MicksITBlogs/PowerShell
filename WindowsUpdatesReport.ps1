<#
	.SYNOPSIS
		Generate Windows Updates Report
	
	.DESCRIPTION
		This script will extract the list of windows updates installed
		during an MDT build.
	
	.PARAMETER OutputFile
		File to write the list of installed updates to.
	
	.PARAMETER ExclusionsFile
		Text file containing a list of update descriptions to exclude from the report
	
	.PARAMETER Email
		Send an email to the specified IT staff with the attached .csv file containing a list of all updates installed during the build process.
	
	.PARAMETER From
		Email Sender
	
	.PARAMETER To
		Email Recipient
	
	.PARAMETER SMTPServer
		SMTPServer
	
	.PARAMETER Subject
		Email Subject
	
	.PARAMETER Body
		Body contents
	
	.EXAMPLE
		powershell.exe -executionpolicy bypass -file WindowsUpdatesReport.ps1 -OutputFile BaseBuild.csv -Path \\NetworkLocation\Directory
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.139
		Created on:   	5/31/2017 10:12 AM
		Created by:   	Mick Pletcher 
		Filename:     	WindowsUpdatesReport.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()][string]$OutputFile = 'WindowsUpdatesReport.csv',
	[ValidateNotNullOrEmpty()][string]$ExclusionsFile = 'Exclusions.txt',
	[switch]$Email,
	[string]$From,
	[string]$To,
	[string]$SMTPServer,
	[string]$Subject = 'Windows Updates Build Report',
	[string]$Body = "List of windows updates installed during the build process"
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

function Remove-OutputFile {
<#
	.SYNOPSIS
		Delete Output File
	
	.DESCRIPTION
		This function deletes the old output file that contains a list of updates that were installed during a build.
#>
	
	[CmdletBinding()]
	param ()
	
	#Get the path this script is executing from
	$RelativePath = Get-RelativePath
	#Define location of the output file
	$File = $RelativePath + $OutputFile
	If ((Test-Path -Path $File) -eq $true) {
		Remove-Item -Path $File -Force
	}
}

function Get-Updates {
<#
	.SYNOPSIS
		Retrieve the list of installed updates
	
	.DESCRIPTION
		This function retrieves the list of updates that were installed during the build process
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([array])]
	param ()
	
	$UpdateArray = @()
	#Get the path this script is executing from
	$RelativePath = Get-RelativePath
	#File containing a list of exclusions
	$ExclusionsFile = $RelativePath + $ExclusionsFile
	#Get list of exclusions from exclusions file
	$Exclusions = Get-Content -Path $ExclusionsFile
	#Locate the ZTIWindowsUpdate.log file
	$FileName = Get-ChildItem -Path $env:HOMEDRIVE"\minint" -filter ztiwindowsupdate.log -recurse
	#Get list of all installed updates except for Windows Malicious Software Removal Tool, Definition Update for Windows Defender, and Definition Update for Microsoft Endpoint Protection
	$FileContent = Get-Content -Path $FileName.FullName | Where-Object { ($_ -like "*INSTALL*") } | Where-Object {$_ -notlike "*Windows Defender*"} | Where-Object {$_ -notlike "*Endpoint Protection*"} | Where-Object {$_ -notlike "*Windows Malicious Software Removal Tool*"} | Where-Object {$_ -notlike "*Dell*"} | Where-Object {$_ -notlike $Exclusions}
	#Filter out all unnecessary lines
	$Updates = (($FileContent -replace (" - ", "~")).split("~") | where-object { ($_ -notlike "*LOG*INSTALL*") -and ($_ -notlike "*ZTIWindowsUpdate*") -and ($_ -notlike "*-*-*-*-*") })
	foreach ($Update in $Updates) {
		#Create object
		$Object = New-Object -TypeName System.Management.Automation.PSObject
		#Add KB article number to object
		$Object | Add-Member -MemberType NoteProperty -Name KBArticle -Value ($Update.split("(")[1]).split(")")[0].Trim()
		#Add description of KB article to object
		$Description = $Update.split("(")[0]
		$Description = $Description -replace (",", " ")
		$Object | Add-Member -MemberType NoteProperty -Name Description -Value $Description
		#Add the object to the array
		$UpdateArray += $Object
	}
	If ($UpdateArray -ne $null) {
		$UpdateArray = $UpdateArray | Sort-Object -Property KBArticle
		#Define file to write the report to
		$OutputFile = $RelativePath + $OutputFile
		$UpdateArray | Export-Csv -Path $OutputFile -NoTypeInformation -NoClobber
	}
	Return $UpdateArray
}

Clear-Host
#Delete the old report file
Remove-OutputFile
#Get list of installed updates
Get-Updates
If ($Email.IsPresent) {
	$RelativePath = Get-RelativePath
	$Attachment = $RelativePath + $OutputFile
	#Email Updates
	Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Attachments $Attachment
}
