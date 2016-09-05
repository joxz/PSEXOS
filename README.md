# PSEXOS

## Description

This is a rudimentary Powershell module for working with the ExtremeXOS 'Machine to Machine Interface' (MMI) provided by Extreme Networks in EXOS version 21.1.4.
The script uses `Invoke-Webrequest` to send JSONRPC over HTTP to a remote EXOS switch. The returned JSON is parsed to PowerShell objects for further processing.

**Issues / Pull Requests welcome!**

## Instructions

````PowerShell
# manual setup
 # download the repository
 # copy the 'PSEXOS' folder to a module path ($env:USERPROFILE\Documents\WindowsPowerShell\Modules\)
 Import-Module PSEXOS (Import-Module \\Path\PSEXOS)

# TODO: with PowerShell 5 and PowerShellGet
#Install-Module PSEXOS

# Get commands for the module
Get-Command -Module PSEXOS
````

## Examples

### Get-VlanPortInfo

Displays VLANs for selected ports tagged/untagged. Data is returned as a PSCustomObject.

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

### Invoke-EXOScommand

Invokes a command on an EXOS switch. CLIoutput is returned, the JSON aswell if parameter provided. The JSON response can then be parsed to PowerShell objects.

````Powershell
  C:\PS> $res = Invoke-EXOScommand -ip "10.1.1.1" -cred (Get-Credential) -cmd "show vlan"
  C:\PS> $res

      -----------------------------------------------------------------------------------------------
      Name            VID  Protocol Addr       Flags                         Proto  Ports  Virtual
                                                                                    Active router
                                                                                    /Total
      -----------------------------------------------------------------------------------------------
      Ctrl            1234 --------------------------------------C---------  ANY    0 /2   VR-Default
      Default         1    --------------------------------T---------------  ANY    0 /1   VR-Default
      fdfdfd          4088 ------------------------------------------------  ANY    0 /0   VR-Default
      lala            123  ------------------------------------------------  ANY    0 /2   VR-Default
      Mgmt            4095 10.139.12.35   /24  ----------------------------  ANY    1 /1   VR-Mgmt
      v254            254  192.168.254.51 /24  ------------------P---------  ANY    0 /2   VR-Default
      voice           5    ------------------------------------------------  ANY    0 /1   VR-Default
      wlan            110  ------------------------------------------------  ANY    0 /1   VR-Default
      -----------------------------------------------------------------------------------------------
      Flags : (B) BFD Enabled, (c) 802.1ad customer VLAN, (C) EAPS Control VLAN,
              (d) Dynamically created VLAN, (D) VLAN Admin Disabled,
              (e) CES Configured, (E) ESRP Enabled, (f) IP Forwarding Enabled,
              (F) Learning Disabled, (i) ISIS Enabled,
              (I) Inter-Switch Connection VLAN for MLAG, (k) PTP Configured,
              (l) MPLS Enabled, (L) Loopback Enabled, (m) IPmc Forwarding Enabled,
              (M) Translation Member VLAN or Subscriber VLAN, (n) IP Multinetting Enabled,
              (N) Network Login VLAN, (o) OSPF Enabled, (O) Virtual Network Overlay,
              (p) PIM Enabled, (P) EAPS protected VLAN, (r) RIP Enabled,
              (R) Sub-VLAN IP Range Configured, (s) Sub-VLAN, (S) Super-VLAN,
              (t) Translation VLAN or Network VLAN, (T) Member of STP Domain,
              (v) VRRP Enabled, (V) VPLS Enabled, (W) VPWS Enabled, (Z) OpenFlow Enabled

      Total number of VLAN(s) : 8
````

## Notes

* ExtremeXOS MMI is compatible with ExtremeXOS 21.1+.
* Webserver needs to be enabled on the switch
  * `enable web http`
  * an **admin level user with password** has to be used
* <http://documentation.extremenetworks.com/app_notes/MMI/121152_MMI_Application_Release_Notes.pdf>

## TODOs

* Add SSL support
* Add Proxy support
* Store cookie for repeated use of Invoke-EXOScommand
* Multiple inputs and pipeline support for Invoke-EXOScommand
* Make PSEXOS compatible for PowerShell5 and PowerShellGet (upload to PSGallery)