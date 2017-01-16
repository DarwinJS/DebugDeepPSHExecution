<#
Snippet Author: Darwin Sanoy
It can be pretty frustrating to debug PowerShell that is running in call stacks like these:
Packer => Remote Execution => PowerShell
Chef Service => Ruby => PowerShell
Packer => Remote Execution => Chef => Ruby => PowerShell
CloudFormation => cfn-init => PowerShell

A lot can be learned by dumping a variety of information about the run environment.

This code is meant to be setup for execution when you are dealing with problems in
a deep run environment and then removed once you're done debugging.

This code works for all execution stacks - but is especially helpful when you can't
use your normal PowerShell debugging tools.

Tested and working on: Windows and PowerShell Core for Linux

#>

#serialize the output file
$RunningOnWindows = $true
If ((Test-Path variable:IsWindows) -AND !$IsWindows)
{
  write-output 'running on PowerShell Core, setting up TEMP environment variable'
  $env:temp = '/tmp'
  $env:computername = hostname
  $env:computername = ($env:computername).split('.')[0]
  $RunningOnWindows = $false
  If ($IsLinux) {$OSFamily = 'Linux'}
  If ($IsOSX) {$OSFamily = 'OSX'}
}
Else
{
  $OSFamily = 'Windows'
}
#Keep in mind that on windows temp folder is "per-user profile" - so the file may
#not be in the temp folder of the user you logon as to retrieve the file.
$outputfile = "$env:temp\RunEnvDetails_$(Get-date -format 'yyyyMMddhhmmss').txt"

If (((Test-Path variable:IsCoreCLR)) -AND ($IsCoreCLR))
{ $PowerShellEdition = "Core" } Else { $PowerShellEdition = "Regular (Not Core)" }

$OSBitness = 32 #Default
If ($RunningOnWindows)
{
  $loggedonuserdetails = 'Windows security token information for this process: '
  $loggedonuserdetails += (whoami /all | out-string)

  $processdetails = 'Parent process for this process: '
  $processdetails += (get-process -id (Get-WmiObject -Query "select * from Win32_Process where Handle=$pid" ).Parentprocessid | select Id,Path | fl | out-string)

  If ($env:PROCESSOR_ARCHITECTURE -ilike '*64*')
  {$OSBitness = 64}

  $executionpolicydetails = 'ExecutionPolicy (Windows Only)'
  $executionpolicydetails = Get-ExecutionPolicy -list

}
Else
{
  $loggedonuserdetails = 'Groups: '
  $loggedonuserdetails += $(id -Gn)

  $processdetails = 'Parent process for this process: '
  $parentid = $(ps -o ppid= -p $PID).trim()
  $parentcmdline = (get-content /proc/$parentid/cmdline)
  $processdetails += "Parent Process:  $PID  $parentcmdline"

  If ((uname -a) -ilike '*_64*')
  {$OSBitness = 64}

  $executionpolicydetails = $null
}

$PROCBitness = 32 #Default
If ([System.IntPtr]::Size -eq 8)
{
  $PROCBitness = 64
}

Function Write-Log ($msg)
{
  $msg | out-file -append $outputfile -encoding ascii
}

Write-Log @"
******************************************************************************
PowerShell Environment Dump for understanding and debugging deep
  or alternate run environments for PowerShell.
By Darwin Sanoy
Runs on Windows and PowerShell Core (Linux / OSX)
Project and Updated Code: https://github.com/DarwinJS/DebugDeepPSHExecution
******************************************************************************

"@

Write-Log "Original File name: `"$outputfile`""
Write-Log "Computername: $env:COMPUTERNAME"
Write-Log "OS Family: $OSFamily"
Write-Log "PowerShell Edition: $PowerShellEdition"
Write-Log "Running as User $env:USERNAME"
Write-Log "Bitness / Architecture of the   OS    PowerShell is running on: $OSBitness"
Write-Log "Bitness / Architecture of the PROCESS PowerShell is running in: $ProcBitness"

Write-Log 'Process Details:'
Write-Log $processdetails

Write-Log $executionpolicydetails

Write-Log 'PowerShell Invocation Object for this process: '
Write-Log $myinvocation

Write-Log 'PowerShell version table for this process: '
Write-Log $psversiontable

Write-Log 'PowerShell Host Object for this process: '
Write-Log $host

Write-Log 'Environment variables for this process: '
Write-Log $(gci env: | out-string)

Write-Log 'PowerShell variables for this process: '
Write-Log $(gci variable: | out-string)

Write-Log 'Detailed User Info for PowerShell Process User:'
Write-Log $loggedonuserdetails

Write-output (Get-content $outputfile)  #emit all the data in case the calling system is smart enough to record it directly.
