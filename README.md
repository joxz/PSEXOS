# PSEXOS

## Description

This is a rudimentary Powershell module for working with the ExtremeXOS 'Machine to Machine Interface' (MMI) provided by Extreme Networks in EXOS version 21.1.4.
The script uses `Invoke-Webrequest` to send JSONRPC over HTTP to a remote EXOS switch. The returned JSON is parsed to PowerShell objects for further processing.

**Issues / Pull Requests welcome!**

## Instructions

````PowerShell
# manual setup
 # download the repository
 # copy the 'PSXOS' folder to a module path ($env:USERPROFILE\Documents\WindowsPowerShell\Modules\)
 Import-Module PSXOS (Import-Module \\Path\PSXOS)

# TODO: with PowerShell 5 and PowerShellGet
Install-Module PSXOS

# Get commands for the module
Get-Command -Module PSXOS
````

## Examples

### Display VLANs for selected ports

````PowerShell
  C:\PS> $res = Get-vlanportinfo -ip "10.1.0.1" -cred (Get-Credential) -ports "1-2"
  C:\PS> $res | Format-Table
        Port VLAN_ID Name    Tag    VR
        ---- ------- ----    ---    --
        1    1234    Ctrl    Tagged VR-Default
        1    254     v254    Tagged VR-Default
        1    123     lala    Tagged VR-Default
        1    110     wlan    PVID   VR-Default
        2    1       Default PVID   VR-Default
        2    1234    Ctrl    Tagged VR-Default
        2    254     v254    Tagged VR-Default
        2    123     lala    Tagged VR-Default
        2    5       voice   Tagged VR-Default


    C:\PS> $res | Sort-Object Port, Tag, VLAN_ID | Format-Table -GroupBy Port -auto

           Port: 1
       
        Port VLAN_ID Name Tag    VR
        ---- ------- ---- ---    --
        1    110     wlan PVID   VR-Default
        1    123     lala Tagged VR-Default
        1    1234    Ctrl Tagged VR-Default
        1    254     v254 Tagged VR-Default


           Port: 2
       
        Port VLAN_ID Name    Tag    VR
        ---- ------- ----    ---    --
        2    1       Default PVID   VR-Default
        2    123     lala    Tagged VR-Default
        2    1234    Ctrl    Tagged VR-Default
        2    254     v254    Tagged VR-Default
        2    5       voice   Tagged VR-Default
````
