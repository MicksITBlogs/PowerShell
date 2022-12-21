<#
	.SYNOPSIS
		Wake-On-LAN
	
	.DESCRIPTION
		A description of the file.
	
	.PARAMETER ConsoleTitle
		Title for PowerShell console
	
	.PARAMETER BIOSPassword
		A description of the BIOSPassword parameter.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2022 v5.8.209
		Created on:   	8/1/2022 8:16 AM
		Created by:   	Mick Pletcher
		Filename:		WOL.ps1
		===========================================================================
#>
param
(
	[ValidateNotNullOrEmpty()]
	[string]$ConsoleTitle,
	[string]$BIOSPassword
)

function Set-BIOS {
<#
	.SYNOPSIS
		Configure WOL in BIOS
	
	.DESCRIPTION
		Configure WOL in BIOS
	
#>
	
	[CmdletBinding()]
	param ()
	
	#Import Dell BIOS Provider PowerShell Module
	Try {
		Import-Module -Name DellBIOSProvider
	}
	catch {
		Find-Module -Name DellBIOSProvider | Install-Module -Force
		Import-Module -Name DellBIOSProvider
	}
	#Set Wake-On-LAN to LanOnly
	$BIOSItem = "PowerManagement\WakeOnLan"
	$NewValue = "LanWlan"
	#Check if LanWlan is available
	If ($NewValue -notin ("DellSmBios:\" + $BIOSItem).PossibleValues) {
		$NewValue = "LanOnly"
	}
	If (Get-Item -Path ("DellSmBios:\" + $BIOSItem) -ErrorAction SilentlyContinue) {
		Write-Host ("BIOS" + [char]32 + $BIOSItem.split('\')[1] + ":" + [char]32) -NoNewline
		If ((Get-Item -Path ("DellSmBios:\" + $BIOSItem)).CurrentValue -ne $NewValue) {
			If ($BIOSPassword) {
				Set-Item -Path ("DellSmBios:\" + $BIOSItem) -Value $NewValue -Force -Password $BIOSPassword
			} else {
				Set-Item -Path ("DellSmBios:\" + $BIOSItem) -Value $NewValue -Force
			}
			If ((Get-Item -Path ("DellSmBios:\" + $BIOSItem)).CurrentValue -eq $NewValue) {
				Write-Host $NewValue -ForegroundColor Yellow
			}
			else {
				Write-Host (Get-Item -Path ("DellSmBios:\" + $BIOSItem)).CurrentValue -ForegroundColor Red
			}
		}
		else {
			Write-Host $NewValue -ForegroundColor Yellow
		}
	}
	
	#Disable CState Control
	$BIOSItem = "Performance\CStatesCtrl"
	$NewValue = "Disabled"
	#Test if CState exists
	If (Get-Item -Path ("DellSmBios:\" + $BIOSItem) -ErrorAction SilentlyContinue) {
		Write-Host ("BIOS" + [char]32 + $BIOSItem.split('\')[1] + ":" + [char]32) -NoNewline
		If ((Get-Item -Path ("DellSmBios:\" + $BIOSItem)).CurrentValue -ne $NewValue) {
			If ($BIOSPassword) {
				Set-Item -Path ("DellSmBios:\" + $BIOSItem) -Value $NewValue -Force -Password $BIOSPassword
			}
			else {
				Set-Item -Path ("DellSmBios:\" + $BIOSItem) -Value $NewValue -Force
			}
			If ((Get-Item -Path ("DellSmBios:\" + $BIOSItem)).CurrentValue -eq $NewValue) {
				Write-Host $NewValue -ForegroundColor Yellow
			}
			else {
				Write-Host (Get-Item -Path ("DellSmBios:\" + $BIOSItem)).CurrentValue -ForegroundColor Red
			}
		}
		else {
			Write-Host $NewValue -ForegroundColor Yellow
		}
	}
	
	#Disable Deep Sleep
	$BIOSItem = "PowerManagement\DeepSleepCtrl"
	$NewValue = "Disabled"
	#Test if Deep Sleep exists
	If (Get-Item -Path ("DellSmBios:\" + $BIOSItem) -ErrorAction SilentlyContinue) {
		Write-Host ("BIOS" + [char]32 + $BIOSItem.split('\')[1] + ":" + [char]32) -NoNewline
		If ((Get-Item -Path ("DellSmBios:\" + $BIOSItem)).CurrentValue -ne $NewValue) {
			If ($BIOSPassword) {
				Set-Item -Path ("DellSmBios:\" + $BIOSItem) -Value $NewValue -Force -Password $BIOSPassword
			}
			else {
				Set-Item -Path ("DellSmBios:\" + $BIOSItem) -Value $NewValue -Force
			}
			If ((Get-Item -Path ("DellSmBios:\" + $BIOSItem)).CurrentValue -eq $NewValue) {
				Write-Host $NewValue -ForegroundColor Yellow
			}
			else {
				Write-Host (Get-Item -Path ("DellSmBios:\" + $BIOSItem)).CurrentValue -ForegroundColor Red
			}
		}
		else {
			Write-Host $NewValue -ForegroundColor Yellow
		}
	}
	
	#Disable Block S3
	$BIOSItem = "PowerManagement\BlockS3"
	$NewValue = "Disabled"
	#Test if Block S3 exists
	If (Get-Item -Path ("DellSmBios:\" + $BIOSItem) -ErrorAction SilentlyContinue) {
		Write-Host ("BIOS" + [char]32 + $BIOSItem.split('\')[1] + ":" + [char]32) -NoNewline
		If ((Get-Item -Path ("DellSmBios:\" + $BIOSItem)).CurrentValue -ne $NewValue) {
			If ($BIOSPassword) {
				Set-Item -Path ("DellSmBios:\" + $BIOSItem) -Value $NewValue -Force -Password $BIOSPassword
			}
			else {
				Set-Item -Path ("DellSmBios:\" + $BIOSItem) -Value $NewValue -Force
			}
			If ((Get-Item -Path ("DellSmBios:\" + $BIOSItem)).CurrentValue -eq $NewValue) {
				Write-Host $NewValue -ForegroundColor Yellow
			}
			else {
				Write-Host (Get-Item -Path ("DellSmBios:\" + $BIOSItem)).CurrentValue -ForegroundColor Red
			}
		}
		else {
			Write-Host $NewValue -ForegroundColor Yellow
		}
	}
	
	#Disable C States
	$BIOSItem = "PowerManagement\CStatesCtrl"
	$NewValue = "Disabled"
	#Test if CStatesCtrl exists
	If (Get-Item -Path ("DellSmBios:\" + $BIOSItem) -ErrorAction SilentlyContinue) {
		Write-Host ("BIOS" + [char]32 + $BIOSItem.split('\')[1] + ":" + [char]32) -NoNewline
		If ((Get-Item -Path ("DellSmBios:\" + $BIOSItem)).CurrentValue -ne $NewValue) {
			If ($BIOSPassword) {
				Set-Item -Path ("DellSmBios:\" + $BIOSItem) -Value $NewValue -Force -Password $BIOSPassword
			}
			else {
				Set-Item -Path ("DellSmBios:\" + $BIOSItem) -Value $NewValue -Force
			}
			If ((Get-Item -Path ("DellSmBios:\" + $BIOSItem)).CurrentValue -eq $NewValue) {
				Write-Host $NewValue -ForegroundColor Yellow
			}
			else {
				Write-Host (Get-Item -Path ("DellSmBios:\" + $BIOSItem)).CurrentValue -ForegroundColor Red
			}
		}
		else {
			Write-Host $NewValue -ForegroundColor Yellow
		}
	}
}

Function Set-AdvancedNIC {
   	#Get the Ethernet NIC
	$NIC = Get-NetAdapter | Where-Object {($_.PhysicalMediaType -eq '802.3') -and ($_.Status -eq 'Up')}
    	#Disable Energy Efficient Ethernet setting so NIC does not go to sleep
    #Two variants of Energy Efficient Exist on different Dell models
	#Check if Energy-Efficient Ethernet Exists
	If (Get-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName 'Energy-Efficient Ethernet' -ErrorAction SilentlyContinue) {
		Write-Host 'NIC Energy-Efficient Ethernet: ' -NoNewline
		Set-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName 'Energy-Efficient Ethernet' -DisplayValue 'Disabled'
		If ((Get-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName 'Energy-Efficient Ethernet').DisplayValue -eq 'Disabled') {
			Write-Host 'Disabled' -ForegroundColor Yellow
		}
		else {
			Write-Host 'Enabled' -ForegroundColor Red
		}
	}
	#Check if Energy Efficient Ethernet Exists
	If (Get-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName 'Energy Efficient Ethernet' -ErrorAction SilentlyContinue) {
		Write-Host 'NIC Energy Efficient Ethernet: ' -NoNewline
		Set-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName 'Energy Efficient Ethernet' -DisplayValue 'Off'
		If ((Get-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName 'Energy Efficient Ethernet').DisplayValue -eq 'Off') {
			Write-Host 'Off' -ForegroundColor Yellow
		}
		else {
			Write-Host 'On' -ForegroundColor Red
		}
	}
	#Turn on Wake on Magic Packet
    	#Check if Wake on Magic Packet Exists
	If (Get-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName 'Wake on Magic Packet' -ErrorAction SilentlyContinue) {
		Write-Host 'NIC Wake on Magic Packet: ' -NoNewline
		Set-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName 'Wake on Magic Packet' -RegistryKeyword '*WakeOnMagicPacket' -RegistryValue 1
		If ((Get-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName 'Wake on Magic Packet').DisplayValue -eq 'Enabled') {
			Write-Host 'Enabled' -ForegroundColor Yellow
		}
		else {
			Write-Host 'Disabled' -ForegroundColor Red
		}
	}
	#Shutdown WakeOnLAN
	If (Get-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName 'Shutdown Wake-On-Lan' -ErrorAction SilentlyContinue) {
		Write-Host 'NIC Shutdown Wake-On-Lan: ' -NoNewline
		Set-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName 'Shutdown Wake-On-Lan' -DisplayValue 'Enabled'
		If ((Get-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName 'Shutdown Wake-On-Lan').DisplayValue -eq 'Enabled') {
			Write-Host 'Enabled' -ForegroundColor Yellow
		}
		else {
			Write-Host 'Disabled' -ForegroundColor Red
		}
	}
}

function Set-PowerManagement {
<#
	.SYNOPSIS
		Enable Power Management
	
	.DESCRIPTION
		A detailed description of the Set-PowerManagement function.
	
	.EXAMPLE
				PS C:\> Set-PowerManagement
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	#Turn off Hibernation
    Write-Host ("OS Hiberboot:" + [char]32) -NoNewline
    If ((Get-ItemProperty -Path REGISTRY::"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power").HiberbootEnabled -ne 0) {
        Set-ItemProperty -Path REGISTRY::"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name HiberbootEnabled -Value 0 -Force
    }
    If ((Get-ItemProperty -Path REGISTRY::"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power").HiberbootEnabled -eq 0) {
        Write-Host "Disabled" -ForegroundColor Yellow
    } else {
        Write-Host "Enabled" -ForegroundColor Red
    }

	#0 = Option 1 & 2 checked
    #10 = Option 1 checked, 2 & 3 cleared
    #24 = Option 1 unchecked
    #256 = Option 1, 2, & 3 all checked
    #264 = Option 2 & 3 Checked
    #272 = Option 1 checked
    #280 = Option 2 & 3 checked
    $PNPValue = 256
	$Adapter = Get-NetAdapter | Where-Object { ($_.Status -eq 'Up') -and ($_.PhysicalMediaType -eq '802.3') }
	$KeyPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}\'
	foreach ($Entry in (Get-ChildItem $KeyPath -ErrorAction SilentlyContinue).Name) {
		If ((Get-ItemProperty REGISTRY::$Entry).DriverDesc -eq $Adapter.InterfaceDescription) { 
			$Value = (Get-ItemProperty REGISTRY::$Entry).PnPCapabilities
			If ($Value -ne $PnPValue) {
				Set-ItemProperty -Path REGISTRY::$Entry -Name PnPCapabilities -Value $PnPValue -Force
				Disable-PnpDevice -InstanceId $Adapter.PnPDeviceID -Confirm:$false
				Enable-PnpDevice -InstanceId $Adapter.PnPDeviceID -Confirm:$false
				$Value = (Get-ItemProperty REGISTRY::$Entry).PnPCapabilities }
			If ($Value -eq $PnPValue) {
				Write-Host 'Allow the computer to turn off this device is configured' -ForegroundColor Yellow
			} else { 
				Write-Host 'Allow the computer to turn off this device Failed' -ForegroundColor Red
				Exit 1
			}
		}
	}
}


#Set Console Title
$host.ui.RawUI.WindowTitle = $ConsoleTitle
Set-BIOS
Set-AdvancedNIC
Set-PowerManagement
