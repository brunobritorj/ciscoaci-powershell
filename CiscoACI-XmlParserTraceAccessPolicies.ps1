function CiscoACI-XmlParserTraceAccessPolicies {
  <#
    .SYNOPSIS
    Trace the access policies path for an EPG deployment from XML files.
    .DESCRIPTION
    Pass information about the EPG dn its deployment (node number, interface and vlan), be sure to have access to the XML files and trace if there is a valid path to it. 
    Be sure to be in the same folder as the XML files, each of them should contains its subtree. To collect them:
      icurl 'http://localhost:7777/api/class/infraNodeP.xml?query-target=subtree' > infraNodeP.xml
      icurl 'http://localhost:7777/api/class/infraAccPortP.xml?query-target=subtree' > infraAccPortP.xml
      icurl 'http://localhost:7777/api/class/infraHPortS.xml?query-target=subtree' > infraHPortS.xml
      icurl 'http://localhost:7777/api/class/infraAccPortGrp.xml?query-target=subtree' > infraAccPortGrp.xml
      icurl 'http://localhost:7777/api/class/infraAccBndlGrp.xml?query-target=subtree' > infraAccBndlGrp.xml
      icurl 'http://localhost:7777/api/class/infraAttEntityP.xml?query-target=subtree' > infraAttEntityP.xml
      icurl 'http://localhost:7777/api/class/physDomP.xml?query-target=subtree' > physDomP.xml
      icurl 'http://localhost:7777/api/class/fvnsVlanInstP.xml?query-target=subtree' > fvnsVlanInstP.xml
      icurl 'http://localhost:7777/api/class/fvAEPg.xml?query-target=subtree' > fvAEPg.xml
    .EXAMPLE
    CiscoACI-XmlParserTraceAccessPolicies -epgDn 'uni/tn-MyTenant/ap-MyApp/epg-MyEPG' -node 101 -int eth1/1 -vlan 10
    .EXAMPLE
    CiscoACI-XmlParserTraceAccessPolicies -epgDn 'uni/tn-MyTenant/ap-MyApp/epg-MyEPG' -node 101 -int eth1/1 -vlan 10 -detailed
    .EXAMPLE
    CiscoACI-XmlParserTraceAccessPolicies -epgDn 'uni/tn-MyTenant/ap-MyApp/epg-MyEPG' -node 101 -int eth1/1 -vlan 10 -quiet
    .PARAMETER epgDN
    Specifies the EPG dn. Example: 'uni/tn-MyTenant/ap-MyApp/epg-MyEPG'
    .PARAMETER node
    Specifies the node number of the deployment. Example: 101
    .PARAMETER int
    Specifies the interface name of the deployment. Example: eth1/1
    .PARAMETER vlan
    Specifies the vlan number of the deployment. Example: 10
    .PARAMETER detailed
    Enables full logging on screen.
    .PARAMETER epgDN
    Enables silent mode. Function will return only $true or $false for a valid path.
    .NOTES
    This function expects that the files have its object name, those are:
    fvAEPg.xml, fvnsVlanInstP.xml, infraAccBndlGrp.xml, infraAccPortGrp.xml, infraAccPortP.xml, infraAttEntityP.xml, infraHPortS.xml, infraNodeP.xml and physDomP.xml
    .LINK
    https://github.com/brunobritorj/ciscoaci-powershell
  #>

  param (
    [parameter(mandatory=$true)][string]$epgDn = 'uni/tn-TN_IT/ap-AP_PROD/epg-EPG-BDB-VMWARE-PROD-VSAN_VL-3007',
    [parameter(mandatory=$true)][int]$node = '610',
    [parameter(mandatory=$true)][string]$int = '1/6',
    [parameter(mandatory=$true)][int]$vlan = 3007,
    [switch]$detailed,
    [switch]$quiet
  )

  # Check file presence
  '.\fvAEPg.xml', '.\fvnsVlanInstP.xml', '.\infraAccBndlGrp.xml', '.\infraAccPortGrp.xml', '.\infraAccPortP.xml', '.\infraAttEntityP.xml', '.\infraHPortS.xml', '.\infraNodeP.xml', '.\physDomP.xml' | ForEach-Object { if (-not (Test-Path $_)) { Write-Error "Missing $_ file"} }

  # Remove 'eth' string from interface
  if ($int -match 'eth.\/[\d]') { $int = $int -replace 'eth'}

  if ($detailed) { $DebugPreference = 'Continue' }
  elseif ($quiet) { $WarningPreference = 'SilentlyContinue' }
  if ($detailed -and $quiet) { Write-Debug 'DETAILED takes preference than QUIET' }

  $EPG = [PSCustomObject]@{
    dn = $epgDn
    node = $node
    int = $int
    vlan = $vlan
  }

  Write-Debug '# PHYSICAL PATH'    
  Write-Debug '' 
  $physicalPaths = @()

  # NODE BLOCK(S)
  $infraNodeBlk = CiscoACI-XmlParser infraNodeP.xml infraNodeBlk | where { ($_.from_ -le $EPG.node) -and ($_.to_ -ge $EPG.node) }
  if (-not $infraNodeBlk) { Write-Warning "Unable to found any infraNodeBlk" }
  foreach ($nodeblk in $infraNodeBlk) {    
    Write-Debug "     1-infraNodeBlk $($nodeblk.dn)"

    # LEAF SELECTOR(S)
    $infraLeafS = CiscoACI-XmlParser infraNodeP.xml infraLeafS | where dn -Match ($nodeblk.dn -replace '/nodeblk-.*')
    foreach ($leafslct in $infraLeafS) {
      Write-Debug "       2-infraLeafS $($leafslct.dn)"

      # SWITCH PROFILE
      $infraNodeP = CiscoACI-XmlParser infraNodeP.xml infraNodeP | where dn -eq ($leafslct.dn -replace '/leaves-.*')
      Write-Debug "       3-infraNodeP $($infraNodeP.dn)"

      # INTERFACE PROFILE(s) connection from SwitchProfile
      $infraRsAccPortP = CiscoACI-XmlParser infraNodeP.xml infraRsAccPortP | where dn -Match ($infraNodeP.dn -replace '/rsaccPortP-.*')
      foreach ($intProf in $infraRsAccPortP) {
        Write-Debug "  4-infraRsAccPortP $($intProf.dn)"

        # INTERFACE PROFILE
        $infraAccPortP = CiscoACI-XmlParser infraAccPortP.xml infraAccPortP | where dn -eq $intProf.tDn
        Write-Debug "    5-infraAccPortP $($infraAccPortP.dn)"

        # PORT SELECTOR(S)
        $infraHPortS = CiscoACI-XmlParser infraAccPortP.xml infraHPortS | where dn -Match $infraAccPortP.dn
        foreach ($portselec in $infraHPortS) {
          Write-Debug "      6-infraHPortS $($portselec.dn)"

          # PORT BLOCK(S)
          $infraPortBlk = CiscoACI-XmlParser infraAccPortP.xml infraPortBlk | where dn -Match $portselec.dn | where { ($_.fromCard -le ($EPG.int -replace '/.*')) -and ($_.toCard -ge ($EPG.int -replace '/.*')) -and ($_.fromPort -le ($EPG.int -replace '.*/')) -and (($_.toPort -ge ($EPG.int -replace '.*/'))) }
          foreach ($portblk in $infraPortBlk) {
            Write-Debug "     7-infraPortBlk $($portblk.dn)"

            # IPG connection from PortSelector
            $infraRsAccBaseGrp = CiscoACI-XmlParser infraAccPortP.xml infraRsAccBaseGrp | where dn -Match $portselec.dn
            foreach ($ipgConn in $infraRsAccBaseGrp) {
              Write-Debug "8-infraRsAccBaseGrp $($ipgConn.dn)"

              # IPG --- (infraAccPortGrp for single ports OR infraAccBndlGrp for PC's/vPC's)
              $infraAccPortGrp = CiscoACI-XmlParser infraAccPortGrp.xml infraAccPortGrp | where dn -eq $ipgConn.tDn
              $infraAccBndlGrp = CiscoACI-XmlParser infraAccBndlGrp.xml infraAccBndlGrp | where dn -eq $ipgConn.tDn
              if ( (-not $infraAccPortGrp) -and (-not $infraAccBndlGrp) ) { Write-Warning "Unable to found either infraAccPortGrp or infraAccBndlGrp $($ipgConn.tDn)" }
              else {
                if ($infraAccPortGrp) { $IPG = $infraAccPortGrp }
                else { $IPG = $infraAccBndlGrp }
                Write-Debug "  9-infraAccBndlGrp $($IPG.dn)"

                # AEP connection from IPG
                $infraRsAttEntP = CiscoACI-XmlParser infraAccPortGrp.xml infraRsAttEntP | where dn -eq "$($IPG.dn)/rsattEntP" ### <-- Need to adapt to permit PC/vPC?
                if (-not $infraRsAttEntP) { Write-Warning "Unable to found an AEP for the IPG $($IPG.dn)"}
                else {
                  Write-Debug "  10-infraRsAttEntP $($infraRsAttEntP.dn) - Physical path found!"
                  $physicalPaths += [PSCustomObject]@{
                    SwitchProfile = $infraNodeP.dn
                    InterfaceProfile = $infraAccPortP.dn
                    InterfaceSelector = $portselec.dn
                    PortBlock = $portblk.dn
                    InterfacePolicyGroup = $IPG.dn
                    AepUnderIPG = $infraRsAttEntP.tDn
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  Write-Debug ''

  if (-not $physicalPaths) {
    if ((-not $quiet) -or $detailed) { Write-Warning "Unable to found any valid physical path" }
    else { return $false}
  }
  else {
    Write-Debug '# LOGICAL PATH'
    Write-Debug ''

    # EPG
    $fvAEPg = CiscoACI-XmlParser fvAEPg.xml fvAEPg | Where dn -eq $EPG.dn
    if (-not $fvAEPg) { Write-Warning "Unable to found any EPG with DN $($EPG.dn)" }
    else {
      Write-Debug "         1-fvAEPg $($fvAEPg.dn)"

      # DEPLOYED PATH connection from EPG
      $fvRsPathAtt = CiscoACI-XmlParser fvAEPg.xml fvRsPathAtt | where { ($_.dn -Match "$($EPG.dn).*$($EPG.node).*$($EPG.int)") -and ($_.encap -match $EPG.vlan) } # STATIC PATH (filtered by node/interface/vlan) associated to this EPG
      if (-not $fvRsPathAtt) { Write-Warning "Unable to found a path from this EPG to node $($EPG.node) interface $($EPG.int) vlan $($EPG.vlan)" }
      else { Write-Debug "    2-fvRsPathAtt $($fvRsPathAtt.dn)" }

      # DOMAIN connection(s) from EPG
      $fvRsDomAtt = CiscoACI-XmlParser fvAEPg.xml fvRsDomAtt | where dn -Match $EPG.dn # DOMAINS associated to this EPG
      if (-not $fvRsDomAtt) { Write-Warning "Unable to found any domain for the EPG" }
      else {
        $logicalPaths = @()
        foreach ($domAtt in $fvRsDomAtt) {
          Write-Debug "     3-fvRsDomAtt $($domAtt.dn)"
                    
          # DOMAIN(s) <<<- Need to adapt to multiple domains?!
          $physDomP = CiscoACI-XmlParser physDomP.xml physDomP | Where dn -in $domAtt.tDn
          if (-not $physDomP) { Write-Warning "Unable to found the domain $($domAtt.dn)" }
          else { Write-Debug "       4-physDomP $($physDomP.dn)" }

          #erase/restart vars for this domain
          $infraRsVlanNs = $fvnsVlanInstP = $fvnsEncapBlk = $infraRtDomP = $infraAttEntityP = $null

          # VLAN POOL connection from this domain
          $infraRsVlanNs = CiscoACI-XmlParser physDomP.xml infraRsVlanNs | where dn -Match "$($physDomP.dn)/rsvlanNs"
          Write-Debug "  5-infraRsVlanNs $($infraRsVlanNs.dn)"

          # VLAN Pool
          $fvnsVlanInstP = CiscoACI-XmlParser fvnsVlanInstP.xml fvnsVlanInstP | Where dn -eq $infraRsVlanNs.tDn
          Write-Debug "  6-fvnsVlanInstP $($fvnsVlanInstP.dn)"

          # VLAN Range
          $fvnsEncapBlk = CiscoACI-XmlParser fvnsVlanInstP.xml fvnsEncapBlk | where dn -Match "\[$($fvnsVlanInstP.name)\]-$($fvnsVlanInstP.allocMode)" | where { (($_.from -replace 'vlan') -le $EPG.vlan) -and (($_.to -replace 'vlan') -ge $EPG.vlan) }
          Write-Debug "   7-fvnsEncapBlk $($fvnsEncapBlk.dn)"

          # AEP connection from this domain
          $infraRtDomP = CiscoACI-XmlParser physDomP.xml infraRtDomP | where dn -Match "$($physDomP.dn)/rtdomP"
          Write-Debug "    8-infraRtDomP $($infraRtDomP.dn)"

          # AEP
          $infraAttEntityP = CiscoACI-XmlParser infraAttEntityP.xml infraAttEntityP | Where dn -eq $infraRtDomP.tDn
          Write-Debug "9-infraAttEntityP $($infraAttEntityP.dn)"

          # Full logical path
          if ( $infraRsVlanNs -and $fvnsVlanInstP -and $fvnsEncapBlk -and $infraRtDomP -and $infraAttEntityP ) {
            $logicalPaths += [PSCustomObject]@{
              Domain = $physDomP.dn
              VlanPool = $fvnsVlanInstP.dn
              VlanRange = $fvnsEncapBlk.dn
              AepUnderDomain = $infraRtDomP.tDn
            }
          }
        }

        # Full physical and logical path
        if ($physicalPaths.AepUnderIPG -ne $logicalPaths.AepUnderDomain ) {
          if ((-not $quiet) -or $detailed) { Write-Warning 'Not able to determine the full path due to different AEPs under physical and logical path' }
          else { return $false }
        }
        else {
          if ((-not $quiet) -or $detailed) {
            return [PSCustomObject]@{
              SwitchProfile = $physicalPaths.SwitchProfile
              InterfaceProfile = $physicalPaths.InterfaceProfile
              InterfaceSelector = $physicalPaths.InterfaceSelector
              PortBlock = $physicalPaths.PortBlock
              InterfacePolicyGroup = $physicalPaths.InterfacePolicyGroup
              AEP = $physicalPaths.AepUnderIPG
              Domain = $logicalPaths.Domain
              VlanPool = $logicalPaths.VlanPool
              VlanRange = $logicalPaths.VlanRange
            }
          }
          else { return $true }
        }
      }
    }
  }
}
