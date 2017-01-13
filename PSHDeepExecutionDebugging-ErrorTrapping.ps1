<#
Snippet Author: Darwin Sanoy
It can be pretty frustrating to debug PowerShell that is running in call stacks like these:
Packer => Remote Execution => PowerShell
Chef Service => Ruby => PowerShell
Packer => Remote Execution => Chef => Ruby => PowerShell
CloudFormation => cfn-init => PowerShell

When errors are generated in these environments, PowerShell kicks out just a small bit
of the error information it actually possses.
The below code can be inserted into the top of any PowerShell script.
If an error occurs, it will dump all of the error information in the entire $error object
to a text file.

This code works for all execution stacks - but is especially helpful when you can't
use your normal PowerShell debugging tools.

This code only triggers when there are hard errors.  If you do not have any other
PowerShell error handling, you can leave it in for production deployment to discover
the cause of intermittant problems.

Tested and working on: Windows and PowerShell Core for Linux

#>


$ErrorActionPreference = 'Stop'
Trap {
  If ((!(Test-Path env:temp)) -AND (Test-Path '/tmp'))
  {
    Write-Host "We are running on Linux, setting up TEMP environment variable"
    $env:temp = '/tmp'
    $templocation = $env:temp
  }
  Else
  {
  $templocation = "$env:windir\temp" #use $env:temp if you might be running under a non-admin user - log location will vary by user
  }
  $dumpfile = "$templocation\$(split-path -leaf $myinvocation.mycommand.definition)_$(Get-date -format 'yyyyMMddhhmmss').log"
  'Below is the contents of the entire `$error object.  It includes errors that your code may have already handled.' | out-string | out-file $dumpfile -encoding ascii
  'The last error in the list may be a symptom of an earlier error - read carefully :) ' | out-string | out-file $dumpfile -Append -encoding ascii
  $Error | fl * -force | out-string | out-file $dumpfile -Append -encoding ascii
  Write-output "Errors dumped to $dumpfile"
}

Write-Output "Let's make an error"

Some_junk_that_creates_an_error
