cls

Function AutoCAD2013English{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{5783F2D7-B001-0000-0102-0060B0CE6BBA}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "AutoCAD 2013 - English"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskRevitInteroperabilityfor3dsMaxand3dsMaxDesign201364-bit{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{06E18300-BB64-1664-8E6A-2593FC67BB74}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk Revit Interoperability for 3ds Max and 3ds Max Design 2013 64-bit"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskShowcase201364-bit{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{A15BFC7D-6A90-47E6-8C6E-D51B2929D8C8}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk Showcase 2013 64-bit"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskDirectConnect201364-bit{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{324297F8-2898-454B-9AC4-07050AEB35B3}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk DirectConnect 2013 64-bit"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskSketchBookDesigner2013{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{3CB60177-D3D2-4E9C-BE4D-8372B34B4C7F}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk SketchBook Designer 2013"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskDesignReview201332-bit{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{153DB567-6FF3-49AD-AC4F-86F8A3CCFDFB}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk Design Review 2013 *32-bit*"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskInventorFusion2013{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{FFF5619F-2013-0064-A85E-9994F70A9E5D}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk Inventor Fusion 2013"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskMaterialLibrary201332-bit{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{117EBEEB-5DB0-43C8-9FD6-DD583DB152DD}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk Material Library 2013 *32-bit*"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskMaterialLibraryBaseResolutionImageLibrary2013{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{606E12B9-641F-4644-A22A-FF38AE980AFD}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk Material Library Base Resolution Image Library 2013"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskMaterialLibraryLowResolutionImageLibrary2013{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{27C6C0A2-2EC9-4FEA-BE2B-659EAAC2C68C}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk Material Library Low Resolution Image Library 2013"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskMaterialLibraryMediumResolutionImageLibrary2013{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{58760EEC-8B6A-43F4-81AA-696E381DFADD}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk Material Library Medium Resolution Image Library 2013"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskContentService{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{62F029AB-85F2-0000-866A-9FC0DD99DDBC}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk Content Service"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskSync{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{EE5F74BC-5CD5-4EF2-86BA-81E6CF46A18F}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk Sync"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskRevit2013{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{7346B4A0-1300-0510-0409-705C0D862004}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk Revit 2013"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutoCADArchitecture2013{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{5783F2D7-B004-0000-0102-0060B0CE6BBA}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "AutoCAD Architecture 2013"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskNavisworksSimulate2013{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{F17E30E2-7ED4-0000-8A8E-CAB597E3F8ED}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk Navisworks Simulate 2013"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskWorkflowsBuildingDesignSuite2013{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{06388E0D-A364-478B-8E40-7D76142A8DF2}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk Workflows - Building Design Suite 2013"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskNavisworksSimulate20132008DWGFileReader{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{4F744A9A-3067-4605-8864-DA1658059F0B}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk Navisworks Simulate 2013 - 2008 DWG File Reader"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskNavisworksSimulate20132009DWGFileReader{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{07DC9A9D-1793-4EB4-AC1A-70750F9FB72B}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk Navisworks Simulate 2013 - 2009 DWG File Reader"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskNavisworksSimulate20132010DWGFileReader{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{0D53A298-B2B7-4746-BB92-B757A6E559C3}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk Navisworks Simulate 2013 - 2010 DWG File Reader"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskNavisworksSimulate20132011DWGFileReader{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{107CB1E9-DDA9-40B5-8A6D-325361402200}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk Navisworks Simulate 2013 - 2011 DWG File Reader"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function Revit2013LanguagePackEnglish{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{7346B4A0-1300-0511-0409-705C0D862004}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Revit 2013 Language Pack - English"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskNavisworksSimulate20132012DWGFileReader{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{90A2F9D3-3E5E-4EF4-BC83-E7795CEF1A42}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk Navisworks Simulate 2013 - 2012 DWG File Reader"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskNavisworksSimulate20132013DWGFileReader{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{CBED6FC7-FB20-4920-AA80-3D6F3459F902}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk Navisworks Simulate 2013 - 2013 DWG File Reader"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskNavisworksSimulate2013EnglishLanguagePack{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{F17E30E2-7ED4-0409-8A8E-CAB597E3F8ED}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk Navisworks Simulate 2013 English Language Pack"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

Function AutodeskSimulationCFD2013{
	#Declare Local Memory
	Set-Variable -Name GUID -Value "{1C11BFF1-1FA3-4AA9-AA15-9AA2BB921F9E}" -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host "Autodesk Simulation CFD 2013"
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	(Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	
	#Cleanup Local Memory
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
}

#Covers all apps the ADSUninstallTool.exe uninstalls
AutoCAD2013English
AutodeskRevitInteroperabilityfor3dsMaxand3dsMaxDesign201364-bit
AutodeskShowcase201364-bit
AutodeskDirectConnect201364-bit
AutodeskSketchBookDesigner2013
AutodeskDesignReview201332-bit
AutodeskInventorFusion2013
AutodeskMaterialLibrary201332-bit
AutodeskMaterialLibraryBaseResolutionImageLibrary2013
AutodeskMaterialLibraryLowResolutionImageLibrary2013
AutodeskMaterialLibraryMediumResolutionImageLibrary2013
AutodeskContentService
AutodeskSync

#Uninstalls the ADSUninstallTool.exe does not uninstall
AutodeskRevit2013
AutoCADArchitecture2013
AutodeskNavisworksSimulate2013
AutodeskWorkflowsBuildingDesignSuite2013
AutodeskNavisworksSimulate20132008DWGFileReader
AutodeskNavisworksSimulate20132009DWGFileReader
AutodeskNavisworksSimulate20132010DWGFileReader
AutodeskNavisworksSimulate20132011DWGFileReader
Revit2013LanguagePackEnglish
AutodeskNavisworksSimulate20132012DWGFileReader
AutodeskNavisworksSimulate20132013DWGFileReader
AutodeskNavisworksSimulate2013EnglishLanguagePack
AutodeskSimulationCFD2013
