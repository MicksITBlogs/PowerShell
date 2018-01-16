<#  
 .SYNOPSIS  
   Install CMTrace  
 .DESCRIPTION  
   Install CMTrace.exe and associate .log files  
 .Author  
   Mick Pletcher  
 .Date  
   06 February 2015  
 .EXAMPLE  
   powershell.exe -executionpolicy bypass -file install.ps1  
 #>  
   
 $RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\"   
 $Architecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture  
 $Architecture = $Global:Architecture.OSArchitecture  
 If ($Architecture -eq "32-bit") {  
      Copy-Item -Path $RelativePath"CMTrace.exe" -Destination $env:ProgramFiles"\Windows NT\Accessories" -Force  
      $Parameters = "Ftype logfile="+[char]34+$env:ProgramFiles+"\Windows NT\Accessories\CMTrace.exe"+[char]34+" %1"  
      cmd.exe /c $Parameters  
 } else {  
      Copy-Item -Path $RelativePath"CMTrace.exe" -Destination ${env:ProgramFiles(x86)}"\Windows NT\Accessories" -Force  
      $Parameters = "FType logfile="+[char]34+${env:ProgramFiles(x86)}+"\Windows NT\Accessories\CMTrace.exe"+[char]34+" %1"  
      cmd.exe /c $Parameters  
 }  
 $Parameters = "assoc .log=logfile"  
 cmd.exe /c $Parameters  
   