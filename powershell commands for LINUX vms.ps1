# powershell commands for enhanced session for hyper-v VMs 
# also see xrdp install shell script (for use on guest VM)

# enable hyper-v 
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# see if host windows box has enhanced session mode turned on
Get-VMHost | select Name, EnableEnhancedSessionMode

# if not true, then set as true
Set-VMHost -EnableEnhancedSessionMode $true

# set guest VM to use hvsocket
Set-VM -VMName <Name-of-VM> -EnhancedSessionTransportType HvSocket



