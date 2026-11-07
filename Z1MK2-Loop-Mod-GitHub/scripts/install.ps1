<#
  Z1 MK2 Loop-Mod - Installer
  Wendet patches/patches.json auf die Z1-MK2-Dateien deiner Traktor-Installation an.
  Es werden KEINE Dateien von Native Instruments mitgeliefert: Der Installer nimmt
  deine eigenen Originaldateien, sichert sie und aendert sie an genau definierten Stellen.
#>
param(
  [string]$TraktorQml = "C:\Program Files\Native Instruments\Traktor Pro 4\Resources64\qml",
  [string]$BackupDir  = (Join-Path $env:ProgramData "Z1MK2-Loop-Mod\backup"),
  [switch]$NoElevate,
  [switch]$IgnoreRunningTraktor,   # nur fuer Tests
  [switch]$NoPause
)
$ErrorActionPreference = 'Stop'
$Marker   = '// MOD'
$Utf8     = New-Object System.Text.UTF8Encoding($false)
$Root     = Split-Path -Parent $PSScriptRoot
$Patches  = Join-Path $Root 'patches\patches.json'

function Done($code) { if (-not $NoPause) { Write-Host ''; Read-Host 'Enter zum Beenden' | Out-Null }; exit $code }

# --- Adminrechte (nur noetig, wenn Traktor unter "Program Files" liegt) ---------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin -and -not $NoElevate) {
  $argList = @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"",'-TraktorQml',"`"$TraktorQml`"",'-BackupDir',"`"$BackupDir`"")
  Start-Process powershell -Verb RunAs -ArgumentList $argList | Out-Null
  exit 0
}

Write-Host 'Z1 MK2 Loop-Mod - Installation' -ForegroundColor Cyan
if (-not (Test-Path $TraktorQml)) { Write-Host "Traktor-Ordner nicht gefunden: $TraktorQml" -ForegroundColor Red; Done 1 }

# --- Traktor muss beendet sein ---------------------------------------------------------
while (-not $IgnoreRunningTraktor -and (Get-Process -Name 'Traktor Pro 4' -ErrorAction SilentlyContinue)) {
  Read-Host 'Traktor laeuft noch. Bitte Traktor beenden und Enter druecken' | Out-Null
}

$spec = Get-Content $Patches -Raw -Encoding UTF8 | ConvertFrom-Json
$files = @($spec.files.PSObject.Properties | ForEach-Object { $_.Name })

function Read-Text($path) { [IO.File]::ReadAllText($path, $Utf8) }
function Count-Occ($text, $find) { ([regex]::Matches($text, [regex]::Escape($find))).Count }

# --- 1) Originale bestimmen (aus Traktor oder - wenn der Mod schon drin ist - aus der Sicherung)
$originals = @{}
foreach ($rel in $files) {
  $target = Join-Path $TraktorQml $rel
  if (-not (Test-Path $target)) { Write-Host "Datei fehlt: $target" -ForegroundColor Red; Done 1 }
  $text = Read-Text $target
  if ($text.Contains($Marker)) {
    $bak = Join-Path $BackupDir $rel
    if (-not (Test-Path $bak)) { Write-Host "Mod ist schon installiert, aber es gibt keine Sicherung von $rel. Bitte Traktor ueber Native Access reparieren und neu starten." -ForegroundColor Red; Done 1 }
    $text = Read-Text $bak
    if ($text.Contains($Marker)) { Write-Host "Sicherung von $rel ist selbst veraendert - Abbruch." -ForegroundColor Red; Done 1 }
  }
  $originals[$rel] = $text
}

# --- 2) Alle Aenderungen im Speicher anwenden; bei JEDER Abweichung wird nichts geschrieben
$results = @{}
$problems = @()
foreach ($rel in $files) {
  $orig = $originals[$rel]
  $crlf = $orig.Contains("`r`n")
  $t = $orig.Replace("`r`n", "`n")
  $i = 0
  foreach ($h in $spec.files.$rel) {
    $i++
    $n = Count-Occ $t $h.find
    if ($n -ne 1) { $problems += "$rel - Stelle $i wurde $n-mal gefunden (erwartet: 1)"; continue }
    $t = $t.Replace($h.find, $h.replace)
  }
  if ($crlf) { $t = $t.Replace("`n", "`r`n") }
  $results[$rel] = $t
}
if ($problems.Count -gt 0) {
  Write-Host 'ABBRUCH: Diese Traktor-Version passt nicht zu den Aenderungen. Es wurde nichts veraendert.' -ForegroundColor Red
  $problems | ForEach-Object { Write-Host "  $_" }
  Done 1
}

# --- 3) Originale sichern, Dateien schreiben, pruefen -------------------------------------
foreach ($rel in $files) {
  $bak = Join-Path $BackupDir $rel
  New-Item -ItemType Directory -Force -Path (Split-Path $bak) | Out-Null
  [IO.File]::WriteAllText($bak, $originals[$rel], $Utf8)
}
foreach ($rel in $files) { [IO.File]::WriteAllText((Join-Path $TraktorQml $rel), $results[$rel], $Utf8) }
foreach ($rel in $files) {
  if ((Read-Text (Join-Path $TraktorQml $rel)) -ne $results[$rel]) { Write-Host "FEHLER beim Schreiben von $rel - bitte Deinstallieren.bat ausfuehren." -ForegroundColor Red; Done 1 }
}
Write-Host ''
Write-Host "Fertig: $($files.Count) Dateien angepasst. Sicherung der Originale: $BackupDir" -ForegroundColor Green
Write-Host 'Jetzt Traktor starten.'
Done 0
