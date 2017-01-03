# DebugDeepPSHExecution
Code that helps you debug problems that occur when PowerShell is initiated in a deep or indirect call stack.

Some possible challenges that can be uncovered with these scripts:
* **Unexpected execution bitness**: script executes as 32-bit when expecting 64-bit or vice versa - for instance SCCM 2012 "Package" objects run as 32-bit and "Application" objects run as 64-bit.
* **Unexpected or unknown user context**: script is executed by a user id that you are not expecting - for instance, cloud formation initiates scripts to run under the "Administrator" user even though the ec2config service runs under the system account.
* **Unexpected absence of environment variables**: when powershell ?????
* **Unexpected absence or redirection of specific user profile elements**: ?????
* **Unexpected or unknown initial environment**: for example, Packer uses the task scheduler ONLY when you specify a user name and password on a provisioner - otherwise it executes remotely.
* **Unexpected results when code is executed remotely**: for instance, windows updates - *.msu files - cannot be executed over remoting, including when they are bundled inside a setup.exe type installer.
* **Unexpected or unknown dynamic code execution**: some exes may contain and dynamically execute PowerShell code.
* **Unexpected or unknown PowerShell engine hosting**: for instance, Chocolatey 0.10.0 and later defaults to hosting powershell itself, rather than handing off to "powershell.exe" to be the PowerShell host.
