<#
.SYNOPSIS
   Create Local Administrators Report
.DESCRIPTION
   This will read all .log files and consolidate them into a master 
   .csv file with the computer name and list of local admins for
   each computer
.Author
   Mick Pletcher
.Date
   14 February 2015
.EXAMPLE
   powershell.exe -executionpolicy bypass -file LocalAdministratorsReport.ps1
#>

$MasterLog = "\\NetworkLocation\LocalAdministrators.csv"
$Files = Get-ChildItem -Path \\NetworkLocation -Force
If ((Test-Path $MasterLog) -eq $true) {
	Remove-Item -Path $MasterLog -Force
}
If ((Test-Path $MasterLog) -eq $false) {
	$TitleBar = "ComputerName,UserName"+[char]13
	New-Item -Path $MasterLog -ItemType File -Value $TitleBar -Force
}
Foreach ($File in $Files) {
	If ($File.Extension -eq ".log") {
		$Usernames = Get-Content -Path $File.FullName
		Foreach ($Username in $Usernames) {
			$Entry = $File.BaseName+","+$Username
			Add-Content -Path $MasterLog -Value $Entry -Force
		}
	}
}

# SIG # Begin signature block
# MIID9QYJKoZIhvcNAQcCoIID5jCCA+ICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUjZ9wSJmADrm6V+qYUDgsmA7z
# YxugggITMIICDzCCAXygAwIBAgIQ7HIUNzqOT5xDLZzmAt84bjAJBgUrDgMCHQUA
# MBgxFjAUBgNVBAMTDU1pY2sgUGxldGNoZXIwHhcNMTQwNzE2MTM1NTA1WhcNMzkx
# MjMxMjM1OTU5WjAYMRYwFAYDVQQDEw1NaWNrIFBsZXRjaGVyMIGfMA0GCSqGSIb3
# DQEBAQUAA4GNADCBiQKBgQCScgjcWXrW4VkX2SFeT8Qse6Vxpr0KEiP1htaEeI4Y
# hnYkdu+BsI8EvDRcXtBl8jbb+2hrwhLPCIs73ha/mJ8Bi93aG1lZxBj0skknENwc
# WRnppmmfPR6ZB3YPJ/JI1LMKUenKE5LgriojqfKLR1bX27IO8NK6EAcicZqwidLr
# zwIDAQABo2IwYDATBgNVHSUEDDAKBggrBgEFBQcDAzBJBgNVHQEEQjBAgBAmjhAc
# F97GTTLK+hLMy2UQoRowGDEWMBQGA1UEAxMNTWljayBQbGV0Y2hlcoIQ7HIUNzqO
# T5xDLZzmAt84bjAJBgUrDgMCHQUAA4GBAG8Ll2EtPpoJxDEBWHbN2+Kaae0lB9il
# CNTJwUB09Xqul7CFMKOOUt2zU+VsPQAHaJb2VY5ajgJRU22KFwAUk0KFbMxGibDc
# giw5FkzyAHqGyDZjwdPPFs7PJ1Ulnq3qc/JF/fXH5De02Dt7NEZQsTO+SMJWYjHE
# vb6aRW4Q0oDwMYIBTDCCAUgCAQEwLDAYMRYwFAYDVQQDEw1NaWNrIFBsZXRjaGVy
# AhDschQ3Oo5PnEMtnOYC3zhuMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQow
# CKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcC
# AQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBQF3c/6Ox/av+swTMi4
# JNyPHpaJbzANBgkqhkiG9w0BAQEFAASBgAIeBLzZlG4EkoAby/0NtK3jQxf7nr5U
# +RQOYSWZVKT/PBahYreQl+OX20yzuhyV/2OpTxJ4E8AHozuusZ1yOGXffhgf6bzL
# UW3yBrPec6Vsim/HbQWlrfudunbnKsvrvDZ8cx7rTt+alz5yeESfuxZ5KigmF6dR
# XTDb8epmYYqo
# SIG # End signature block
