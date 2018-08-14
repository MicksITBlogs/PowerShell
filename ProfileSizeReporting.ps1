#Full path and filename of the file to write the output to
$File = "<Path to CSV file>\ProfileSizeReport.csv"
#Exclude these accounts from reporting
$Exclusions = ("Administrator", "Default", "Public")
#Get the list of profiles
$Profiles = Get-ChildItem -Path $env:SystemDrive"\Users" | Where-Object { $_ -notin $Exclusions }
#Create the object array
$AllProfiles = @()
#Create the custom object
foreach ($Profile in $Profiles) {
	$object = New-Object -TypeName System.Management.Automation.PSObject
	#Get the size of the Documents and Desktop combined and round with no decimal places
	$FolderSizes = [System.Math]::Round("{0:N2}" -f ((Get-ChildItem ($Profile.FullName + '\Documents'), ($Profile.FullName + '\Desktop') -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum))
	$object | Add-Member -MemberType NoteProperty -Name ComputerName -Value $env:COMPUTERNAME.ToUpper()
	$object | Add-Member -MemberType NoteProperty -Name Profile -Value $Profile
	$Object | Add-Member -MemberType NoteProperty -Name Size -Value $FolderSizes
	$AllProfiles += $object
}
#Create the formatted entry to write to the file
[string]$Output = $null
foreach ($Entry in $AllProfiles) {
	[string]$Output += $Entry.ComputerName + ',' + $Entry.Profile + ',' + $Entry.Size + [char]13
}
#Remove the last line break
$Output = $Output.Substring(0,$Output.Length-1)
#Write the output to the specified CSV file. If the file is opened by another machine, continue trying to open until successful
Do {
	Try {
		$Output | Out-File -FilePath $File -Encoding UTF8 -Append -Force
		$Success = $true
	} Catch {
		$Success = $false
	}
} while ($Success = $false)
