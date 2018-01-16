 cls  
 #Declare Global Variables  
 Set-Variable -Name Computer -Scope Global -Force  
 Set-Variable -Name Active -Scope Global -Force  
 Set-Variable -Name Network -Scope Global -Force  
 Set-Variable -Name Networks -Scope Global -Force  
 Set-Variable -Name Output -Scope Global -Force  
 Set-Variable -Name RetVal -Scope Global -Force  
 $Computer = gc env:computername  
 $Networks = Get-WmiObject Win32_NetworkAdapter -ComputerName $Computer  
 Foreach ($Network in $Networks) {  
      If ($Network.NetEnabled -eq $true) {  
           $Active = $Network  
           Write-Host "Network Adaptor"  
           Write-host "   "$Network.Description  
           Write-Host  
           $RetVal = $Network.Disable()  
           If ($RetVal.ReturnValue -eq 0) {  
                Write-Host "Network adaptor is disabled"  
           }  
           Start-Sleep -Seconds 5  
           $RetVal = $Network.Enable()  
           If ($RetVal.ReturnValue -eq 0) {  
                Write-Host "Network adaptor is re-enabled"  
           }  
           Start-Sleep -Seconds 30  
           $Output = Test-Connection google.com -Quiet  
           If ($Output -eq $true) {  
                Write-Host "Network adaptor Restored"  
           } else {  
                Write-Host "Network adaptor unavailable"  
           }  
      }  
 }  
 Remove-Variable -Name Active -Scope Global -Force  
 Remove-Variable -Name Computer -Scope Global -Force  
 Remove-Variable -Name Network -Scope Global -Force  
 Remove-Variable -Name Networks -Scope Global -Force  
 Remove-Variable -Name Output -Scope Global -Force  
 Remove-Variable -Name RetVal -Scope Global -Force  