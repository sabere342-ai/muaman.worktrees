# MUAMAN-13I deterministic Windows Release build.
# Runs `flutter build windows --release` for an app source root using the
# given isolated SDK / PUB_CACHE / TEMP / HOME. Captures a structured log.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File run_build.ps1 ^
#       -AppRoot <app-source-root> -SdkRoot <sdk-root> ^
#       -PubCache <pub-cache-root> -TmpRoot <tmp-root> -HomeRoot <home-root> ^
#       -LogFile <log-path>

param(
  [Parameter(Mandatory=$true)][string]$AppRoot,
  [Parameter(Mandatory=$true)][string]$SdkRoot,
  [Parameter(Mandatory=$true)][string]$PubCache,
  [Parameter(Mandatory=$true)][string]$TmpRoot,
  [Parameter(Mandatory=$true)][string]$HomeRoot,
  [Parameter(Mandatory=$true)][string]$LogFile
)
$ErrorActionPreference = 'Stop'

$env:PUB_CACHE = $PubCache
$env:TEMP = $TmpRoot
$env:TMP = $TmpRoot
$env:HOME = $HomeRoot
$env:USERPROFILE = $HomeRoot
$env:APPDATA = Join-Path $HomeRoot 'appdata\roaming'
$env:LOCALAPPDATA = Join-Path $HomeRoot 'appdata\local'
$env:NUGET_PACKAGES = Join-Path $HomeRoot 'appdata\local\NuGet\packages'
$env:CI = 'true'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:FLUTTER_ROOT = ''
$env:DART_HOME = ''
$env:FLUTTER_BIN = ''
$env:PATH = (Join-Path $SdkRoot 'bin') + ';' + $env:PATH

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$header = @(
  "=== MUAMAN-13I BUILD: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz') ==="
  "AppDir: $AppRoot"
  "SdkBin: $(Join-Path $SdkRoot 'bin')"
  "PUB_CACHE: $PubCache"
  "TEMP: $TmpRoot"
  "HOME: $HomeRoot"
  "USERPROFILE: $HomeRoot"
  "CI: $($env:CI) ; FLUTTER_SUPPRESS_ANALYTICS: $($env:FLUTTER_SUPPRESS_ANALYTICS)"
  "PATH[0]: $(($env:PATH -split ';')[0])"
  "==========================================="
)
$header | Out-File -LiteralPath $LogFile -Encoding UTF8

Push-Location $AppRoot
& (Join-Path $SdkRoot 'bin\flutter.bat') build windows --release 2>&1 | ForEach-Object {
  $_ | Tee-Object -FilePath $LogFile -Append
}
$code = $LASTEXITCODE
Pop-Location

$sw.Stop()
$footer = @(
  "==========================================="
  "BUILD EXIT CODE: $code"
  "BUILD DURATION (seconds): $([math]::Round($sw.Elapsed.TotalSeconds,1))"
  "COMPLETED: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
)
$footer | Out-File -LiteralPath $LogFile -Append -Encoding UTF8
exit $code
