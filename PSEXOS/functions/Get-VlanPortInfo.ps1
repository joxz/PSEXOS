function Get-VlanPortInfo {
<#
    .SYNOPSIS 
    Displays VLANs assigned to a list of ports.
    .DESCRIPTION
    Displays VLANs assigned to a list of ports. 
    You can see VLAN IDs, VLAN Names, tagged or untagged and VR.
    Output is a PSCustomObject and may be formatted or processed like any other PowerShell object.
    .PARAMETER ipaddress
    Specifies the IP address of the switch with http enabled.
    .PARAMETER credential
    Specifies the credentials to be used for the request as System.Management.Automation.PSCredential.
    .PARAMETER portlist
    Specifies the ports to display (format e.g.: "1-2" or "1:1-15").
    .INPUTS
    None. You cannot pipe objects to Get-VlanPortInfo.
    .OUTPUTS
    System.Management.Automation.PSCustomObject - Result of Get-VlanPortInfo contains Ports, VLANs, VLAN Names, VR Name
    .EXAMPLE
    Get-VlanPortInfo for ports 1-2 with additional processing for visibility

    C:\PS> $res = Get-VlanPortInfo -ip "10.1.0.1" -cred (Get-Credential) -ports "1-2"
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

    .EXAMPLE
    Get-VlanPortInfo for ports 1-2 piped to Out-GridView

    C:\PS> Get-vlanportinfo -ip "10.1.0.1" -cred (Get-Credential) -ports "1-2" | Sort-Object Port, Tag, VLAN_ID | Out-GridView
    .NOTES
    Get-VlanPortInfo relies on ExtremeXOS Machine to Machine Interface (MMI).
    ExtremeXOS MMI is compatible with ExtremeXOS 21.1+.
    Webserver needs to be enabled on the switch - 'enable web http'.
    http://documentation.extremenetworks.com/app_notes/MMI/121152_MMI_Application_Release_Notes.pdf
#>  
    [CmdletBinding()]
    Param(
        [Parameter(mandatory=$true)]
        [alias("ip")]
        [string]$ipaddress,

        [Parameter(mandatory=$true)]
        [alias("cred")]
        [System.Management.Automation.PSCredential]$credential,

        [Parameter(mandatory=$true)]
        [alias("ports")]
        [string]$portlist  
    )

begin {
    Write-Verbose -Message $($PSBoundParameters | Format-List | Out-String)

    # get ports in portlist
    $command = "debug cfgmgr show next vlan.show_ports_info port=None portList=$portlist"
    $response,$session = Send-EXOSrpc -ip $ipaddress -cred $credential -cmd $command

    # convert response to object
    $responseobj = $response.content | ConvertFrom-Json

    # arraylist for output
    [System.Collections.ArrayList]$result = @()
} #end begin

process {
    # loop portlist send webrequests for VLANs assigned to each port
    foreach ($item in $responseobj.result.data.port) {
        write-verbose -message "Port: $item"
        $commandvlan = "debug cfgmgr show next vlan.show_ports_info_detail_vlans port=$item vlanIfInstance=None"
        $portresponse = Send-EXOSrpc -ip $ipaddress -cmd $commandvlan -session $session

        Write-Verbose -Message "Parameters for request: $ipaddress`n $commandvlan`n $session`n"

        $portresponseobj = $portresponse.content | ConvertFrom-Json

        # loop VLANs for every port in portlist, find tagStatus
        foreach ($portobj in $portresponseobj.result.data) {
            Write-Verbose -message "VLAN objects for Port $item `n $portobj"
            if ($portobj.tagstatus -like "1") {
                $tag = "Tagged"
            } #end if
            elseif ($portobj.tagStatus -like "0") {
                $tag = "PVID"
            }

            $obj=[pscustomobject] @{
                'Port' = $item
                'VLAN_ID' = $portobj.vlanId
                'Name' = $portobj.vlanName
                'Tag' = $tag
                'VR' = $portobj.vrName
            }

            # add object to ArrayList
            [void]$result.add($obj)

        } #end foreach
    } #end foreach
} #end process

end {
    return $result
} #end end

} #end function