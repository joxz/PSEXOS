function Get-Vlans {
<#
    .SYNOPSIS 
    Displays VLANs and VLAN properties.
    .DESCRIPTION
    Displays VLANs and VLAN properties. 
    You can see VLAN IDs, VLAN Names, tagged or untagged, IP addresses and VR.
    Output is a PSCustomObject and may be formatted or processed like any other PowerShell object.
    .PARAMETER ipaddress
    Specifies the IP address of the switch with http enabled.
    .PARAMETER credential
    Specifies the credentials to be used for the request as System.Management.Automation.PSCredential.
    .INPUTS
    None. You cannot pipe objects to Get-Vlans.
    .OUTPUTS
    System.Management.Automation.PSCustomObject
    .EXAMPLE
    Get-Vlans with additional formatting and filtering examples

    C:\PS> $res = Get-vlans -ip "10.139.12.35" -cred (Get-Credential)
    C:\PS> $res | Format-Table
        name    tag  activePorts taggedPorts untaggedPorts ipAddress      ipForwarding VR
        ----    ---  ----------- ----------- ------------- ---------      ------------ --
        Default 1    0                       2                                         VR-Default
        voice   5    0           2                                                     VR-Default
        wlan    110  0                       1                                         VR-Default
        lala    123  0           1-2                                                   VR-Default
        v254    254  0           1-2                       192.168.254.51              VR-Default
        Ctrl    1234 0           1-2                                                   VR-Default
        fdfdfd  4088 0                                                                 VR-Default
        Mgmt    4095 1                                     10.139.12.35                VR-Mgmt

    C:\PS> $res | ? ipAddress -like "10.*" | ft
        name tag  activePorts taggedPorts untaggedPorts ipAddress    ipForwarding VR
        ---- ---  ----------- ----------- ------------- ---------    ------------ --
        Mgmt 4095 1                                     10.139.12.35              VR-Mgmt

    .EXAMPLE
    Get-Vlans in Out-GridView
    
    C:\PS> Get-vlans -ip "10.139.12.35" -cred (Get-Credential) | ogv

    .NOTES
    Get-VlanPortInfo relies on ExtremeXOS Machine to Machine Interface (MMI).
    ExtremeXOS MMI is compatible with ExtremeXOS 21.1+.
    Webserver needs to be enabled on the switch - 'enable web http'.
    http://documentation.extremenetworks.com/app_notes/MMI/121152_MMI_Application_Release_Notes.pdf
#>
    #Requires -Version 3.0 
    [CmdletBinding()]
    Param(
        [Parameter(mandatory=$true)]
        [alias("ip")]
        [string]$ipaddress,

        [Parameter(mandatory=$true)]
        [alias("cred")]
        [System.Management.Automation.PSCredential]$credential
    )

begin {
    Write-Verbose -Message $($PSBoundParameters | Format-List | Out-String)

    # get vlan map
    $command = "debug cfgmgr show next vlan.vlanMap vlanList=1-4095"
    $response,$session = Send-EXOSrpc -ip $ipaddress -cred $credential -cmd $command

    # convert response to object
    $responseobj = $response.content | ConvertFrom-Json

    # arraylist for output
    [System.Collections.ArrayList]$result = @()
} #end begin

process {
    # loop through vlans
    foreach ($item in $responseobj.result.data.vlanName) {
        # remove the last empty item with status ERROR
        if ($item -notlike "") {
            $commandvlan = "debug cfgmgr show one vlan.vlanProc action=SHOW_VLAN_NAME name1=$item"
            $vlanresponse = Send-EXOSrpc -ip $ipaddress -cmd $commandvlan -session $session

            $vlanresponseobj = ($vlanresponse.content | ConvertFrom-Json).result.data

            $obj=[pscustomobject] @{
                'name' = $item
                'tag' = $vlanresponseobj.tag
                'activePorts' = $vlanresponseobj.activePorts
                'taggedPorts' = $vlanresponseobj.taggedPorts
                'untaggedPorts' = $vlanresponseobj.untaggedPorts
                'ipAddress' = $($vlanresponseobj.ipaddress -replace "0.0.0.0", "")
                'ipForwarding' = $($vlanresponseobj.ipforwardingStatus -replace "0","")
                'VR' = $vlanresponseobj.name2
            }

            # add object to ArrayList
            [void]$result.add($obj)
        } #end if
} #end foreach
    
} #end process

end {
    return $result
} #end end

} #end function