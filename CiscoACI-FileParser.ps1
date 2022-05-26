function CiscoACI-FileParser {
    param (
        [Parameter(Mandatory=$true)]
        [ArgumentCompleter({
            param($cmdName, $paramName, $wordToComplete, $cmdAst, $preBoundParameters)
            $props = (Get-ChildItem | Where-Object { ($_.Extension -match '.xml') -or ($_.Extension -match '.json')} ).Name
            @($props) -like "$wordToComplete*"
        })]
        [System.IO.FileInfo]$fileName,

        [Parameter(Mandatory=$false)]
        [ArgumentCompleter({
            param($cmdName, $paramName, $wordToComplete, $cmdAst, $preBoundParameters)
                if ($typedFileName = $preBoundParameters['fileName']) {
                    if ($typedFileName -match '\.xml') {
                        [xml]$xml = Get-Content -Path $typedFileName
                        if ($xml.imdata) { $props = ($xml.imdata | Get-Member| Where-Object {$_.MemberType -eq 'Property'} ).Name }
                        else { $props = ($xml | Get-Member| Where-Object {$_.MemberType -eq 'Property'} ).Name }
                    }
                    elseif ($typedFileName -match '\.json') {
                        $json = Get-Content $typedFileName | ConvertFrom-Json
                        if ($json.imdata) { $props = ($json.imdata | Get-Member| Where-Object {$_.MemberType -eq 'NoteProperty'} ).Name }
                        else { $props = ($json | Get-Member| Where-Object {$_.MemberType -eq 'NoteProperty'} ).Name }
                    }
                    @($props) -like "$wordToComplete*"
                }
        })]
        [string]$class,

        [Parameter(Mandatory=$false)][string]$name
    )

    $fileExtension = Get-ChildItem | Where-Object Name -eq $fileName | Select-Object -ExpandProperty Extension
    if ($fileExtension -match 'xml') { [xml]$importedObject = Get-Content -Path $fileName }
    elseif ($fileExtension -match 'json') { $importedObject = Get-Content $fileName | ConvertFrom-Json }

    if ($class -match 'firmware') {
        # Returns a firmware summary
        Write-Warning "Returning a firmware summary instead $class"
        $toReturn = @()
        $toReturn += $importedObject.imdata.firmwareCtrlrRunning | Select-Object dn, type, mode, version -Unique
        $toReturn += $importedObject.imdata.firmwareRunning | Select-Object dn, type, mode, version -Unique
    }
    elseif ($class) {
        # Returns the class specified by user
        if ($name) { $toReturn = $importedObject.imdata.$class | Where-Object name -eq $name}
        else { $toReturn = $importedObject.imdata.$class }
    }
    elseif (-not $class) {
        # Returns all available classes
        if ($importedObject.imdata) { $toReturn = $importedObject.imdata }
        else { $toReturn = $json }
    }

    return $toReturn

}
