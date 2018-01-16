<#
.Author
	Mick Pletcher
.SYNOPSIS
   Outlook Data Folder
.DESCRIPTION
   This script will remove the Outlook data folder. In order to use this script,
   you will need to obtain the powershell translated hexadecimal key. The very first
   thing to do is to go into regedit and manually find the registry key associated with
   the outlook data folder. You do this by opening up each registry key and to the right
   is the ASCII translated data. Once you have found this, the next thing to do is to note
   the name of the key containing the data. Now run the GetHKUBinaryKeyValue function with
   the DeleteHKUBinaryKeyValue commented out. This will generate the list of keys and
   give you the translated value that PowerShell is reading. copy the translated value. Now
   comment out the GetHKUBinaryKeyValue and uncomment the DeleteHKUBinaryKeyValue. Pass the
   translated value into the function as the second variable. You can see the examples below.
   This is intended to run as the end user. I ended up running it via a GPO as the user, under
   their credentials. It worked like a charm.
.EXAMPLE
	GetHKUBinaryKeyValue "Software\Microsoft\Windows NT\CurrentVersion\Windows Messaging Subsystem\Profiles\Default Outlook Profile"
	DeleteHKUBinaryKeyValue "Software\Microsoft\Windows NT\CurrentVersion\Windows Messaging Subsystem\Profiles\Default Outlook Profile" "101 0 68 0 79 0 67 0 83 0 32 0 68 0 77 0 0 0"
#>

Function GetHKUBinaryKeyValue ($RegKey, $KeyVal) {
	Set-Variable -Name HKUsers -Scope Local -Force
	
	Set-Variable -Name i -Scope Local -Force
	Set-Variable -Name Key -Scope Local -Force
	Set-Variable -Name SubKey -Scope Local -Force
	Set-Variable -Name SubKeys -Scope Local -Force
	Set-Variable -Name Temp -Scope Local -Force
	Set-Variable -Name Value -Scope Local -Force
	
	$Temp = New-PSDrive HKU Registry HKEY_USERS
	$HKUsers = Get-ChildItem HKU:\ -ErrorAction SilentlyContinue
	ForEach ($User in $HKUsers) {
		[string]$Key = $User.Name
		$Key = $Key -replace "HKEY_USERS", "HKU:"
		$Key = $Key+"\"+$RegKey
		If (Test-Path $Key) {
			$Subkeys = Get-ChildItem $Key -ErrorAction SilentlyContinue
			Foreach ($SubKey in $SubKeys) {
				Write-host $SubKey
				For ($i=0; $i -lt $Subkey.ValueCount; $i++) {
					[string]$Value = $Subkey.GetValue($Subkey.Property[$i])
					Write-Host "   "$Subkey.Property[$i]" : "$Value
					If ($Value -eq $KeyVal) {
						$DeleteKey = $true
					}
				}
				Write-Host
			}
		}
	}

	Remove-Variable -Name HKUsers -Scope Local -Force
	Remove-Variable -Name i -Scope Local -Force
	Remove-Variable -Name Key -Scope Local -Force
	Remove-Variable -Name SubKey -Scope Local -Force
	Remove-Variable -Name SubKeys -Scope Local -Force
	Remove-Variable -Name Temp -Scope Local -Force
	Remove-Variable -Name Value -Scope Local -Force
}

Function DeleteHKUBinaryKeyValue ($RegKey, $KeyVal) {
	Set-Variable -Name HKUsers -Scope Local -Force
	Set-Variable -Name i -Scope Local -Force
	Set-Variable -Name Key -Scope Local -Force
	Set-Variable -Name SubKey -Scope Local -Force
	Set-Variable -Name SubKeys -Scope Local -Force
	Set-Variable -Name Temp -Scope Local -Force
	Set-Variable -Name Value -Scope Local -Force
	
	$Temp = New-PSDrive HKU Registry HKEY_USERS
	$HKUsers = Get-ChildItem HKU:\ -ErrorAction SilentlyContinue
	ForEach ($User in $HKUsers) {
		[string]$Key = $User.Name
		$Key = $Key -replace "HKEY_USERS", "HKU:"
		$Key = $Key+"\"+$RegKey
		If (Test-Path $Key) {
			$Subkeys = Get-ChildItem $Key -ErrorAction SilentlyContinue
			Foreach ($SubKey in $SubKeys) {
				For ($i=0; $i -lt $Subkey.ValueCount; $i++) {
					[string]$Value = $Subkey.GetValue($Subkey.Property[$i])
					If ($Value -eq $KeyVal) {
						$DeleteKey = $true
					}
				}
				If ($DeleteKey -eq $true) {
					[string]$SubKey1 = $SubKey
					$SubKey1 = $SubKey1 -replace "HKEY_USERS", "HKU:"
					If (Test-Path $SubKey1) {
						Remove-Item $SubKey1 -Force
					}
					$DeleteKey = $false
				}
			}
		}
	}

	Remove-Variable -Name HKUsers -Scope Local -Force
	Remove-Variable -Name i -Scope Local -Force
	Remove-Variable -Name Key -Scope Local -Force
	Remove-Variable -Name SubKey -Scope Local -Force
	Remove-Variable -Name SubKeys -Scope Local -Force
	Remove-Variable -Name Temp -Scope Local -Force
	Remove-Variable -Name Value -Scope Local -Force
}

cls
#GetHKUBinaryKeyValue "Software\Microsoft\Windows NT\CurrentVersion\Windows Messaging Subsystem\Profiles\Default Outlook Profile"
DeleteHKUBinaryKeyValue "Software\Microsoft\Windows NT\CurrentVersion\Windows Messaging Subsystem\Profiles\Default Outlook Profile" "101 0 68 0 79 0 67 0 83 0 32 0 68 0 77 0 0 0"
