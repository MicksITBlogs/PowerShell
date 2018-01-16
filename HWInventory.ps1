Clear-Host

Set-Variable -Name a -Scope Global -Force
Set-Variable -Name SMSCli -Scope Global -Force

$SMSCli = [wmiclass] "root\ccm:SMS_Client"
$a = $SMSCli.TriggerSchedule("{00000000-0000-0000-0000-000000000001}")
If ($a.__PROPERTY_COUNT -eq 1) {
	$SMSCli.Dispose
	Remove-Variable -Name a -Scope Global -Force
	Remove-Variable -Name SMSCli -Scope Global -Force
	exit 0
} else {
	$SMSCli.Dispose
	Remove-Variable -Name a -Scope Global -Force
	Remove-Variable -Name SMSCli -Scope Global -Force
	exit 1
}
