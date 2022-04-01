class aciFaultInst {
  [string]$faultType = 'fault.Inst'
  [string]$code
  [string]$ack
  [string]$annotation
  [string]$cause
  [string]$changeSet
  [string]$childAction
  [string]$created
  [string]$delegated
  [string]$descr
  [string]$dn
  [string]$domain
  [string]$extMngdBy
  [string]$highestSeverity
  [string]$lastTransition
  [string]$lc
  [string]$modTs
  [int]$occur
  [string]$origSeverity
  [string]$prevSeverity
  [string]$rn
  [string]$rule
  [string]$severity
  [string]$status
  [string]$subject
  [string]$type
  [string]$uid
}

class aciFaultDelegate {
  [string]$faultType = 'fault.Delegate'
  [string]$affected
  [string]$code
  [string]$ack
  [string]$cause
  [string]$changeSet
  [string]$childAction
  [string]$created
  [string]$descr
  [string]$dn
  [string]$domain
  [string]$highestSeverity
  [string]$lastTransition
  [string]$lc
  [string]$modTs
  [int]$occur
  [string]$origSeverity
  [string]$prevSeverity
  [string]$rn
  [string]$rule
  [string]$severity
  [string]$status
  [string]$subject
  [string]$type
}

function CiscoACI-FaultParserImport {
  <#
    .SYNOPSIS
    Import faults from a file with moquery raw output content.

    .DESCRIPTION
    You can import a moquery output for faultInfo, faultInst or faultDelegate into a PowerShell variable. You can use this variable to make queries and views using PS tools such as 'Where-Object', 'Select-Object' and so on. 

    .EXAMPLE
    CiscoACI-FaultParserImport -faultsFile .\moquery-faultInfo.txt

    .NOTES
    Only the moquery output is accepted. Make sure the file first line contains the '# fault' for the first fault and that there is no blank lines at the end.

    .PARAMETER faultsFile
    Specifies the file name for the file.
  #>

  param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({
      if (-not ($_ | Test-Path)) { throw "File not found" }
      else { return $true }
    })]
    [System.IO.FileInfo]$faultsFile
  )

  Write-Progress -Activity "Reading file $faultsFile" -PercentComplete 0
  $faultInfo = Get-Content $faultsFile

  $script:faults = @()
  [int]$lineTot = $faultInfo.count
  [int]$faultNum = 1
  for ($lineNum = 0 ; $lineNum -lt $lineTot; $lineNum++) {
    if ( ($faultInfo[$lineNum] -eq '# fault.Inst') -or ($faultInfo[$lineNum] -eq '# fault.Delegate') ){
        $f_faultType = $faultInfo[$lineNum]
        $vars = @()
        $vars += 'faultType'
    }
    elseif ($faultInfo[$lineNum] -eq '') {
      if ($f_faultType -eq '# fault.Inst') {
        $script:faults += [aciFaultInst]$fault = @{
          code = $f_code
          ack = $f_ack
          annotation = $f_annotation
          cause = $f_cause
          changeSet = $f_changeSet
          childAction = $f_childAction
          created = $f_created
          delegated = $f_delegated
          descr = $f_descr
          dn = $f_dn
          domain = $f_domain
          extMngdBy = $f_extMngdBy
          highestSeverity = $f_highestSeverity
          lastTransition = $f_lastTransition
          lc = $f_lc
          modTs = $f_modTs
          occur = $f_occur
          origSeverity = $f_origSeverity
          prevSeverity = $f_prevSeverity
          rn = $f_rn
          rule = $f_rule
          severity = $f_severity
          status = $f_status
          subject = $f_subject
          type = $f_type
          uid = $f_uid
        }
      }
      elseif ($f_faultType -eq '# fault.Delegate') {
        $script:faults += [aciFaultDelegate]$fault = @{
          affected = $f_affected
          code = $f_code
          ack = $f_ack
          cause = $f_cause
          changeSet = $f_changeSet
          childAction = $f_childAction
          created = $f_created
          descr = $f_descr
          dn = $f_dn
          domain = $f_domain
          highestSeverity = $f_highestSeverity
          lastTransition = $f_lastTransition
          lc = $f_lc
          modTs = $f_modTs
          occur = $f_occur
          origSeverity = $f_origSeverity
          prevSeverity = $f_prevSeverity
          rn = $f_rn
          rule = $f_rule
          severity = $f_severity
          status = $f_status
          subject = $f_subject
          type = $f_type
        }
      }
      Foreach ($v in $vars) { Remove-Variable -Name "f_$v"}
      $faultNum++
      Write-Progress -Activity "Importing faults to the 'faults' variable" -Status "Fault $faultNum imported" -PercentComplete ($lineNum/$lineTot*100)
    }
    else {
      $varName = $faultInfo[$lineNum] -replace ' .*:.*'
      $varValue = ($faultInfo[$lineNum] -replace $varName).Trim().Substring(1).Trim()
      New-Variable -Name "f_$varName" -Value $varValue
      $vars += $varName
    }
  }
  Foreach ($v in $vars) { Remove-Variable -Name "f_$v"}

  ''
  '# Top 10 stats: '
  $faults | group -Property code | sort count -Descending | select Count, Name -First 10
  ''
  "# $($script:faults.count) faults available in 'faults' variable."
  ''
}
