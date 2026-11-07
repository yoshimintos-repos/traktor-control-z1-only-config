<#
  Z1 MK2 Loop-Mod - Deinstallation: stellt die gesicherten Originaldateien wieder her.
#>
param(
  [string]$TraktorQml = "C:\Program Files\Native Instruments\Traktor Pro 4\Resources64\qml",
  [string]$BackupDir  = (Join-Path $env:ProgramData "Z1MK2-Loop-Mod\backup"),
  [switch]$NoElevate,
  [switch]$IgnoreRunningTraktor,   # nur fuer Tests
  [switch]$NoPause
)
$ErrorActionPreference = 'Stop'
$Marker  = '// MOD'
$Utf8    = New-Object System.Text.UTF8Encoding($false)
$Root    = Split-Path -Parent $PSScriptRoot
$Patches = Join-Path $Root 'patches\patches.json'

function Done($code) { if (-not $NoPause) { Write-Host ''; Read-Host 'Enter zum Beenden' | Out-Null }; exit $code }

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin -and -not $NoElevate) {
  $argList = @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"",'-TraktorQml',"`"$TraktorQml`"",'-BackupDir',"`"$BackupDir`"")
  Start-Process powershell -Verb RunAs -ArgumentList $argList | Out-Null
  exit 0
}

Write-Host 'Z1 MK2 Loop-Mod - Deinstallation' -ForegroundColor Cyan
while (-not $IgnoreRunningTraktor -and (Get-Process -Name 'Traktor Pro 4' -ErrorAction SilentlyContinue)) {
  Read-Host 'Traktor laeuft noch. Bitte Traktor beenden und Enter druecken' | Out-Null
}
$spec = Get-Content $Patches -Raw -Encoding UTF8 | ConvertFrom-Json
$files = @($spec.files.PSObject.Properties | ForEach-Object { $_.Name })
$restored = 0
foreach ($rel in $files) {
  $target = Join-Path $TraktorQml $rel
  $bak = Join-Path $BackupDir $rel
  if (-not (Test-Path $target)) { continue }
  $text = [IO.File]::ReadAllText($target, $Utf8)
  if (-not $text.Contains($Marker)) { continue }          # schon original
  if (-not (Test-Path $bak)) { Write-Host "Keine Sicherung fuer $rel gefunden. Traktor ueber Native Access reparieren." -ForegroundColor Red; Done 1 }
  [IO.File]::WriteAllText($target, [IO.File]::ReadAllText($bak, $Utf8), $Utf8)
  $restored++
}
if ($restored -eq 0) { Write-Host 'Es ist bereits das Original installiert. Nichts zu tun.' -ForegroundColor Green }
else { Write-Host "Fertig: $restored Dateien wiederhergestellt. Jetzt Traktor starten." -ForegroundColor Green }
Done 0
