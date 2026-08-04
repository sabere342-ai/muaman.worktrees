# MUAMAN-13E: canonicalize the Dart plugin registrant URI.
#
# flutter_tools derives the URI it bakes into app.so for the generated Dart
# plugin registrant directly from the absolute path of the checkout
# (.dart_tool/flutter_build/dart_plugin_registrant.dart). That value is a
# const String in the compiled snapshot, so app.so from two checkouts at
# different absolute paths can never match.
#
# package_config's PackageConfig.toPackageUri maps a file to a package: URI
# when the file sits under some package's packageUriRoot. Nothing in the
# generated config covers .dart_tool, so this script injects a synthetic
# package whose root is exactly ../.dart_tool. toPackageUri then yields the
# deterministic package:_muaman_registrant/flutter_build/dart_plugin_registrant.dart
# for every checkout, and the frontend server resolves that package: URI back
# to the real file through the same config, so the baked string becomes
# path-independent while the runtime semantics are unchanged.
#
# The script is idempotent and runs as a CMake build step after every
# `flutter pub get`, which regenerates package_config.json without the entry.
param(
  [Parameter(Mandatory = $true)]
  [string]$ConfigPath
)

$ErrorActionPreference = 'Stop'

$regName = '_muaman_registrant'

if (-not (Test-Path -LiteralPath $ConfigPath)) {
  Write-Error "package_config.json not found: $ConfigPath"
  exit 1
}

$json = Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json

if (-not ($json.packages | Where-Object { $_.name -eq $regName })) {
  $entry = [pscustomobject]@{
    name            = $regName
    rootUri         = '../.dart_tool'
    packageUri      = '.'
    languageVersion = '3.0'
  }
  $json.packages = @($entry) + @($json.packages)
  $content = $json | ConvertTo-Json -Depth 100
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($ConfigPath, $content, $utf8NoBom)
  Write-Output "injected '$regName' into $ConfigPath"
} else {
  Write-Output "'$regName' already present in $ConfigPath"
}
