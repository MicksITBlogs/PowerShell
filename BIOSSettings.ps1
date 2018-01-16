<#
.Author
   Mick Pletcher
.Date
   01 May 2014
.SYNOPSIS
   Dell Client Configuration Toolkit
.DESCRIPTION
   Installs CCTK
.PARAMETER <paramName>
   <Description of script parameter>
.EXAMPLE
   <An example of using the script>
#>

#Declare Global Memory
Set-Variable -Name Errors -Value $null -Scope Global -Force
Set-Variable -Name LogFile -Value $Env:windir"\Logs\BuildLogs\CCTK.log" -Scope Global -Force
Set-Variable -Name BuildLog -Value $Env:windir"\Logs\BuildLogs\Build.log" -Scope Global -Force
Set-Variable -Name RelativePath -Scope Global -Force

Function ConsoleTitle ($Title){
	$host.ui.RawUI.WindowTitle = $Title
}

Function GetRelativePath { 
	$Global:RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\" 
}

Function InstallCCTK {
	$MSI = "/i "+[char]34+$Global:RelativePath+"cctk.msi"+[char]34
	$Switches = [char]32+"/qb- /norestart /lvx C:\Windows\logs\ApplicationLogs\CCTK.log"
	$Argument = $MSI+$Switches
	$Output = "Install CCTK....."
	Write-Host "Install CCTK....." -NoNewline
	$ErrCode = (Start-Process -FilePath msiexec.exe -ArgumentList $Argument -Wait -Passthru).ExitCode
	If ($ErrCode -eq 0) {
		$Output = $Output+"Success"
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		$Output = $Output+"Failed with error code "+$ErrCode
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		$Global:Errors++
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function CCTKSetting ($Name,$Option,$Setting,$Drives) {
	$EXE = $Env:PROGRAMFILES+"\Dell\CCTK\X86\cctk.exe"
	If ($Option -ne "bootorder") {
		$Argument = "--"+$Option+"="+$Setting
	} else {
		$Argument = "bootorder"+[char]32+"--"+$Setting+"="+$Drives
	}
	$Output = $Name+"....."
	Write-Host $Name"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $EXE -ArgumentList $Argument -Wait -Passthru).ExitCode
	If ($ErrCode -eq 0) {
		If ($Drives -eq "") {
			$Output = $Output+$Setting
			Write-Host $Setting -ForegroundColor Yellow
		} else {
			$Output = $Output+$Drives
			Write-Host $Drives -ForegroundColor Yellow
		}
	} elseIf ($ErrCode -eq 119) {
		$Output = $Output+"Unavailable"
		Write-Host "Unavailable" -ForegroundColor Green
	} else {
		$Output = $Output+"Failed with error code "+$ErrCode
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		$Global:Errors++
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function ProcessLogFile {
	If ((Test-Path $Env:windir"\logs") -eq $false) {
		New-Item -ItemType Directory -Path $Env:windir"\logs"
	}
	If ((Test-Path $Env:windir"\Logs\BuildLogs") -eq $false) {
		New-Item -ItemType Directory -Path $Env:windir"\Logs\BuildLogs"
	}
	If ((Test-Path $Env:windir"\Logs\ApplicationLogs") -eq $false) {
		New-Item -ItemType Directory -Path $Env:windir"\Logs\ApplicationLogs"
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
		Out-File -FilePath $Global:BuildLog -InputObject "08-Dell Client Configuration Toolkit" -Append -Force
	}
}

cls
ConsoleTitle "Dell Client Configuration Toolkit"
GetRelativePath
ProcessLogFile
InstallCCTK
CCTKSetting "PowerLoss" "acpower" "last" ""
CCTKSetting "Advanced Battery Charge" "advbatterychargecfg" "enable" ""
CCTKSetting "On-Board AGP Slot" "agpslot" "enable" ""
CCTKSetting "Resume from Suspended Mode" "alarmresume" "enable" ""
CCTKSetting "Ambient Light Sensor" "amblightsen" "enable" ""
CCTKSetting "Auto On" "autoon" "disable" ""
CCTKSetting "Battery Charge" "batteryslicecfg" "express" ""
CCTKSetting "Bluetooth Devices" "bluetoothdevice" "enable" ""
CCTKSetting "Camera" "camera" "enable" ""
CCTKSetting "Cellular Radio" "cellularradio" "enable" ""
CCTKSetting "Chassis Intrustion" "chasintrusion" "disable" ""
CCTKSetting "Clear BIOS Event Log" "clearsel" "yes" ""
CCTKSetting "Disable WiFi for Ethernet" "controlwwanradio" "enable" ""
CCTKSetting "CPU eXecute Disable" "cpuxdsupport" "disable" ""
CCTKSetting "C states" "cstatesctrl" "enable" ""
CCTKSetting "System Power Mode" "deepsleepctrl" "disable" ""
CCTKSetting "Dell Reliable Memory Technology" "drmt" "enable" ""
CCTKSetting "Built-in NIC" "embnic1" "on" ""
CCTKSetting "Embedded SATA RAID Controller" "embsataraid" "raid" ""
CCTKSetting "Embedded SD Card" "embsdcard" "on" ""
CCTKSetting "Energy Star logo" "energystarlogo" "enable" ""
CCTKSetting "Serial ATA (e-sata) port" "esataport" "auto" ""
CCTKSetting "Express Battery Charge" "expresscharge" "enable" ""
CCTKSetting "Fastboot" "fastboot" "automatic" ""
CCTKSetting "Ready Boost" "flashcachemodule" "enable" ""
CCTKSetting "HDD Acoustic Mode" "hddacousticmode" "performance" ""
CCTKSetting "HDD Protection" "hddprotection" "on" ""
CCTKSetting "HDD Free Fall Protection" "hdfreefallprotect" "enable" ""
CCTKSetting "Hot Docking" "hotdock" "enable" ""
CCTKSetting "WxAN Hotkey" "htkeywxanradio" "enable" ""
CCTKSetting "CPU Hardware Prefetcher" "hwprefetcher" "enable" ""
CCTKSetting "Hardware Prefetcher" "hwswprefetch" "enable" ""
CCTKSetting "CD drive" "idecdrom" "auto" ""
CCTKSetting "Latitude ON" "instanton" "disable" ""
CCTKSetting "Integrated Sound Device" "integratedaudio" "enable" ""
CCTKSetting "Integrated USB Hub" "integratedusbhub" "highspeed" ""
CCTKSetting "Internal Mini PCI Slot" "internalminipci" "enable" ""
CCTKSetting "Internal USB Ports" "internalusb" "on" ""
CCTKSetting "Ultra Wide Band (UWB) Card" "interwirelessuwb" "enable" ""
CCTKSetting "Intel Rapid Start Technology" "intlrapidstart" "enable" ""
CCTKSetting "Intel Smart Connect" "intlsmartconnect" "disable" ""
CCTKSetting "Keyboard Click Sound" "keyboardclick" "enable" ""
CCTKSetting "Keyboard Illumination" "keyboardillumination" "auto" ""
CCTKSetting "Booting to Latitude ON" "latitudeon" "disable" ""
CCTKSetting "Ability to boot to the Latitude ON" "latitudeonflash" "disable" ""
CCTKSetting "Limit Maximum CPUID Function" "limitcpuidvalue" "off" ""
CCTKSetting "Hyper Threading" "logicproc" "enable" ""
CCTKSetting "Microphone" "microphone" "enable" ""
CCTKSetting "Multiple CPU Cores" "multicpucore" "enable" ""
CCTKSetting "Multiple Displays" "multidisplay" "enable" ""
CCTKSetting "Number Lock" "numlock" "on" ""
CCTKSetting "Onboard 1394 Controller" "onboard1394" "enable" ""
CCTKSetting "Onboard Modem" "onboardmodem" "enable" ""
CCTKSetting "Onreader" "onreader" "disable" ""
CCTKSetting "PCI Slots" "pcislots" "enable" ""
CCTKSetting "<F12> boot menu" "postf12key" "enable" ""
CCTKSetting "<F2> boot menu" "postf2key" "enable" ""
CCTKSetting "MEBx hotkey" "postmebxkey" "on" ""
CCTKSetting "Power Button" "powerbutton" "enable" ""
CCTKSetting "Primary Battery Charging" "primarybatterycfg" "express" ""
CCTKSetting "Primary IDE Master Channel" "primidemast" "auto" ""
CCTKSetting "Primary Parallel IDE Slave Channel" "primideslav" "auto" ""
CCTKSetting "Rear Single USB Ports" "rearsingleusb" "on" ""
CCTKSetting "Report Keyboard Errors" "rptkeyerr" "enable" ""
CCTKSetting "Selective USB feature" "safeusb" "disable" ""
CCTKSetting "SATA port 0" "sata0" "auto" ""
CCTKSetting "SATA port 1" "sata1" "auto" ""
CCTKSetting "SATA port 2" "sata2" "auto" ""
CCTKSetting "SATA port 3" "sata3" "auto" ""
CCTKSetting "SATA port 4" "sata4" "auto" ""
CCTKSetting "SATA port 5" "sata5" "auto" ""
CCTKSetting "SATA port 6" "sata6" "auto" ""
CCTKSetting "SATA port 7" "sata7" "auto" ""
CCTKSetting "SATA Controllers" "satactrl" "enable" ""
CCTKSetting "Serial Port 1" "serial1" "auto" ""
CCTKSetting "Serial Port 2" "serial2" "auto" ""
CCTKSetting "Serial Port Communication" "serialcomm" "on" ""
CCTKSetting "Smart Card Reader" "smartcardreader" "enable" ""
CCTKSetting "SMART Errors" "smarterrors" "enable" ""
CCTKSetting "Built-In Speaker" "speakervol" "enable" ""
CCTKSetting "Speedstep" "speedstep" "automatic" ""
CCTKSetting "POST Splash Screen" "splashscreen" "enable" ""
CCTKSetting "ACPI Standby State" "standbystate" "s3" ""
CCTKSetting "Tablet Buttons" "tabletbuttons" "enable" ""
CCTKSetting "Trusted Execution" "trustexecution" "off" ""
CCTKSetting "Intel Turbo Boost" "turbomode" "enable" ""
CCTKSetting "USB 3.0" "usb30" "enable" ""
CCTKSetting "USB port 00" "usbport00" "enable" ""
CCTKSetting "USB port 01" "usbport01" "enable" ""
CCTKSetting "USB port 02" "usbport02" "enable" ""
CCTKSetting "USB port 03" "usbport03" "enable" ""
CCTKSetting "USB port 04" "usbport04" "enable" ""
CCTKSetting "USB port 05" "usbport05" "enable" ""
CCTKSetting "USB port 06" "usbport06" "enable" ""
CCTKSetting "USB port 07" "usbport07" "enable" ""
CCTKSetting "USB port 08" "usbport08" "enable" ""
CCTKSetting "USB port 09" "usbport09" "enable" ""
CCTKSetting "USB port 10" "usbport10" "enable" ""
CCTKSetting "USB port 11" "usbport11" "enable" ""
CCTKSetting "USB port 12" "usbport12" "enable" ""
CCTKSetting "USB port 13" "usbport13" "enable" ""
CCTKSetting "USB port 14" "usbport14" "enable" ""
CCTKSetting "USB port 15" "usbport15" "enable" ""
CCTKSetting "User Accessible USB ports" "usbports" "enable" ""
CCTKSetting "External USB Ports" "usbportsexternal" "enable" ""
CCTKSetting "Front USB Ports" "usbportsfront" "enable" ""
CCTKSetting "USB PowerShare" "usbpowershare" "enable" ""
CCTKSetting "USB Rear Dual Stack" "usbreardual" "on" ""
CCTKSetting "USB Second Rear Dual Stack" "usbreardual2stack" "on" ""
CCTKSetting "USB Rear Quad Ports" "usbrearquad" "on" ""
CCTKSetting "USB Wake" "usbwake" "disable" ""
CCTKSetting "Virtualization" "virtualization" "enable" ""
CCTKSetting "Virtualization Technology for Direct I/O" "vtfordirectio" "on" ""
CCTKSetting "Wake-on-LAN" "wakeonlan" "lanorwlan" ""
CCTKSetting "WiFi Locator" "wifilocator" "enable" ""
CCTKSetting "Wireless Adapter" "wirelessadapter" "enable" ""
CCTKSetting "Wireless LAN Module" "wirelesslan" "enable" ""
CCTKSetting "Ultra Wide Band (UWB) Switch" "wirelessuwb" "enable" ""
CCTKSetting "Bluetooth Control Switch" "wirelesswitchbluetoothctrl" "enable" ""
CCTKSetting "Cellular Control Switch" "wirelesswitchcellularctrl" "enable" ""
CCTKSetting "Wireless Gigabit Switch" "wirelesswitchwigigctrl" "enable" ""
CCTKSetting "Disable Floppy" "bootorder" "disabledevice" "floppy"
CCTKSetting "Boot Order" "bootorder" "sequence" "hdd.1,hdd.2,cdrom,usbdev,embnic"
ProcessLogFile
Start-Sleep -Seconds 10
