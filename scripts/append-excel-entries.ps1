# Append recovered submission rows to Group Stage Entries.xlsx
# Usage: .\scripts\append-excel-entries.ps1 -InputPath .\recovered-entries.json

param(
  [Parameter(Mandatory = $true)]
  [string]$InputPath
)

Import-Module ImportExcel -ErrorAction Stop

$excelPath = "$env:OneDriveCommercial\World Cup 2026 Pool\Group Stage Entries.xlsx"
if (-not (Test-Path $excelPath)) {
  $excelPath = "$env:OneDrive\World Cup 2026 Pool\Group Stage Entries.xlsx"
}
if (-not (Test-Path $excelPath)) {
  throw 'Excel file not found under OneDrive\World Cup 2026 Pool\Group Stage Entries.xlsx'
}

$incoming = Get-Content -Raw -Path $InputPath | ConvertFrom-Json
if ($incoming -isnot [array]) { $incoming = @($incoming) }

$existing = Import-Excel $excelPath -WorksheetName 'Group Stage Entries'
$existingNames = @($existing | Where-Object { $_.PlayerName } | ForEach-Object { $_.PlayerName.Trim().ToLower() })

$groups = @('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L')
$added = 0

foreach ($item in $incoming) {
  $name = if ($item.playerName) { $item.playerName } else { $item.PlayerName }
  $name = $name.Trim()
  if (-not $name) { continue }
  if ($existingNames -contains $name.ToLower()) {
    Write-Host "Skip (already in Excel): $name"
    continue
  }

  $emailVal = if ($item.playerEmail) { $item.playerEmail } elseif ($item.Email) { $item.Email } else { '' }
  $submittedVal = if ($item.submittedAt) { $item.submittedAt } elseif ($item.SubmittedAt) { $item.SubmittedAt } else { (Get-Date).ToUniversalTime().ToString('o') }

  $row = [ordered]@{
    PlayerName  = $name
    Email       = $emailVal.Trim()
    SubmittedAt = $submittedVal
  }

  foreach ($g in $groups) {
    foreach ($pos in @('1st', '2nd', '3rd', '4th')) {
      $col = "Group${g}_$pos"
      $row[$col] = $item.$col
      if (-not $row[$col] -and $item.groups) {
        $idx = @{ '1st' = 0; '2nd' = 1; '3rd' = 2; '4th' = 3 }[$pos]
        $row[$col] = $item.groups.$g[$idx]
      }
    }
  }

  $existing += [pscustomobject]$row
  $existingNames += $name.ToLower()
  $added++
  Write-Host "Queued: $name"
}

if ($added -eq 0) {
  Write-Host 'Nothing to append.'
  exit 0
}

$existing |
  Export-Excel -Path $excelPath -WorksheetName 'Group Stage Entries' -TableName 'Entries' -AutoSize -ClearSheet

Write-Host "Appended $added row(s) to $excelPath"
Write-Host 'Run .\scripts\sync-pool-from-excel.ps1 next, then commit and push.'
