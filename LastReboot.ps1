Import-Module -Name ActiveDirectory -Force
#Get list of windows based servers
$Servers = Get-ADComputer -Filter * -Properties * | Where-Object {$_.OperatingSystem -like '*windows server*'} | Select Name | Sort-Object -Property Name
#Create Report Array
$Report = @()
#Parse through server list
Foreach ($Server in $Servers) {
    #Get the computer name
    $ComputerName = ([String]$Server).Split("=")[1].Split("}")[0].Trim()
    #Check if the system is online
    If ((Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) -eq $true) {
        #Query last bootup time and use $Null if unobtainable
        Try {
            $LastBootTime = (Get-CimInstance -ClassName win32_operatingsystem -ComputerName $ComputerName -ErrorAction SilentlyContinue).LastBootUpTime
            $LastBoot = (New-TimeSpan -Start $LastBootTime -End (Get-Date)).Days
        } Catch {
            $LastBoot = $null
        }
        #Add computername and last boot time to the object
        If ($ComputerName -ne $null) {
            $SystemObject = New-Object -TypeName psobject
            $SystemObject | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName
            $SystemObject | Add-Member -MemberType NoteProperty -Name DaysSinceLastBoot -Value $LastBoot
            $Report += $SystemObject
        }
    } else {
            $SystemObject = New-Object -TypeName psobject
            $SystemObject | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName
            $SystemObject | Add-Member -MemberType NoteProperty -Name DaysSinceLastBoot -Value 'OFFLINE'
            $Report += $SystemObject
    }
    $ComputerName = $null
}
#Print report to screen
$Report
$OutFile = "C:\Users\Desktop\LastRebootReport.csv"
#Delete CSV file if it already exists
If ((Test-Path -Path $OutFile) -eq $true) {
    Remove-Item -Path $OutFile -Force
}
#Export report to CSV file
$Report | Export-Csv -Path $OutFile -NoClobber -Encoding UTF8 -NoTypeInformation -Force
