 msiexec.exe /i %~dp0\openlm_utilizer_agent_win_1713.msi /qb- /norestart  
 timeout 2  
 taskkill.exe /IM OpenLM_Agent.exe /t /f  
 timeout 2  
 copy %~dp0\OpenLM_Agent.exe.config "C:\Program Files (x86)\OpenLM\OpenLM Agent\OpenLM_Agent.exe.config" /v /y /z  
 "C:\Program Files (x86)\OpenLM\OpenLM Agent\OpenLM_Agent.exe"  
