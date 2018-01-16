<#  
 .SYNOPSIS  
   Wake-On-LAN  
 .DESCRIPTION  
   Enable Wake-On-LAN  
 .PARAMETER <paramName>  
   <Description of script parameter>  
 .EXAMPLE  
   <An example of using the script>  
 #>  
 #Declare Global Memory  
 Set-Variable -Name AppLog -Scope Global -Force  
 Set-Variable -Name BuildLog -Scope Global -Force  
 Set-Variable -Name Errors -Value $null -Scope Global -Force  
 Set-Variable -Name LogFile -Scope Global -Force  
 Set-Variable -Name RelativePath -Scope Global -Force  
 Set-Variable -Name Sequence -Scope Global -Force  
 Set-Variable -Name Title -Scope Global -Force  
 Function ConsoleTitle ($Title){  
      $host.ui.RawUI.WindowTitle = $Title  
 }  
 Function DeclareGlobalVariables {  
      $Global:AppLog = "/lvx "+$Env:windir + "\Logs\ApplicationLogs\WakeOnLAN.log"  
      $Global:BuildLog = $Env:windir + "\Logs\BuildLogs\Build.log"  
      $Global:LogFile = $Env:windir + "\Logs\BuildLogs\WakeOnLAN.log"  
      $Global:Sequence = "08"  
      $Global:Title = "Wake On LAN"  
 }  
 Function GetRelativePath {   
      $Global:RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\"   
 }  
 Function EnableWOL {  
      # Get all physical ethernet adaptors  
      $nics = Get-WmiObject Win32_NetworkAdapter -filter "AdapterTypeID = '0' `  
      AND PhysicalAdapter = 'true' `  
      AND NOT Description LIKE '%Centrino%' `  
      AND NOT Description LIKE '%wireless%' `  
      AND NOT Description LIKE '%virtual%' `  
      AND NOT Description LIKE '%WiFi%' `  
      AND NOT Description LIKE '%Bluetooth%'"  
      foreach ($nic in $nics) {  
           $nicName = $nic.Name  
           $Output = "NIC:"+$nicName+[char]10  
           Write-Host "NIC:"$nicName  
           $Output = $Output + "Allow the computer to turn off this device....."  
           Write-Host "Allow the computer to turn off this device....." -NoNewline  
           $nicPower = Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi | where {$_.instancename -match [regex]::escape($nic.PNPDeviceID) }  
           If ($nicPower.Enable -ne $True) {  
                $nicPower.Enable = $True  
                $Temp = $nicPower.psbase.Put()  
           }  
           If ($nicPower.Enable -eq $True) {  
                $Output = $Output + "Enabled"  
                Write-Host "Enabled" -ForegroundColor Yellow  
           } else {  
                $Output = $Output + "Failed"  
                Write-Host "Failed" -ForegroundColor Red  
           }  
           $Output = $Output + [char]10  
           $Output = $Output + "Allow this device to wake the computer....."  
           Write-Host "Allow this device to wake the computer....." -NoNewline  
           $nicPowerWake = Get-WmiObject MSPower_DeviceWakeEnable -Namespace root\wmi | where {$_.instancename -match [regex]::escape($nic.PNPDeviceID) }  
           If ($nicPowerWake.Enable -ne $True) {  
                $nicPowerWake.Enable = $True  
                $Temp = $nicPowerWake.psbase.Put()  
           }  
           If ($nicPowerWake.Enable -eq $True) {  
                $Output = $Output + "Enabled"  
                Write-Host "Enabled" -ForegroundColor Yellow  
           } else {  
                $Output = $Output + "Failed"  
                Write-Host "Failed" -ForegroundColor Red  
           }  
           $Output = $Output + [char]10  
           $Output = $Output + "Only allow a magic packet to wake the computer....."  
           Write-Host "Only allow a magic packet to wake the computer....." -NoNewline  
           $nicMagicPacket = Get-WmiObject MSNdis_DeviceWakeOnMagicPacketOnly -Namespace root\wmi | where {$_.instancename -match [regex]::escape($nic.PNPDeviceID) }  
           If ($nicMagicPacket.EnableWakeOnMagicPacketOnly -ne $True) {  
                $nicMagicPacket.EnableWakeOnMagicPacketOnly = $True  
                $Temp = $nicMagicPacket.psbase.Put()  
           }  
           If ($nicMagicPacket.EnableWakeOnMagicPacketOnly -eq $True) {  
                $Output = $Output + "Enabled"  
                Write-Host "Enabled" -ForegroundColor Yellow  
           } else {  
                $Output = $Output + "Failed"  
                Write-Host "Failed" -ForegroundColor Red  
           }  
      }  
      Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force  
 }  
 Function ProcessLogFile {  
      If ((Test-Path $Env:windir"\Logs") -eq $false) {  
           New-Item -ItemType Directory -Path $Env:windir"\Logs"  
      }  
      If ((Test-Path $Env:windir"\Logs\ApplicationLogs") -eq $false) {  
           New-Item -ItemType Directory -Path $Env:windir"\Logs\ApplicationLogs"  
      }  
      If ((Test-Path $Env:windir"\Logs\BuildLogs") -eq $false) {  
           New-Item -ItemType Directory -Path $Env:windir"\Logs\BuildLogs"  
      }  
      If ($Global:Errors -eq $null) {  
           If (Test-Path $Global:LogFile) {  
                Remove-Item $Global:LogFile -Force  
           }  
           $File1 = $Global:LogFile.Split(".")  
           $Filename1 = $File1[0]+"_ERROR"+"."+$File1[1]  
           If (Test-Path $Filename1) {  
                Remove-Item $Filename1 -Force  
           }  
           $Global:Errors = 0  
      } elseIf ($Global:Errors -ne 0) {  
           If (Test-Path $Global:LogFile) {  
                $Global:LogFile.ToString()  
                $File1 = $Global:LogFile.Split(".")  
                $Filename1 = $File1[0]+"_ERROR"+"."+$File1[1]  
                Rename-Item $Global:LogFile -NewName $Filename1 -Force  
           }  
      } else {  
           $LogTitle = $Global:Sequence + " - "+$Global:Title  
           Out-File -FilePath $Global:BuildLog -InputObject $LogTitle -Append -Force  
      }  
 }  
 Function ExitPowerShell {  
      If ($Global:Errors -ne $null) {  
           Exit 1  
      }  
 }  
 cls  
 GetRelativePath  
 DeclareGlobalVariables  
 ConsoleTitle $Global:Title  
 ProcessLogFile  
 EnableWOL  
 ProcessLogFile  
 ExitPowerShell  
 Start-Sleep -Seconds 10  