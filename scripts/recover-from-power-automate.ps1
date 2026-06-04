# Recover deleted Excel rows from Power Automate flow run history.
#
# Run in PowerShell from the repo root:
#   .\scripts\recover-from-power-automate.ps1
#
# Sign in when prompted, then check:
#   recovered-entries-report.txt  — audit of all runs vs current Excel
#   recovered-entries.json        — payloads missing from Excel (restore these)
#
# Then:
#   .\scripts\append-excel-entries.ps1 -InputPath .\recovered-entries.json
#   .\scripts\sync-pool-from-excel.ps1
#   git add src/data/pool-entries.js && git commit && git push

$ErrorActionPreference = 'Stop'

$environmentId = 'defaultce489f496a08487cbc9c7d75078824ea'
$flowId = 'b11215c7b719489eb98d80e420ecc2a9'

$excelPath = "$env:OneDriveCommercial\World Cup 2026 Pool\Group Stage Entries.xlsx"
if (-not (Test-Path $excelPath)) {
  $excelPath = "$env:OneDrive\World Cup 2026 Pool\Group Stage Entries.xlsx"
}
if (-not (Test-Path $excelPath)) {
  throw 'Excel file not found.'
}

Import-Module ImportExcel -ErrorAction Stop

function Get-FlowAccessToken {
  if (-not (Get-Module -ListAvailable Az.Accounts)) {
    throw 'Install Az.Accounts: Install-Module Az.Accounts -Scope CurrentUser'
  }
  Import-Module Az.Accounts -ErrorAction Stop
  if (-not (Get-AzContext)) {
    Write-Host 'Sign in to Azure (device code)...'
    Connect-AzAccount -UseDeviceAuthentication | Out-Null
  }
  $token = Get-AzAccessToken -ResourceUrl 'https://service.flow.microsoft.com/'
  return $token.Token
}

Write-Host 'Getting Power Automate access token...'
$flowToken = Get-FlowAccessToken
$headers = @{ Authorization = "Bearer $flowToken" }
$base = "https://api.flow.microsoft.com/providers/Microsoft.ProcessSimple/environments/$environmentId/flows/$flowId"

Write-Host 'Fetching flow runs (last 28 days)...'
$runs = @()
$uri = "$base/runs?api-version=2016-11-01"
do {
  $page = Invoke-RestMethod -Headers $headers -Uri $uri
  $runs += $page.value
  $uri = $page.nextLink
} while ($uri)

$currentNames = @(
  Import-Excel $excelPath -WorksheetName 'Group Stage Entries' |
    Where-Object { $_.PlayerName -and $_.PlayerName.Trim() } |
    ForEach-Object { $_.PlayerName.Trim().ToLower() }
)

$allSubmissions = @()
$missing = @()
$report = New-Object System.Collections.Generic.List[string]
$report.Add("Power Automate submission audit — $(Get-Date -Format o)")
$report.Add("Excel file: $excelPath")
$report.Add("Current Excel players ($($currentNames.Count)): $($currentNames -join ', ')")
$report.Add('')

foreach ($run in ($runs | Sort-Object { $_.properties.startTime })) {
  $detail = Invoke-RestMethod -Headers $headers -Uri "$base/runs/$($run.name)?api-version=2016-11-01"
  $body = $detail.properties.trigger.outputs.body
  if (-not $body) { continue }

  if ($body.action -eq 'list') {
    $report.Add("[blank/list request] $($run.properties.startTime)")
    continue
  }

  $name = [string]$body.playerName
  $name = $name.Trim()
  if (-not $name) {
    $report.Add("[blank row created] $($run.properties.startTime)")
    continue
  }

  $allSubmissions += $name
  $key = $name.ToLower()

  if ($currentNames -notcontains $key) {
    $missing += $body
    $report.Add("[MISSING — restore] $name <$($body.playerEmail)> at $($run.properties.startTime)")
  } else {
    $report.Add("[in Excel] $name at $($run.properties.startTime)")
  }
}

$repoRoot = Split-Path $PSScriptRoot -Parent
$reportPath = Join-Path $repoRoot 'recovered-entries-report.txt'
$jsonPath = Join-Path $repoRoot 'recovered-entries.json'

$uniqueMissing = $missing | Sort-Object { $_.playerName.ToLower() } -Unique

$report.Add('')
$report.Add("Valid submissions in flow history: $(@($allSubmissions | Sort-Object -Unique).Count)")
$report.Add("Missing from Excel (unique): $($uniqueMissing.Count)")
if ($uniqueMissing.Count -gt 0) {
  $report.Add('Missing names: ' + (($uniqueMissing | ForEach-Object { $_.playerName }) -join ', '))
}

$report | Set-Content -Path $reportPath -Encoding UTF8
$uniqueMissing | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

Write-Host ''
Write-Host "Report:  $reportPath"
Write-Host "Restore: $jsonPath ($($uniqueMissing.Count) entries)"
if ($uniqueMissing.Count -gt 0) {
  Write-Host ''
  Write-Host 'Next steps:'
  Write-Host '  .\scripts\append-excel-entries.ps1 -InputPath .\recovered-entries.json'
  Write-Host '  .\scripts\sync-pool-from-excel.ps1'
}
