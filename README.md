# check_horizonview

I have start to writing a collection of checkmk checks to monitor Horizon View on the base of https://github.com/tschubb/check_horizonview The scripts are designed to used with Check MK Agent on a Windows host.

**Current Version:** Release v1.0

Checks:

 * check_horizonview_sessions.ps1 - checks the amount of sessions in a connected or disconnected state. (outputs perf data)
 * check_horizonview_provisioning_error.ps1 - checks for machines in a provisioning_error state.
 * check_horizonview_agent_unreachable.ps1 - checks for machines in a agent_unreachable state.
 * check_horizonview_disabled_pools.ps1 - checks for pools in a disabled state.

Use Powershell Get-Help for more detail on how to use each script.

## Script Dependencies

Microsoft Windows Powershell 5.1
[Windows Powershell Downloads](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-windows-powershell?view=powershell-6#upgrading-existing-windows-powershell)

The Powershell scripts require the PowerCLI 6.5 R1 and Hv.Helper to be installed.

[VMware blog](https://blogs.vmware.com/euc/2017/01/vmware-horizon-7-powercli-6-5.html)

[Hv.Helper Github](https://github.com/vmware/PowerCLI-Example-Scripts)

## How it Works with Check MK

...

## Release Notes

v1.0 - Initial version changed from https://github.com/tschubb/check_horizonview

## Contribute/Feature Requests

I am always happy to recieve feedback good or bad. I plan to improve and expand on these checks.

Drop me a line if you find a bug or want a feature adding to an existing check or have an idea for an addtional check.

Feel free to message me if you need help getting the checks working in your environment. 

https://github.com/mccrossen/checkmk_horizonview
