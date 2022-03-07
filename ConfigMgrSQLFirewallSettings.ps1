If ((Get-NetFirewallRule -Name "ConfigMgr Port 135 UDP" -ErrorAction SilentlyContinue) -eq $null) {
New-NetFirewallRule -Name "ConfigMgr Port 135 UDP" -DisplayName "ConfigMgr Port 135 UDP" -Description "Site Server" -Group "Configuration Manager" -Profile "Domain" -Protocol UDP -LocalPort 135 -Enabled True
}
If ((Get-NetFirewallRule -Name "ConfigMgr Port 135 TCP" -ErrorAction SilentlyContinue) -eq $null) {
    New-NetFirewallRule -Name "ConfigMgr Port 135 TCP" -DisplayName "ConfigMgr Port 135 TCP" -Description "Site Server" -Group "Configuration Manager" -Profile "Domain" -Protocol TCP -LocalPort 135 -Enabled True
}
If ((Get-NetFirewallRule -Name "ConfigMgr Port 1433 TCP" -ErrorAction SilentlyContinue) -eq $null) {
    New-NetFirewallRule -Name "ConfigMgr Port 1433 TCP" -DisplayName "ConfigMgr Port 1433 TCP" -Description "Asset Intelligence Synchronization Point, App Catalog Web Service Point, Endpoint Protection, Enrollment Point, MP, Reporting point, Site Server, SMS Provider, SQL Server, SMP" -Group "Configuration Manager" -Profile "Domain" -Protocol TCP -LocalPort 1433 -Enabled True
}
If ((Get-NetFirewallRule -Name "ConfigMgr Port 4022 TCP" -ErrorAction SilentlyContinue) -eq $null) {
    New-NetFirewallRule -Name "ConfigMgr Port 4022 TCP" -DisplayName "ConfigMgr Port 4022 TCP" -Description "SQL Server" -Group "Configuration Manager" -Profile "Domain" -Protocol TCP -LocalPort 4022 -Enabled True
}
If ((Get-NetFirewallRule -Name "ConfigMgr Port 445 TCP" -ErrorAction SilentlyContinue) -eq $null) {
    New-NetFirewallRule -Name "ConfigMgr Port 445 TCP" -DisplayName "ConfigMgr Port 445 TCP" -Description "Site Server" -Group "Configuration Manager" -Profile "Domain" -Protocol TCP -LocalPort 445 -Enabled True
}
