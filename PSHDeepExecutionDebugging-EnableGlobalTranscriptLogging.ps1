
#Requires -version 5

<#
Snippet Author: Darwin Sanoy
It can be pretty frustrating to debug PowerShell that is running in call stacks like these:
Packer => Remote Execution => PowerShell
Chef Service => Ruby => PowerShell
Packer => Remote Execution => Chef => Ruby => PowerShell
CloudFormation => cfn-init => PowerShell

PowerShell 5 has expanded features for generating global transcripts of PowerShell activity
that log the commands and outputs of PowerShell script execution in almost any execution
context - include embedded contexts like custom PowerShell hosting and dynamic programmatic
execution of PowerShell by other languages like C#.

This code is meant to be setup for execution when you are dealing with problems in
a deep run environment and then removed once you're done debugging.

If your organization has these same values defined in local or AD group policy, then
those settings will override the settings of this script at your GPO enforcement 
interval (default is every 90 minutes) - in most cases this should not interfere with 
briefly testing a script.

Tested and working on: Windows

#>

$GlobalTranscriptsEnabled = $True
$regpathtranscription = "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\Transcription"
$regpathscriptblocktranscription = "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
$OutputDirectory = "$env:public\pshgloballogging"

If ([version]$psversiontable.psversion -lt [version]"5.0")
{  Throw "You must be running PowerShell 5.0 or later to setup global transcripts."}

If ($GlobalTranscriptsEnabled)
{
  if(-not (Test-Path $regpathtranscription)) { $null = New-Item $regpathtranscription –Force | out-null}

  Set-ItemProperty $regpathtranscription -Name OutputDirectory -Value $OutputDirectory
  Set-ItemProperty $regpathtranscription -Name EnableTranscripting -Value 1
  Set-ItemProperty $regpathtranscription -Name EnableInvocationHeader -Value 1
  if(-not (Test-Path $regpathscriptblocktranscription)) { $null = New-Item $regpathscriptblocktranscription –Force | out-null}
  Set-ItemProperty $regpathscriptblocktranscription -Name EnableScriptBlockLogging -Value 1
  Set-ItemProperty $regpathscriptblocktranscription -Name EnableScriptBlockInvocationLogging -Value 1
  Write-Output "Global transcripts were enabled for debugging, logs are stored in: $OutputDirectory"
  Write-Output "Script block logging is enabled, event logs are stored in 'Microsoft-Windows-PowerShell/Operational'"
}
Else
{
  If (Test-Path $regpathtranscription) {Remove-Item $regpathtranscription -Force –Recurse}
  If (Test-Path $regpathscriptblocktranscription) {Remove-Item $regpathscriptblocktranscription -Force –Recurse}
  Write-Output "Global transcripts were disabled, generated logs are retained in: $OutputDirectory and event logs are retained in 'Microsoft-Windows-PowerShell/Operational'"
}
