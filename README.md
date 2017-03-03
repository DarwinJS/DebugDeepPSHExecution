#PowerShell Execution Is Frequently Buried Deep
PowerShell is frequently the last mile worker at the coal face - 5 miles out in a tunnel at the bottom of a mine shaft. 

This is because the breadth of Windows automation available through PowerShell results in it being embedded into almost every windows automation tooling stack - even when PowerShell is not the primary orchestration technology.  

Whether you are using configuration management like Chef, Puppet, Ansible or Salt or a continuous deployment tool such as Team City, TFS or Octopus or cloud orchestration such as Cloud Foundry or Cloud Formation or even a traditional ops tool like Systems Center - at some point, somewhere you will be compelled to call PowerShell.

Being at the end of a deep call stack of automation technologies is the daily norm for PowerShell, but it can make troubleshooting and debugging problems difficult for the automation developer.

#Blind Debugging of Deep PowerShell Execution

It can be pretty frustrating to try to debug or diagnose PowerShell code that that is initiated in call stacks like these:
* Packer => Remote Execution => PowerShell
* Chef Service => Ruby => PowerShell
* Packer => Remote Execution => Chef => Ruby => PowerShell
* CloudFormation => cfn-init => PowerShell
* SCCM Package Pushes

This is because PowerShell is initiated in a deep or indirect call stack where you are running blind because you are unable to easily view the process or results of execution.

There can be a variety of unexpected things about these execution contexts that don't match up with the runtime expectations of your code.  In some cases the calling system makes some effort to capture exit codes or errors - but many times this final result does not reveal enough to diagnose the problem.

In my experience, I spend a disproportionate amount of time initially learning the tricks and limitations of a new runtime environment - once I know them, the problems with new code are much less frequent.

Below is a list of challenges that can be uncovered with these scripts.  These are not theoretical challenges - I have personally experienced many of them.  In most cases finding these items was a surprise.  I don't use the list as a set of hypothesis.  Instead, my hypothesis is simply "if it is a deep or blind execution context - something unexpected might be happening"  Then I just start dumping information and ensuring I can record errors and look through the data - many times the problem is easy to spot when I have this kind of visibility into the execution environment and errors.

Some of these problems are made worse if PowerShell is running as part of operating System or software deployment automation.  There can also be special conditions on the first Windows bootup.

#Versus PowerShell 5 Remote Debugging Features
PowerShell 5 has some excellent remote debugging capabilities for finding out what's going on when things get really weird (https://youtu.be/dxXMwzWlJgA). These scripts are still very helpful because:
* They work for older versions of PowerShell and PowerShell Core on Linux/OSX.
* They are easy and obvious to use when you have not had exposure to the PowerShell debugger.
* They are helpful when PowerShell is executing in an environment which you cannot (or cannot easily) get to with PowerShell remoting.  This is sometimes due to security boundaries or the inability to get a cloud instance of Windows in a common network, security or firewall context with the node you need to debug.  You may not have a way to pause the surrounding orchestrating automation.  Etc, etc, etc.
* Even when you are confortable with remote debugging and are running PowerShell 5, these scripts can be a good first attempt at finding the information you need before resorting to full on remote debugging.
* The trap code is designed to be left in your code permanently for debugging.

