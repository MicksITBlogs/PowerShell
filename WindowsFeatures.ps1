<#
	.SYNOPSIS
		Process Windows Features
	
	.DESCRIPTION
		This script can return a list of online windows features and/or set specific windows features.
	
	.PARAMETER ListFeatures
		Return a list of all Windows Features
	
	.PARAMETER Feature
		A description of the Feature parameter.
	
	.PARAMETER Setting
		A description of the Setting parameter.
	
	.PARAMETER FeaturesFile
		Name of the features file that contains a list of features with their corresponding settings for this script to process through. The files resides in the same directory as this script.
	
	.EXAMPLE
		Return a list of all available online Windows Features
		powershell.exe -executionpolicy bypass -command WindowsFeatures.ps1 -ListFeatures $true
		
		Set one Windows Feature from the command line
		powershell.exe -executionpolicy bypass -command WindowsFeatures.ps1 -Feature 'RSATClient-Features' -Setting 'disable'
		
		Set multiple features by reading contents of a text file
		powershell.exe -executionpolicy bypass -command WindowsFeatures.ps1 -FeaturesFile 'FeaturesList.txt'
	
	.NOTES
		You must use -command instead of -file in the command line because of the use of boolean parameters

		An error code 50 means you are trying to enable a feature in which the required parent feature is disabled
		
		I have also included two commented out lines at the bottom of the script as examples if you want to hardcode the features within the script.
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.122
		Created on:   	5/27/2016 2:46 PM
		Created by:   	Mick Pletcher
		Organization:
		Filename:     	WindowsFeatures.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
		[boolean]$ListFeatures = $false,
		[string]$Feature,
		[ValidateSet('enable', 'disable')][string]$Setting,
		[String]$FeaturesFile
)

function Confirm-Feature {
<#
	.SYNOPSIS
		Confirm the feature setting
	
	.DESCRIPTION
		Confirm the desired change took place for a feature
	
	.PARAMETER FeatureName
		Name of the feature
	
	.PARAMETER FeatureState
		Desired state of the feature
	
	.EXAMPLE
		PS C:\> Confirm-Feature
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
			[ValidateNotNull()][string]$FeatureName,
			[ValidateSet('Enable', 'Disable')][string]$FeatureState
	)
	
	$WindowsFeatures = Get-WindowsFeaturesList
	$WindowsFeature = $WindowsFeatures | Where-Object { $_.Name -eq $FeatureName }
	switch ($FeatureState) {
		'Enable' {
			If (($WindowsFeature.State -eq 'Enabled') -or ($WindowsFeature.State -eq 'Enable Pending')) {
				Return $true
			} else {
				Return $false
			}
		}
		'Disable' {
			If (($WindowsFeature.State -eq 'Disabled') -or ($WindowsFeature.State -eq 'Disable Pending')) {
				Return $true
			} else {
				Return $false
			}
		}
		default {
			Return $false
		}
	}
	
}

function Get-WindowsFeaturesList {
<#
	.SYNOPSIS
		List Windows Features
	
	.DESCRIPTION
		This will list all available online windows features
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	$Temp = dism /online /get-features
	$Temp = $Temp | Where-Object { ($_ -like '*Feature Name*') -or ($_ -like '*State*') }
	$i = 0
	$Features = @()
	Do {
		$FeatureName = $Temp[$i]
		$FeatureName = $FeatureName.Split(':')
		$FeatureName = $FeatureName[1].Trim()
		$i++
		$FeatureState = $Temp[$i]
		$FeatureState = $FeatureState.Split(':')
		$FeatureState = $FeatureState[1].Trim()
		$Feature = New-Object PSObject
		$Feature | Add-Member noteproperty Name $FeatureName
		$Feature | Add-Member noteproperty State $FeatureState
		$Features += $Feature
		$i++
	} while ($i -lt $Temp.Count)
	$Features = $Features | Sort-Object Name
	Return $Features
}

function Set-WindowsFeature {
<#
	.SYNOPSIS
		Configure a Windows Feature
	
	.DESCRIPTION
		Enable or disable a windows feature
	
	.PARAMETER Name
		Name of the windows feature
	
	.PARAMETER State
		Enable or disable windows feature
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Name,
			[Parameter(Mandatory = $true)][ValidateSet('enable', 'disable')][string]$State
	)
	
	$EXE = $env:windir + "\system32\dism.exe"
	Write-Host $Name"....." -NoNewline
	If ($State -eq "enable") {
		$Parameters = "/online /enable-feature /norestart /featurename:" + $Name
	} else {
		$Parameters = "/online /disable-feature /norestart /featurename:" + $Name
	}
	$ErrCode = (Start-Process -FilePath $EXE -ArgumentList $Parameters -Wait -PassThru -WindowStyle Minimized).ExitCode
	If ($ErrCode -eq 0) {
		$FeatureChange = Confirm-Feature -FeatureName $Name -FeatureState $State
		If ($FeatureChange -eq $true) {
			If ($State -eq 'Enable') {
				Write-Host "Enabled" -ForegroundColor Yellow
			} else {
				Write-Host "Disabled" -ForegroundColor Yellow
			}
		} else {
			Write-Host "Failed" -ForegroundColor Red
		}
	} elseif ($ErrCode -eq 3010) {
		$FeatureChange = Confirm-Feature -FeatureName $Name -FeatureState $State
		If ($FeatureChange -eq $true) {
			If ($State -eq 'Enable') {
				Write-Host "Enabled & Pending Reboot" -ForegroundColor Yellow
			} else {
				Write-Host "Disabled & Pending Reboot" -ForegroundColor Yellow
			}
		} else {
			Write-Host "Failed" -ForegroundColor Red
		}
	} else {
		If ($ErrCode -eq 50) {
			Write-Host "Failed. Parent feature needs to be enabled first." -ForegroundColor Red
		} else {
			Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		}
	}
}

function Set-FeaturesFromFile {
<#
	.SYNOPSIS
		Set multiple features from a text file
	
	.DESCRIPTION
		This function reads the comma separated features and values from a text file and executes each feature.
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	$RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + '\'
	$FeaturesFile = $RelativePath + $FeaturesFile
	If ((Test-Path $FeaturesFile) -eq $true) {
		$FeaturesFile = Get-Content $FeaturesFile
		foreach ($Item in $FeaturesFile) {
			$Item = $Item.split(',')
			Set-WindowsFeature -Name $Item[0] -State $Item[1]
		}
	}
}

Clear-Host
If ($ListFeatures -eq $true) {
	$WindowsFeatures = Get-WindowsFeaturesList
	$WindowsFeatures
}
If ($FeaturesFile -ne '') {
	Set-FeaturesFromFile
}
If ($Feature -ne '') {
	Set-WindowsFeature -Name $Feature -State $Setting
}
#Set-WindowsFeature -Name 'RSATClient-Features' -State 'disable'
#Set-WindowsFeature -Name 'RSATClient-ServerManager' -State 'disable'
