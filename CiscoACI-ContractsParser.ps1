cls

function CiscoACI-ContractsParser {

  <#
    .SYNOPSIS
    Verify the contracts configuration between EPGs from a XML tenant file exported.
    .DESCRIPTION
    From a XML tenant file exported, verify the contracts between one or more EPGs in a given VRF. It could be an internal EPG (fvAEPg) or an external one from a L3Out (l3extInstP)
    .EXAMPLE
    CiscoACI-ContractsParser -XmlFile .\tn-MyTenant.xml -VrfName 'MyVrfName' -EPGs 'MyEPG1', 'MyEpg2'
    .EXAMPLE
    CiscoACI-ContractsParser -XmlFile .\tn-MyTenant.xml -VrfName 'MyVrfName' -EPGs 'MyEPG1', 'MyEpg2', 'MyEpg3'
    .PARAMETER XmlFile
    Specifies the file name for the exported tenant configuration.
    .PARAMETER VrfName
    Specifies the name of the VRF.
    .PARAMETER EPGs
    Specifies one or more EPG to be analyzed. It accepts internal EPGs (fvAEPg) or external ones from L3Outs (l3extInstP).
    .NOTES
    Only XML files, JSON is not supported. Only one tenant and intra VRF, route leaking is not supported for now.
    .LINK
    https://github.com/brunobritorj/ciscoaci-powershell
  #>

  param (
    [Parameter(Mandatory=$true)][System.IO.FileInfo]$XmlFile,
    [Parameter(Mandatory=$true)][String]$VrfName,
    [Parameter(Mandatory=$true)][String[]]$EPGs
  )

  [xml]$xml = Get-Content -Path $XmlFile

  $fvCtx = $xml.imdata.fvTenant.fvCtx | Where-Object name -EQ $VrfName
  if ($fvCtx) {
    $fvCtx = [PSCustomObject]@{
      Name = $fvCtx.name
      prefGrMemb = $fvCtx.vzAny.prefGrMemb
    }
  }

  $epgList = @()
  foreach ($epgName in $EPGs) {
    $epg = $xml.imdata.fvTenant.fvAp.fvAEPg | Where-Object name -EQ $epgName
    if ($epg) {
      $epgList += [PSCustomObject]@{
        Class = 'fvAEPg'
        Name = $epg.name
        prefGrMemb = $epg.prefGrMemb
        fvRsProv = $epg.fvRsProv.tnVzBrCPName
        fvRsCons = $epg.fvRsCons.tnVzBrCPName
        fvRsBd = $epg.fvRsBd
      }
    }
    else {
      $epg = $xml.imdata.fvTenant.l3extOut.l3extInstP | Where-Object name -EQ $epgName
      if ($epg) {
        $epgList += [PSCustomObject]@{
          Class = 'l3extInstP'
          Name = $epg.name
          prefGrMemb = $epg.prefGrMemb
          fvRsProv = $epg.fvRsProv.tnVzBrCPName
          fvRsCons = $epg.fvRsCons.tnVzBrCPName
        }
      }
      else { return "Consumer epg with name $epgName not found"}
    }
  }

  Write-Host "VRF $VrfName has prefGrMemb set to " -NoNewline
  if ($fvCtx.prefGrMemb -eq 'enabled') { Write-Host $fvCtx.prefGrMemb -BackgroundColor Green }
  else { Write-Host $fvCtx.prefGrMemb -BackgroundColor Red }
  return $epgList | Sort-Object Class | Format-Table
}