#My List of the Unexpected
* **Unexpected / unknown / misconfigured execution bitness**: script executes as 32-bit when expecting 64-bit or vice versa. Some execution agents may be coded to specifically choose a bitness.  Execution under services will default to the bitness of the service - for instance SCCM 2012 "Package" objects run as 32-bit and "Application" objects run as 64-bit.  Many management agents for Windows are 32-bit even when installed on 64-bit Windows.
* **Unexpected / unknown / misconfigured user context**: script is executed by a user id that you are not expecting - for instance, cloud formation initiates scripts to run under the "Administrator" user even though the ec2config service runs under the system account.  Machine group policies run as the system account.
* **Unexpected absence of environment variables**: when powershell runs under specific contexts, such as under a service or a special system account, some normally expected environment variables may not be present.  Path environment variable changes (and others) only propagate to services and some system contexts after a service restart or system reboot (because the service manager only gets a new read on environment variables on a restart).
* **Unexpected absence or redirection of specific user profile elements**: For example the "System" account user profile folder does not contain the "Start Menu" folders like a regular user.  On 64-bit windows, the system account has a different user profile folder depending on bitness because it is under the system32 folder which is redirected to syswow64 for 32-bit execution.  In certain execution contexts the initiation of a process as a new user can stipulate whether to load the user's profile at all.
* **Unexpected or unknown initial environment**: for example, Packer uses the task scheduler ONLY when you specify a user name and password on a provisioner - otherwise it executes remotely.
* **Unexpected results when code is executed remotely**: for instance, windows updates - *.msu files - cannot be executed over remoting, including when they are bundled inside a setup.exe type installer.
* **Unexpected or unknown dynamic code execution**: some exes may contain and dynamically execute PowerShell code.
* **Unexpected or unknown reboot pending**: especially in cases where a machine build is laying down many subsequent layers of software and configuration changes, conditions can arise where a pending reboot affects deep execution more than foreground execution.  These conditions may give rise to requiring a reboot only when executing in the deep call stack.  Here the same example of system path changes or other environment variable changes not propagating until reboot also apply.  I have also seen situations where the WebAdministration PowerShell module can only be loaded at it's full path location, not with a relative reference when trying to use it immediately after installing the web-server feature.
* **Unexpected or unknown PowerShell engine hosting**: for instance, Chocolatey 0.10.0 and later defaults to hosting powershell itself, rather than handing off to "powershell.exe" to be the PowerShell host.
* **Unexpected or unknown security**: for instance, the user id executing PowerShell was added to a group, but was not re-logged on for that group membership to become active in the current process token or under Windows a lack of elevated admin rights when the code requires it.


#The Scripts
Compatibility Targets: PowerShell Core on Linux and Nano Server and Full PowerShell on Windows.
Whenever relevant these scripts are created to work on PowerShell for Windows and PowerShell Core for Linux and OSX (tested on CentOS).  This means they also contain some cool methods for detecting and accommodating running on non-windows targets under PowerShell Core.
This also means they are compatible with Nano Server as there are certain coding PowerShell techniques that do not work well on Nano

* PSHDeepExecutionDebugging-DumpRunEnvironment.ps1
  * Tested On: Windows and Linux
  * Usage: Run on it's own as a "script" or "job" in the deep execution context and examine the output.
  * Purpose: Dumps a variety of information such as environment variables, bitness, PowerShell variables, parent process and others to a text file.
  * Description: Used to discover many details about the run environment.  In the perfect world I would run this as the first script when trying to run PowerShell in a new run context for the first time, but I usually end up running it after my powershell code acts in unexpected ways.
* PSHDeepExecutionDebugging-ErrorTrapping.ps1
  * Tested On: Windows and Linux
  * Usage: Add to existing code that is failing with an error that is hard to diagnose, examine the output of the full .net error object.  This code can be left in place as your primary error trapping for deep execution powershell.
  * Purpose: Dumps the entire PowerShell $Error variable to a text file - many times this gives critical clues that allow nearly immediate identification of the cause or where to start looking for the cause.
  * Description: Can be left in place as primary error handling for deep execution scripts.
* PSHDeepExecutionDebugging-EnableGlobalTranscriptLogging.ps1
  * Tested On: Windows (PowerShell Core does not support policies on non-windows)
  * Usage: Run as admin on a machine to enable transcription (does not need to run in same context as the scripts you want to debug)
  * Purpose: Enables PowerShell global transcription which allows logging of PowerShell execution in any context.
  * Description: Used to discover problems and errors with deep execution scenarios.
* PSHDeepExecutionDebugging-AutomaticProcmonTrace.ps1
  * Tested On: Windows R2 Under CloudFormation
  * Usage: Start and stop procmon tracing with monitored code executing in between.
  * Purpose: Enables procmon tracing for a subset of a complex automation / orchestration stack where you cannot simply pause the process and manually execute procmon
  * Description: Get detailed procmon tracing of these events