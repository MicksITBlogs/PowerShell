;Change SMS 2003 Cache Size
; Author: Mick Pletcher
; Date: 06 March 2012
;
; Open SMS 2003 CPL
Run( "control C:\Windows\SysWOW64\CCM\smscfgrc.cpl" )
;
; Activate Tabs
WinWait( "Systems Management Properties" )
WinActivate( "Systems Management Properties" )
Send( "{TAB}" )
Sleep( 250 )
Send( "{TAB}" )
Sleep( 250 )
Send( "{TAB}" )
Sleep( 250 )
;
; Go to advanced Window
WinWait( "Systems Management Properties" )
WinActivate( "Systems Management Properties" )
Send( "{RIGHT}" )
Sleep( 250 )
Send( "{RIGHT}" )
Sleep( 250 )
Send( "{RIGHT}" )
Sleep( 250 )
;
; Change Cache Size
WinWait( "Systems Management Properties" )
WinActivate( "Systems Management Properties" )
Send( "{TAB}" )
Sleep( 250 )
Send( "{TAB}" )
Sleep( 250 )
Send( "{TAB}" )
Sleep( 250 )
Send( "{TAB}" )
Sleep( 250 )
Send( "5000" )
Sleep( 250 )
Send( "{Enter}" )
Sleep( 250 )
Send( "{Enter}" )
Sleep( 250 )