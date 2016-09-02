function Send-XOSrpc {
<#
    .SYNOPSIS 
    Sends commands to an ExtremeXOS switch with JSONRPC enabled.
    .DESCRIPTION
    Sends commands to an ExtremeXOS switch with JSONRPC enabled. 
    When used with credentials this function returns 2 objects, WebResponseObject and Sessionvariable.
    The Sessionvariable can be used by following requests, no credentials necessary.
    .PARAMETER ipaddress
    Specifies the IP Address of the switch with http enabled.
    .PARAMETER command
    Specifies the command to be executed.
    .PARAMETER credential
    Specifies the credentials to be used for the request.
    .PARAMETER session
    Specifies the session to be used for the request. 
    .INPUTS
    None. You cannot pipe objects to New-XOSjsonrpc
    .OUTPUTS
    Microsoft.PowerShell.Commands.WebResponseObject - Result of the request.
    System.Object - Sessionvariable returned with the first request for use with subsequent requests (cookie).
    .EXAMPLE
    Request with credentials provided

    C:\PS> $request,$session = Send-XOSrpc -ip "10.1.1.1" -cmd "show vlan" -cred (Get-Credential)
    C:\PS> $request
        StatusCode        : 200
        StatusDescription : OK
        Content           : {
                      "id": "1",
                      "jsonrpc": "2.0",
                      "result": [
        ....
    C:\PS> $session
        Headers               : {[AUTHORIZATION, Basic YWRdsdsd6U3RFghjTZIwRPLY=]}
        Cookies               : System.Net.CookieContainer
        UseDefaultCredentials : False
        Credentials           :
        Certificates          :
        UserAgent             : Mozilla/5.0 (Windows NT; Windows NT 10.0; de-DE) WindowsPowerShell/5.1.14393.82
        Proxy                 :
        MaximumRedirection    : -1    
    C:\PS>$request.content | ConvertFrom-Json
    .EXAMPLE
    Request using a session

    C:\PS> $request = Send-XOSrpc -ip "10.1.1.1" -cmd "show vlan" -session $session
    C:\PS> $request
        StatusCode        : 200
        StatusDescription : OK
        Content           : {
                      "id": "1",
                      "jsonrpc": "2.0",
                      "result": [
        ....
    C:\PS>$request.content | ConvertFrom-Json
    .NOTES
    Send-XOSjsonrpc relies on ExtremeXOS Machine to Machine Interface (MMI).
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
        [alias("cmd")]
        [string]$command,

        [Parameter(mandatory=$false)]
        [alias("cred")]
        [System.Management.Automation.PSCredential]$credential,        

        [Parameter(mandatory=$false)]
        [alias("sess")]
        [System.Object]$session
    ) #end Param

begin {
    write-verbose -Message $($PSBoundParameters | Format-List | Out-String)

    #set uri
    $uri = "http://" + $ipaddress + "/jsonrpc"

    #generate random id for request
    $id = Get-Random -Maximum 999

    #build command for request
    $body = @"
{"method":"cli","id":"$id","jsonrpc":"2.0","params":["$command"]}
"@
} #end begin

process {
    if ((-not $session) -and $credential) {
        write-verbose -Message "No session provided, using credentials"
        
        #set authorization for header
        try {
           $base64authinfo = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $credential.GetNetworkCredential().UserName,$credential.GetNetworkCredential().Password))) 
        }
        catch [System.Exception] {
           break; 
           Write-Verbose -Message "Conversion to Base64 Header failed"
        } #end trycatch        
        
        #splatting webrequest parameters
        $reqparams = @{
            Uri = $uri
            Method = 'POST'
            ContentType = 'application/json'
            SessionVariable = 'session'
            Headers = @{AUTHORIZATION = $base64authinfo}
            ErrorAction = 'stop'
            Body = $body
        } #end hastable
        
        # invoke webrequest with previously defined parameters
        try {
            Write-Verbose -Message "Running $($MyInvocation.MyCommand).`nPSBoundParameters:$($PSBoundParameters | Format-List | Out-String)`n Invoke-WebRequest parameters: $($reqparams | Format-List | Out-String)"
            $webreq = Invoke-WebRequest @reqparams
            Write-Verbose -Message "Connection Status: $($webreq.StatusCode), $($webreq.StatusDescription)"

            return $webreq, $session
        }
        catch {
            throw "Error retrieving session: $_"
        } #end trycatch
    } #end if

    elseif ($session -and (-not $credential)) {
        write-verbose -Message "Session provided, using cookie"
        
        #splatting webrequest parameters
        $reqparams = @{
            Uri = $uri
            Method = 'POST'
            ContentType = 'application/json'
            WebSession = $session
            ErrorAction = 'stop'
            Body = $body
        } #end hastable

        # invoke webrequest with previously defined parameters
        try {
            Write-Verbose -Message "Running $($MyInvocation.MyCommand).`nPSBoundParameters:$($PSBoundParameters | Format-List | Out-String)`n Invoke-WebRequest parameters: $($reqparams | Format-List | Out-String)"
            $webreq = Invoke-WebRequest @reqparams
            Write-Verbose -Message "Connection Status: $($webreq.StatusCode), $($webreq.StatusDescription)"

            return $webreq
        }
        catch {
            throw "Error retrieving session: $_"
        } #end trycatch

    } #end elseif

    else {
        throw "Please provide either credentials or a session"
    } #end else
} #end process

} #end function
