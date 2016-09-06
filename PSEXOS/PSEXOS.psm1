Set-StrictMode -Version Latest
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

$ps1s = Get-ChildItem -Path ("$here\Functions\") -Filter *.ps1

ForEach ($ps1 in $ps1s)
{
    Write-Verbose "Loading $($ps1.FullName)"
    . $ps1.FullName
}

$functionstoexport = @(
    'Invoke-EXOScommand'
    'Get-Vlans'
    'Get-VlanPortInfo'
)

#Export functions
Export-ModuleMember -Function $functionsToExport