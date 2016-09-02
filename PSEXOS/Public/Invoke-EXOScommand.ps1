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
        [string]$command,
        
        [Parameter(mandatory=$false)]
        [alias("json")]
        [switch]$showjson
    )

process {
        $response,$session = Send-EXOSrpc -ip $ipaddress -cred $credential -cmd $command

        $clioutput = ($response.content |ConvertFrom-Json).result.clioutput
        $json = $response.content
} #end process

end {   
    if ($showjson) {
        return $clioutput, $json
    }
    elseif (-not $showjson) {
        return $clioutput
    }
} #end end

} #end function