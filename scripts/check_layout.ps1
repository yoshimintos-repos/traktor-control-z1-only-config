<#
  Z1 MK2 Loop-Mod - Layout-Pruefung (liest nur, aendert nichts)
  Prueft in "Traktor Settings.tsi", welche Z1-MK2-Layouts im Controller Manager
  angelegt sind. Aktiv ist ein Eintrag nur, wenn ihm ein Geraet (In-Port) zugewiesen ist.
  Mehrere aktive Layouts stoeren sich gegenseitig (z. B. setzt ein altes Layout bei
  Shift + EQ-Taste zusaetzlich einen eigenen Loop). Eintraege mit Port "None" schaden nicht.
#>
param(
  [string]$SettingsFile = "",
  [switch]$NoPause
)
$ErrorActionPreference = 'Stop'
function Done($code) { if (-not $NoPause) { Write-Host ''; Read-Host 'Enter zum Beenden' | Out-Null }; exit $code }

if (-not $SettingsFile) {
  $docs = [Environment]::GetFolderPath('MyDocuments')
  $dirs = Get-ChildItem (Join-Path $docs 'Native Instruments') -Directory -Filter 'Traktor *' -ErrorAction SilentlyContinue |
          Where-Object { Test-Path (Join-Path $_.FullName 'Traktor Settings.tsi') } |
          Sort-Object { try { [version]($_.Name -replace '^Traktor\s+','') } catch { [version]'0.0' } } -Descending
  if (-not $dirs) { Write-Host 'Keine "Traktor Settings.tsi" gefunden.' -ForegroundColor Yellow; Done 0 }
  $SettingsFile = Join-Path $dirs[0].FullName 'Traktor Settings.tsi'
}
Write-Host "Pruefe: $SettingsFile" -ForegroundColor Cyan

$xml = [IO.File]::ReadAllText($SettingsFile)
$m = [regex]::Match($xml, 'Name="DeviceIO\.Config\.Controller" Type="3" Value="([^"]*)"')
if (-not $m.Success) { Write-Host 'Keine Controller-Einstellungen gefunden.' -ForegroundColor Yellow; Done 0 }
$b = [Convert]::FromBase64String($m.Groups[1].Value)

function U32([int]$o) { [int64](([int64]$b[$o] -shl 24) -bor ([int64]$b[$o+1] -shl 16) -bor ([int64]$b[$o+2] -shl 8) -bor [int64]$b[$o+3]) }
function Frames([int]$o, [int]$end) {
  $list = @()
  while ($o + 8 -le $end) {
    $id = [Text.Encoding]::ASCII.GetString($b, $o, 4)
    if ($id -notmatch '^[A-Z0-9]{4}$') { break }
    $size = U32 ($o + 4)
    if ($o + 8 + $size -gt $end) { break }
    $list += ,@($id, ($o + 8), ($o + 8 + $size))
    $o = $o + 8 + $size
  }
  return ,$list
}
function Str([int]$o) { $n = U32 $o; return @([Text.Encoding]::BigEndianUnicode.GetString($b, $o + 4, 2 * $n), ($o + 4 + 2 * $n)) }

$top  = (Frames 0 $b.Length)[0]
$devs = (Frames $top[1] $top[2]) | Where-Object { $_[0] -eq 'DEVS' } | Select-Object -First 1
$z1 = @()
foreach ($devi in (Frames ($devs[1] + 4) $devs[2])) {
  if ($devi[0] -ne 'DEVI') { continue }
  $s = Str $devi[1]
  if ($s[0] -ne 'Traktor.Kontrol Z1 MK2') { continue }
  $info = [ordered]@{ Rows = 0; OldLoop = $false; ShiftOverride = $null; Port = 'None' }
  $ddat = (Frames $s[1] $devi[2])[0]
  $ddpt = (Frames $ddat[1] $ddat[2]) | Where-Object { $_[0] -eq 'DDPT' } | Select-Object -First 1
  if ($ddpt) { $info.Port = (Str $ddpt[1])[0] }                         # In-Port ("None" = Eintrag inaktiv)
  $ddcb = (Frames $ddat[1] $ddat[2]) | Where-Object { $_[0] -eq 'DDCB' } | Select-Object -First 1
  if ($ddcb) {
    $cmas = (Frames $ddcb[1] $ddcb[2]) | Where-Object { $_[0] -eq 'CMAS' } | Select-Object -First 1
    if ($cmas) {
      foreach ($cmai in (Frames ($cmas[1] + 4) $cmas[2])) {
        $info.Rows++
        $cmd = U32 ($cmai[1] + 8)
        if ($cmd -in 202, 2192, 2196) { $info.OldLoop = $true }          # Loop Active On / Loop Set / Loop Size Selector
        if ($cmd -eq 2548) { $info.ShiftOverride = ((U32 ($cmai[2] - 4)) -eq 0) }  # Modifier #1: "Override factory map" an?
      }
    }
  }
  $z1 += ,$info
}

if ($z1.Count -eq 0) { Write-Host 'Kein Z1-MK2-Layout im Controller Manager angelegt (der Mod laeuft trotzdem; fuer Shift-Funktionen das Begleit-Layout importieren).' -ForegroundColor Yellow; Done 0 }
Write-Host ("Gefundene Z1-MK2-Eintraege im Controller Manager: {0}" -f $z1.Count)
$i = 0; $problem = $false
foreach ($d in $z1) {
  $i++
  if ($d.Port -eq 'None' -or $d.Port -eq '') { $hint = 'inaktiv (kein Geraet zugewiesen) - schadet nicht' }
  elseif ($d.Rows -eq 0)   { $hint = 'leer - schadet nicht, kann entfernt werden' }
  elseif ($d.OldLoop)      { $hint = 'ENTFERNEN: enthaelt alte Loop-Zeilen (stoeren die Loop-Taste / den Gain-Knopf des Mods)'; $problem = $true }
  elseif ($d.ShiftOverride){ $hint = 'Bei "Modifier #1" ist "Override factory map" an - der Mod erkennt Shift nicht'; $problem = $true }
  else                     { $hint = 'passt zum Mod' }
  $portText = if ($d.Port -eq 'None' -or $d.Port -eq '') { 'Port: None' } else { 'Port: Z1 MK2' }
  Write-Host ("  {0}. Traktor.Kontrol Z1 MK2 - {1} Zuweisungen - {2} - {3}" -f $i, $d.Rows, $portText, $hint)
}
$active = @($z1 | Where-Object { $_.Rows -gt 0 -and $_.Port -ne 'None' -and $_.Port -ne '' })
if ($active.Count -gt 1) {
  Write-Host ''
  Write-Host 'Achtung: Mehrere Z1-Layouts sind GLEICHZEITIG aktiv (alle mit Geraet). Behalte nur eines.' -ForegroundColor Yellow
  $problem = $true
}
if ($problem) {
  Write-Host 'So geht es: Traktor > Preferences > Controller Manager > bei "Device" den Eintrag waehlen > "Edit..." > "Remove".' -ForegroundColor Yellow
  Write-Host '(Die Reihenfolge oben entspricht der Reihenfolge der Z1-Eintraege in der Device-Liste. Traktor speichert Aenderungen beim Beenden.)'
} else {
  Write-Host 'Alles in Ordnung.' -ForegroundColor Green
}
Done 0
