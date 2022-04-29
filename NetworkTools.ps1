function NetworkTools-ConvertHexToIP ([parameter(mandatory=$true)][string]$Hex) {

    if ($Hex.ToString() -match '0x') { [string]$Hex = $Hex -replace '0x'}
    $hexPairs = @()
    -4..-1 | ForEach-Object { if ("$($Hex[2*$_])$($Hex[(2*$_)+1])") {$hexPairs += "$($Hex[2*$_])$($Hex[(2*$_)+1])"} }
    [IPAddress]$ipAddress = ($hexPairs | ForEach { [convert]::ToInt32($_,16) }) -join '.'

    return $ipAddress.IPAddressToString
}
