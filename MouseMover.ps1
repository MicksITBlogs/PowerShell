Add-Type -AssemblyName System.Windows.Forms

# Rename Powershell Window
$PowershellConsole = (Get-Host).UI.RawUI
$PowershellConsole.WindowTitle = "Mouse Mover"

Function BalloonTip{
	[system.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
	$balloon = New-Object System.Windows.Forms.NotifyIcon
	$path = Get-Process -id $pid | Select-Object -ExpandProperty Path
	$icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
	$balloon.Icon = $icon
	$balloon.BalloonTipIcon = 'Info'
	$balloon.BalloonTipTitle = 'Secure Screen Stopper'
	$balloon.BalloonTipText = 'Mouse will move in 15 seconds'
	$balloon.Visible = $true
	$balloon.ShowBalloonTip(30000)
	Start-Sleep -Seconds 15
}

BalloonTip
do{
	$screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
	[Windows.Forms.Cursor]::Position = "$($screen.Width*0.25),$($screen.Height*0.25)"
	[Windows.Forms.Cursor]::Position = "$($screen.Width*0.75),$($screen.Height*0.25)"
	[Windows.Forms.Cursor]::Position = "$($screen.Width*0.5),$($screen.Height*0.5)"
	[Windows.Forms.Cursor]::Position = "$($screen.Width*0.25),$($screen.Height*0.75)"
	[Windows.Forms.Cursor]::Position = "$($screen.Width*0.75),$($screen.Height*0.75)"
	[System.Windows.Forms.SendKeys]::SendWait("{PGDN}")
	Start-Sleep -Seconds 120
	BalloonTip
} Until (1 -eq 5)
