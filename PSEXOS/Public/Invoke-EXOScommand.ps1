function Invoke-EXOScommand {
    [CmdletBinding()]
    Param(
        [Parameter(mandatory=$true)]
        [alias("ip")]
        [string]$ipaddress,

        [Parameter(mandatory=$true)]
        [alias("cred")]
        [System.Management.Automation.PSCredential]$credential,

        [Parameter(mandatory=$true)]
        [alias("cmd")]
        [string]$command  
    )

begin {
    $response,$session = Send-EXOSrpc -ip $ipaddress -cred $credential -cmd $command
}

} #end function