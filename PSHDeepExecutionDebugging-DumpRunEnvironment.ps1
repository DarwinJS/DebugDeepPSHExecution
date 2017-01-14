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
If ((!(Test-Path variable:IsWindows)) -AND (!IsWindows))
{
  Write-Host "We are running on Linux, setting up TEMP environment variable"
  $env:temp = '/tmp'
  $env:computername = hostname
  $env:computername = ($env:computername).split('.')[0]
  $RunningOnWindows = $false
}
#Keep in mind that on windows temp folder is "per-user profile" - so the file may
#not be in the temp folder of the user you logon as to retrieve the file.
$outputfile = "$env:temp\RunEnvDetails_$(Get-date -format 'yyyyMMddhhmmss').txt"

"Original File name: `"$outputfile`"" | out-string | out-file -append $outputfile -encoding ascii

"Computername: $env:computername" | out-string | out-file -append $outputfile -encoding ascii

$OSBitness = 32 #Default
If (!$RunningOnWindows)
{
  'Windows security token information for this process: ' | out-file -append $outputfile -encoding ascii
  whoami /all | out-file -append $outputfile -encoding ascii

  'Parent process for this process: ' | out-file -append $outputfile -encoding ascii
  get-process -id (Get-WmiObject -Query "select * from Win32_Process where Handle=$pid" ).Parentprocessid | select * | fl >> $outputfile

  If ((uname -u) -ilike '*64*')
  {$OSBitness = 64}

}
Else
{
  If ($env:PROCESSOR_ARCHITECTURE -ilike '*64*')
  {$OSBitness = 64}
}

$PROCBitness = 32 #Default
If ([System.IntPtr]::Size -eq 8)
{
  $PROCBitness = 64
}

"Bitness / Architecture of the   OS    PowerShell is running on: $OSBitness" | out-file -append $outputfile -encoding ascii

"Bitness / Architecture of the PROCESS PowerShell is running in: $ProcBitness" | out-file -append $outputfile -encoding ascii

'PowerShell Invocation Object for this process: ' | out-file -append $outputfile -encoding ascii
$myinvocation | out-string | out-file -append $outputfile -encoding ascii

'PowerShell version table for this process: ' | out-file -append $outputfile -encoding ascii
$psversiontable | out-string | out-file -append $outputfile -encoding ascii

'PowerShell Host Object for this process: ' | out-file -append $outputfile -encoding ascii
$host | out-string | out-file -append $outputfile -encoding ascii

'Environment variables for this process: ' | out-file -append $outputfile -encoding ascii
gci env: | out-string | out-file -append $outputfile -encoding ascii

'PowerShell variables for this process: ' | out-file -append $outputfile -encoding ascii
gci variable: | out-string | out-file -append $outputfile -encoding ascii

Write-Output "Environment Details were output to: $outputfile"

Get-content $outputfile
