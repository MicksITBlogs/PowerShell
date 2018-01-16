Set-Variable -Name CurrentOU -Scope Global -Force  
 Set-Variable -Name NewOU -Scope Global -Force  
   
 cls  
 Import-Module activedirectory  
 [string]$NewOU = "OU=BNA, OU=Computers, OU=Front Office, DC=ACME, DC=COM"  
 $CurrentOU = get-adcomputer $env:computername  
 Write-Host "Computer Name:"$env:computername  
 Write-Host "Current OU:"$CurrentOU  
 Write-Host "Target OU:"$NewOU  
 Move-ADObject -identity $CurrentOU -TargetPath $NewOU  
 $CurrentOU = get-adcomputer $env:computername  
 Write-Host "New OU:"$CurrentOU  
