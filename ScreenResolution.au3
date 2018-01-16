#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile=install.exe
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; Open Screen Resolution
Run( "control desk.cpl" )
Sleep( 2000 )
; Tab to Resolution
Send( "{TAB}" )
Sleep( 250 )
Send( "{TAB}" )
Sleep( 250 )
; Open Resolution Drop Down
Send( "{Enter}" )
Sleep( 250 )
; Move Resolution Up to max. You may need to add more up arrows.
Send( "{UP}" )
Sleep( 250 )
Send( "{UP}" )
Sleep( 250 )
Send( "{UP}" )
Sleep( 250 )
Send( "{UP}" )
Sleep( 250 )
Send( "{UP}" )
Sleep( 250 )
Send( "{UP}" )
Sleep( 250 )
Send( "{UP}" )
Sleep( 250 )
Send( "{UP}" )
Sleep( 250 )
Send( "{UP}" )
Sleep( 250 )
Send( "{UP}" )
Sleep( 250 )
; Accept resolution
Send( "{Enter}" )
Sleep( 250 )
; Move to OK button
Send( "{TAB}" )
Sleep( 250 )
Send( "{TAB}" )
Sleep( 250 )
Send( "{TAB}" )
Sleep( 250 )
Send( "{TAB}" )
Sleep( 250 )
Send( "{TAB}" )
Sleep( 250 )
; Apply New Resolution
Send( "{Enter}" )
Sleep( 5000 )
; Accept New Resolution
Send( "k" )
