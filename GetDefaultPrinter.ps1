<#
.SYNOPSIS
   Get Default Printer
.DESCRIPTION
   Gets the default printer and writes the printer to a text file in the %APPDATA% folder. If
   this is executed through SCCM, it must be run as the user.
.Author
   Mick Pletcher
.Date
   06 April 2015
.EXAMPLE
   powershell.exe -executionpolicy bypass -file GetDefaultPrinter.ps1
#>

#Declare Global Variables
Set-Variable -Name DefaultPrinter -Scope Global -Force

cls
If ((Test-Path $env:APPDATA"\DefaultPrinter.txt") -eq $true) {
	Remove-Item -Path $env:APPDATA"\DefaultPrinter.txt" -Force
}
$DefaultPrinter = Get-WmiObject -Class win32_printer -ComputerName "localhost" -Filter "Default='true'" | Select-Object ShareName
Write-Host "Default Printer: " -NoNewline
If ($DefaultPrinter.ShareName -ne $null) {
	$DefaultPrinter.ShareName | Out-File -FilePath $env:APPDATA"\DefaultPrinter.txt" -Force -Encoding "ASCII"
	Write-Host $DefaultPrinter.ShareName
} else {
	$DefaultPrinter = "No Default Printer"
	$DefaultPrinter | Out-File -FilePath $env:APPDATA"\DefaultPrinter.txt" -Force -Encoding "ASCII"
	Write-Host $DefaultPrinter
}

#Cleanup Global Variables
Remove-Variable -Name DefaultPrinter -Scope Global -Force

# SIG # Begin signature block
# MIID9QYJKoZIhvcNAQcCoIID5jCCA+ICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUhdw3sg/U/uQ/R/tHR/0rdJFl
# PFygggITMIICDzCCAXygAwIBAgIQ7HIUNzqOT5xDLZzmAt84bjAJBgUrDgMCHQUA
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
# AQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBQP5sLeW7u9HU2XJYAn
# PHfNKdVlWDANBgkqhkiG9w0BAQEFAASBgGpzS23Ll1g3BzS374Vhm1UbdZfigoS4
# b79o0JOXqBRNNWW6svlpUWF9hu55HJ4CxfOUuW3IB5KmeztByDOF4yOJgHQWwI89
# ep8sPPjhG7yBB8gjdRfDd2hGKd93Gr8QPLHCiYt5SoxhKX9JujvYB2+ofilNW1mR
# RxgwDHeR2TBv
# SIG # End signature block
