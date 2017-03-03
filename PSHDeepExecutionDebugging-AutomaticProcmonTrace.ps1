<#
Snippet Author: Darwin Sanoy
It can be pretty frustrating to debug PowerShell that is running in call stacks like these:
Packer => Remote Execution => PowerShell
Chef Service => Ruby => PowerShell
Packer => Remote Execution => Chef => Ruby => PowerShell
CloudFormation => cfn-init => PowerShell

The below code can be inserted into your automation stack to automatically download procmon 
and start a trace.  The second command stops teh trace.

These commands are crafted to be called in an AWS CloudFormation template (which also means
execution starting in the regular windows cmd.exe shell) - however, you can call them anywhere
that you can call PowerShell.

Tested and working on: Windows 2012 R2 under CloudFormation

#>

<#Cloud Formation / CMD.exe Download and Start Trace
#Hard coded paths are purposeful due to CF parsing
1-download-and-start-procmon:
  command: |
    powershell.exe -ExecutionPolicy Unrestricted -command Invoke-WebRequest -Uri https://live.sysinternals.com/Procmon.exe -Outfile c:\windows\temp\procmon.exe ; Start-Process -FilePath c:\windows\temp\procmon.exe -ArgumentList '/Quiet /AcceptEula /Minimized /BackingFile c:\windows\temp\ProcmonCapture.pml' ; Start-Sleep 10 ; Write-Output "STARTED: Procmon Trace: c:\windows\temp\ProcmonCapture.pml"
#>

<#Cloud Formation / CMD.exe Stop Trace
9-stop-procmon:
  command: |
    powershell.exe -ExecutionPolicy Unrestricted -command Start-Process -FilePath c:\windows\temp\procmon.exe -ArgumentList '/Terminate' ; Write-Output "COMPLETED: Procmon Trace: c:\windows\temp\ProcmonCapture.pml"
#>

#Download and Start trace in PowerShell
Invoke-WebRequest -Uri https://live.sysinternals.com/Procmon.exe -Outfile $env:windir\temp\procmon.exe ; Start-Process -FilePath $env:windir\temp\temp\procmon.exe -ArgumentList '/Quiet /AcceptEula /Minimized /BackingFile $env:windir\temp\temp\ProcmonCapture.pml' ; Start-Sleep 10 ; Write-Output "STARTED: Procmon Trace: $env:windir\temp\ProcmonCapture.pml"

#Stop trace in PowerShell
Start-Process -FilePath $env:windir\temp\procmon.exe -ArgumentList '/Terminate' ; Write-Output "COMPLETED: Procmon Trace: $env:windir\temp\ProcmonCapture.pml"