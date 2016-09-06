function Invoke-EXOScommand {
<#
    .SYNOPSIS 
    Invokes command on an EXOS switch.
    .DESCRIPTION
    Invokes command on an EXOS switch. 
    When used this function returns the CLIoutput as formatted text and when used with '-json' the JSON response as PowerShell Object.
    .PARAMETER ipaddress
    Specifies the IP address of the switch with http enabled.
    .PARAMETER command
    Specifies the command to be executed.
    .PARAMETER credential
    Specifies the credentials to be used for the request.
    .PARAMETER json
    JSON output on (default: off). 
    .INPUTS
    Pipeline input for IPAddresses accepted. See example below
    .OUTPUTS
    System.String - CLIouput as formatted text.
    System.String - JSON output
    Successful commands without a CLI output display empty strings (e.g. 'create vlan test')
    .EXAMPLE
    Command with only CLIouput

    C:\PS> $cmd = Invoke-EXOScommand -ip "10.1.1.1" -cred (Get-Credential) -command "show vlan"
    C:\PS> $cmd
        -----------------------------------------------------------------------------------------------
        Name            VID  Protocol Addr       Flags                         Proto  Ports  Virtual
                                                                                      Active router
                                                                                      /Total
        -----------------------------------------------------------------------------------------------
        Ctrl            1234 --------------------------------------C---------  ANY    0 /2   VR-Default
        Default         1    --------------------------------T---------------  ANY    0 /1   VR-Default
        lala            123  ------------------------------------------------  ANY    0 /2   VR-Default
        Mgmt            4095 10.139.12.35   /24  ----------------------------  ANY    1 /1   VR-Mgmt
        v254            254  192.168.254.51 /24  ------------------P---------  ANY    0 /2   VR-Default
        voice           5    ------------------------------------------------  ANY    0 /1   VR-Default
        wlan            110  ------------------------------------------------  ANY    0 /1   VR-Default

        ...
    .EXAMPLE
    Command with JSON output

    C:\PS> $cmd,$json = Invoke-EXOScommand -ip "10.1.1.1" -cred (Get-Credential) -command "show port 1 statistics" -json
    C:\PS> $json
        {
          "id": "297",
          "jsonrpc": "2.0",
          "result": [
            {
              "CLIoutput": "Port      Link       Tx Pkt     Tx Byte      Rx Pkt     Rx Byte      Rx Pkt      Rx Pkt      Tx Pkt
             Tx Pkt\n          State       Count       Count       Count       Count       Bcast       Mcast       Bcast       M
        cast\n========= ===== =========== =========== =========== =========== =========== =========== =========== ===========\n1
                 R               0           0           0           0           0           0           0           0\n========
        = ===== =========== =========== =========== =========== =========== =========== =========== ===========\n          > in
        Port indicates Port Display Name truncated past 8 characters\n          > in Count indicates value exceeds column width.
         Use 'wide' option or '0' to clear.\n          Link State: A-Active, R-Ready, NP-Port Not Present, L-Loopback\n"
            },
            {
              "show_ports_stats": {
                "dot1dTpPortInDiscards": 0,
                "dot1dTpPortInFrames": 0,
                "dot1dTpPortMaxInfo": 1500,
                "dot1dTpPortOutFrames": 0,
                "linkState": 0,
                "port": 1,
                "portList": 1,
                "portNoSnmp": 1,
                "rxBcast": 0,

        ...
    .EXAMPLE
    Multiple commands are also supported

    C:\PS> Invoke-EXOScommand -ip "10.1.1.1" -cred (Get-Credential) -command "create vlan test tag 888; show vlan"
    .EXAMPLE
    Pipeline Input

    C:\PS> $ip = "10.1.1.1","10.1.1.2"
    C:\PS> $ip | % { Invoke-EXOScommand -ip $_ -cred (Get-Credential) -cmd "show vlan" }
    .NOTES
    Send-XOSjsonrpc relies on ExtremeXOS Machine to Machine Interface (MMI).
    ExtremeXOS MMI is compatible with ExtremeXOS 21.1+.
    Webserver needs to be enabled on the switch - 'enable web http'.
    http://documentation.extremenetworks.com/app_notes/MMI/121152_MMI_Application_Release_Notes.pdf
#>
    [CmdletBinding()]
    Param(
        [Parameter(mandatory=$true, ValueFromPipeline=$true)]
        [alias("ip")]
        [string[]]$ipaddress,

        [Parameter(mandatory=$true)]
        [alias("cred")]
        [System.Management.Automation.PSCredential]$credential,

        [Parameter(mandatory=$true)]
        [alias("cmd")]
        [string]$command,
        
        [Parameter(mandatory=$false)]
        [alias("json")]
        [switch]$showjson
    )

process {
    foreach ($ip in $ipaddress) {
        $response,$session = Send-EXOSrpc -ip $ip -cred $credential -cmd $command

        $clioutput = ($response.content | ConvertFrom-Json).result.clioutput
        $json = $response.content
        
        # give some output for commands without clioutput (e.g. "create vlan XXX")
        if ($clioutput.length -eq 0) {
            Write-Output "Command successful, empty CLIoutput returned"
        }
        
        # output json if parameter present
        if ($showjson) {
            return $clioutput, $json
        }
        else {
            return $clioutput
        }
    } #end foreach
} #end process

} #end function