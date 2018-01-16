REM ***************************************************************************
REM ***     Program: ZTIBIOS.vbs
REM ***      Author: Mick Pletcher
REM ***     Created: 12 April 2012
REM ***      Edited: 
REM ***
REM *** Description: This script will retrieve the information required for 
REM ***              populating the ZTIBIOSCheck.xml fields, located in 
REM ***				 c:\deploymentshare\scripts\ of the MDT server. It's
REM ***				 output is stored in a file in the same directory as the
REM ***				 script with the filename of the computer model.txt. This
REM ***				 was done to accomodate using this script with SMS/SCCM on
REM ***				 multiple models of machines to differentiate the outputs.
REM ***				 This text file contains all of the necessary
REM ***				 fields required for populating the information for a
REM ***				 new system. There is a template field at the top of
REM ***				 the xml file that you can copy and populate with the
REM ***				 output data from this script. It is suggested that you
REM ***				 update the BIOS to the latest version first before
REM ***				 running this script, as that will update the information
REM ***				 acquired by this script. 
REM ***************************************************************************
Option Explicit

REM Define Objects
DIM FSO           : Set FSO           = CreateObject("Scripting.FileSystemObject")
DIM objFile       : Set objFile       = Nothing
DIM objHotfixFile : Set objHotfixFile = Nothing

REM Define Variables
DIM BIOS     : Set BIOS     = Nothing
DIM Computer : Set Computer = Nothing

For each Computer in GetObject("winmgmts:\\.\root\cimv2").InstancesOf("Win32_ComputerSystemProduct")
	For each BIOS in GetObject("winmgmts:\\.\root\cimv2").InstancesOf("Win32_BIOS")
		Set objFile = FSO.CreateTextFile(Trim(Computer.Name) & ".txt", True)
		Set objHotfixFile = FSO.OpenTextFile(Trim(Computer.Name) & ".txt", 1,True)
		objFile.WriteLine("Lookup Name:" & Chr(32) & Chr(60) & BIOS.Description & Chr(62))
		objFile.WriteLine("Computer Manufacturer:" & Chr(32) & Chr(60) & Computer.Vendor & Chr(62))
		objFile.WriteLine("Model:" & Chr(32) & Chr(60) & Computer.Name & Chr(62))
		objFile.WriteLine("Date:" & Chr(32) & Chr(60) & BIOS.ReleaseDate & Chr(62))
	next
next

objFile.Close

REM Cleanup
Set FSO           = Nothing
Set objFile       = Nothing
Set objHotfixFile = Nothing
Set BIOS          = Nothing
Set Computer      = Nothing
