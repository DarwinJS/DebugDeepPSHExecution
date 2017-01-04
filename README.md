# DebugDeepPSHExecution
Code that helps you debug problems that occur when PowerShell is initiated in a deep or indirect call stack.

Some possible challenges that can be uncovered with these scripts:
* **Unexpected execution bitness**: script executes as 32-bit when expecting 64-bit or vice versa - for instance SCCM 2012 "Package" objects run as 32-bit and "Application" objects run as 64-bit.
* **Unexpected or unknown user context**: script is executed by a user id that you are not expecting - for instance, cloud formation initiates scripts to run under the "Administrator" user even though the ec2config service runs under the system account.
* **Unexpected absence of environment variables**: when powershell runs under specific contexts, such as under a service or a special system account, some environment variables may not be present.
* **Unexpected absence or redirection of specific user profile elements**: For example the "System" account user profile folder does not contain all the folders of a regular user.  Also on 64-bit windows, the system account has a different user profile folder depending on bitness because it is under the system32 folder which is redirected to syswow64 for 32-bit execution.  In certain execution contexts the initiation of a process as a new user can stipulate whether to load the user's profile at all.
* **Unexpected or unknown initial environment**: for example, Packer uses the task scheduler ONLY when you specify a user name and password on a provisioner - otherwise it executes remotely.
* **Unexpected results when code is executed remotely**: for instance, windows updates - *.msu files - cannot be executed over remoting, including when they are bundled inside a setup.exe type installer.
* **Unexpected or unknown dynamic code execution**: some exes may contain and dynamically execute PowerShell code.
* **Unexpected or unknown PowerShell engine hosting**: for instance, Chocolatey 0.10.0 and later defaults to hosting powershell itself, rather than handing off to "powershell.exe" to be the PowerShell host.
