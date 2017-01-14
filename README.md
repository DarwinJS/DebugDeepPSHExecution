# DebugDeepPSHExecution
Code that helps you debug problems that occur when PowerShell is initiated in a deep or indirect call stack where you are running blind because you are unable to easily view the process or results of execution.

It can be pretty frustrating to try to debug or diagnose PowerShell code that that is initiated in call stacks like these:
* Packer => Remote Execution => PowerShell
* Chef Service => Ruby => PowerShell
* Packer => Remote Execution => Chef => Ruby => PowerShell
* CloudFormation => cfn-init => PowerShell
* SCCM Package Pushes

There can be a variety of unexpected things about these execution contexts that don't match up with the runtime expectations of your code.  In some cases the calling system makes some effort to capture exit codes or errors - but many times this final result does not reveal enough to diagnose the problem.

Below is a list of challenges that can be uncovered with these scripts.  These are not theoretical challenges - I have personally experienced many of them.  In most cases finding these items was a surprise.  I don't use the list as a set of hypothesis.  Instead, my hypothesis is simply "if it is a deep or blind execution context - something unexpected might be happening"  Then I just start dumping information and ensuring I can record errors and look through.
* **Unexpected / unknown / misconfigured execution bitness**: script executes as 32-bit when expecting 64-bit or vice versa. Some execution agents may be coded to specifically choose a bitness.  Execution under services will default to the bitness of the service - for instance SCCM 2012 "Package" objects run as 32-bit and "Application" objects run as 64-bit.  Many management agents for Windows are 32-bit even when installed on 64-bit Windows.
* **Unexpected / unknown / misconfigured user context**: script is executed by a user id that you are not expecting - for instance, cloud formation initiates scripts to run under the "Administrator" user even though the ec2config service runs under the system account.
* **Unexpected absence of environment variables**: when powershell runs under specific contexts, such as under a service or a special system account, some normally expected environment variables may not be present.  Path environment variable changes only propagate to services and some system contexts after a service restart or system reboot.
* **Unexpected absence or redirection of specific user profile elements**: For example the "System" account user profile folder does not contain the "Start Menu" folders like a regular user.  On 64-bit windows, the system account has a different user profile folder depending on bitness because it is under the system32 folder which is redirected to syswow64 for 32-bit execution.  In certain execution contexts the initiation of a process as a new user can stipulate whether to load the user's profile at all.
* **Unexpected or unknown initial environment**: for example, Packer uses the task scheduler ONLY when you specify a user name and password on a provisioner - otherwise it executes remotely.
* **Unexpected results when code is executed remotely**: for instance, windows updates - *.msu files - cannot be executed over remoting, including when they are bundled inside a setup.exe type installer.
* **Unexpected or unknown dynamic code execution**: some exes may contain and dynamically execute PowerShell code.
* **Unexpected or unknown PowerShell engine hosting**: for instance, Chocolatey 0.10.0 and later defaults to hosting powershell itself, rather than handing off to "powershell.exe" to be the PowerShell host.
