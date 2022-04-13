function CiscoACI-XmlParser {
    param (
        [Parameter(Mandatory=$true)]
        [ArgumentCompleter({
            param($cmdName, $paramName, $wordToComplete, $cmdAst, $preBoundParameters)
            $props = (Get-ChildItem | Where-Object Extension -match '.xml').Name
            @($props) -like "$wordToComplete*"
        })]
        [System.IO.FileInfo]$xmlFile,

        [Parameter(Mandatory=$false)]
        [ArgumentCompleter({
            param($cmdName, $paramName, $wordToComplete, $cmdAst, $preBoundParameters)
                if ($obj = $preBoundParameters['xmlFile']) {
                    [xml]$xml = Get-Content -Path $obj
                    if ($xml.imdata) { $props = ($xml.imdata | Get-Member| Where {$_.MemberType -eq 'Property'} ).Name }
                    else { $props = ($xml | Get-Member| Where {$_.MemberType -eq 'Property'} ).Name }
                    @($props) -like "$wordToComplete*"
                }
        })]
        [string]$class,

        [Parameter(Mandatory=$false)][string]$name
    )

    [xml]$xml = Get-Content -Path $xmlFile

    if ($class -match 'firmware') {
        Write-Warning "Returning a firmware summary instead $class"
        $toReturn = @()
        $toReturn += $xml.imdata.firmwareCtrlrRunning | Select-Object dn, type, mode, version -Unique
        $toReturn += $xml.imdata.firmwareRunning | Select-Object dn, type, mode, version -Unique
    }
    elseif ($class) {
        if ($name) { $toReturn = $xml.imdata.$class | Where-Object name -eq $name}
        else { $toReturn = $xml.imdata.$class }
    }
    elseif (-not $class) {
        if ($xml.imdata) { $toReturn = $xml.imdata }
        else { $toReturn = $xml }
    }
    return $toReturn
}
