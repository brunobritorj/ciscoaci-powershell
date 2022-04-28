function NetworkTools-ConvertHexToIP ([parameter(mandatory=$true)][string]$Hex) {

    if ($Hex.ToString() -match '0x') { [string]$Hex = $Hex -replace '0x'}

    $hexPairs = @()
    $hexPairs += "$($Hex[-8])$($Hex[-7])"
    $hexPairs += "$($Hex[-6])$($Hex[-5])"
    $hexPairs += "$($Hex[-4])$($Hex[-3])"
    $hexPairs += "$($Hex[-2])$($Hex[-1])"

    [IPAddress]$ipAddress = ($hexPairs | ForEach { [convert]::ToInt32($_,16) }) -join '.'

    return $ipAddress.IPAddressToString
}
