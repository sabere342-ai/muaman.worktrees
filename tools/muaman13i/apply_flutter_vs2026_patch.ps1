# MUAMAN-13I deterministic VS2026 Flutter SDK patch application.
# Applies the documented 3-line Visual Studio 2026 generator compatibility
# change to packages\flutter_tools\lib\src\windows\visual_studio.dart of a
# pristine official Flutter SDK root.
#
# The script validates the pristine preimage SHA-256 before modification and
# the patched postimage SHA-256 afterwards. It aborts (exit 1) when:
#   - the target file is absent
#   - the pristine hash differs from the expected value
#   - a required substitution anchor is missing (patch no longer applies)
#   - more files than the single approved source file would be modified
#   - the postimage hash differs from the expected value
#
# No fuzzy patching is performed. Byte-exact anchors are required.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File apply_flutter_vs2026_patch.ps1 ^
#       -SdkRoot <path-to-pristine-sdk-root> [-ApplyViaGit] [-LogFile <path>] [-DryRun]

param(
  [Parameter(Mandatory=$true)][string]$SdkRoot,
  [switch]$ApplyViaGit,
  [string]$LogFile = '',
  [switch]$DryRun
)
$ErrorActionPreference = 'Stop'

$relFile = 'packages\flutter_tools\lib\src\windows\visual_studio.dart'
$target = Join-Path $SdkRoot $relFile

$expectedPreimage  = '3C95601EE4B1B399904A92EE5AE32B876C8BF2E2BEB6D409461C9D73C988632D'
$expectedPostimage = 'D08E9D71E978FDE1478FBF438DCEA6D16D26EA966D271F7D5108AC86E3CC5423'

$log = New-Object System.Collections.Generic.List[string]
function Emit([string]$m) { $log.Add($m); Write-Output $m }

Emit "MUAMAN-13I FLUTTER VS2026 PATCH APPLICATION"
Emit "============================================"
Emit "Captured (UTC): $([DateTime]::UtcNow.ToString('yyyy-MM-dd HH:mm:ss'))"
Emit "SDK root: $([System.IO.Path]::GetFullPath($SdkRoot))"
Emit "Target relative path: $relFile"
Emit "Expected pristine (preimage) SHA-256: $expectedPreimage"
Emit "Expected patched (postimage) SHA-256: $expectedPostimage"

# 1. Abort if file absent.
if (-not (Test-Path -LiteralPath $target)) {
  Emit "ABORT: target file absent: $target"
  if ($LogFile) { Set-Content -LiteralPath $LogFile -Value $log -Encoding UTF8 }
  exit 1
}

$utf8 = New-Object System.Text.UTF8Encoding($false)

# 2. Pre-application status: per-file SHA-256 snapshot of the whole flutter_tools tree.
$toolRoot = Join-Path $SdkRoot 'packages\flutter_tools'
$preState = @{}
Get-ChildItem -LiteralPath $toolRoot -Recurse -File -Force | ForEach-Object {
  $preState[$_.FullName.Substring($SdkRoot.Length).TrimStart('\').Replace('\','/')] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
}

$preHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
Emit "Pre-application target SHA-256: $preHash"
if ($preHash -ne $expectedPreimage) {
  Emit "ABORT: preimage hash mismatch (expected $expectedPreimage)"
  if ($LogFile) { Set-Content -LiteralPath $LogFile -Value $log -Encoding UTF8 }
  exit 1
}
Emit "Preimage validation: PASS"

# 3. Read exact bytes; verify anchors; apply byte-exact substitutions.
$content = [System.IO.File]::ReadAllBytes($target)
$text = [System.Text.Encoding]::UTF8.GetString($content)

$anchor1 = "      17 => 'Visual Studio 17 2022',`r`n"
$insert1 = "      18 => 'Visual Studio 18 2026',`r`n"
$anchor2 = "      case 16:`r`n"
$insert2 = "      case 18:`r`n        cppToolchainDescription = 'MSVC v144 - VS 2026 C++ x64/x86 build tools';`r`n"

$i1 = $text.IndexOf($anchor1)
$i2 = $text.IndexOf($anchor2)
if ($i1 -lt 0 -or $i2 -lt 0) {
  Emit "ABORT: required anchor not found (cmakeGenerator anchor at $i1, requiredComponents anchor at $i2). Patch no longer applies cleanly."
  if ($LogFile) { Set-Content -LiteralPath $LogFile -Value $log -Encoding UTF8 }
  exit 1
}
if ($i1 -eq $i2 -or $i1 -lt 0) {
  Emit "ABORT: ambiguous anchors."
  if ($LogFile) { Set-Content -LiteralPath $LogFile -Value $log -Encoding UTF8 }
  exit 1
}
Emit "Anchors located: cmakeGenerator insert before offset $i1, requiredComponents insert before offset $i2."

$patched = $text.Substring(0, $i1) + $insert1 + $text.Substring($i1)
# Recompute second anchor offset in the patched text (first insert shifts nothing after offset $i1).
$i2p = $patched.IndexOf($anchor2)
if ($i2p -lt 0) {
  Emit "ABORT: second anchor not found after first substitution."
  if ($LogFile) { Set-Content -LiteralPath $LogFile -Value $log -Encoding UTF8 }
  exit 1
}
$patched = $patched.Substring(0, $i2p) + $insert2 + $patched.Substring($i2p)

# 4. Post-application validation.
if (-not $DryRun) {
  [System.IO.File]::WriteAllBytes($target, $utf8.GetBytes($patched))
}
$postHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
Emit "Post-application target SHA-256: $postHash"
if ($postHash -ne $expectedPostimage) {
  Emit "ABORT: postimage hash mismatch (expected $expectedPostimage)"
  if ($LogFile) { Set-Content -LiteralPath $LogFile -Value $log -Encoding UTF8 }
  exit 1
}
Emit "Postimage validation: PASS"

# 5. No-other-file-modified check: exactly the approved file may have a
#    different hash; every other file under flutter_tools must be byte-identical.
$postState = @{}
Get-ChildItem -LiteralPath $toolRoot -Recurse -File -Force | ForEach-Object {
  $postState[$_.FullName.Substring($SdkRoot.Length).TrimStart('\').Replace('\','/')] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
}
$relSlash = $relFile.Replace('\','/')
$changed = @()
$checked = @{}
foreach ($p in $preState.Keys) {
  $checked[$p] = $true
  if (-not $postState.ContainsKey($p)) { $changed += "REMOVED $p" }
  elseif ($postState[$p] -ne $preState[$p]) { $changed += "MODIFIED $p" }
}
foreach ($p in $postState.Keys) {
  if (-not $checked.ContainsKey($p)) { $changed += "ADDED $p" }
}
$changed = @($changed | Sort-Object -Unique)
if ($changed.Count -ne 1 -or $changed[0] -ne "MODIFIED $relSlash") {
  Emit "ABORT: more than the approved single file modified. Changed paths: $($changed -join ', ')"
  if ($LogFile) { Set-Content -LiteralPath $LogFile -Value $log -Encoding UTF8 }
  exit 1
}
Emit "No-other-file-modified check: PASS (only $relFile changed, $(@($preState.Keys).Count) files checked)"

# 6. Optional git apply proof against a temporary pristine copy.
if ($ApplyViaGit) {
  $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("muaman13i-gitapply-" + [Guid]::NewGuid().ToString('N'))
  $tmpDir = Join-Path $tmp 'packages\flutter_tools\lib\src\windows'
  New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
  $tmpPristine = Join-Path $tmpDir 'visual_studio.dart'
  # Place pristine content at the patch's expected relative path.
  $restored = $text  # captured before substitution
  [System.IO.File]::WriteAllBytes($tmpPristine, $utf8.GetBytes($restored))
  $patchFile = Join-Path $PSScriptRoot 'flutter-vs2026-generator.patch'
  if (Test-Path -LiteralPath $patchFile) {
    pushd $tmp
    git apply --check "$patchFile" 2>&1 | Out-String | ForEach-Object { Emit $_ }
    $checkCode = $LASTEXITCODE
    if ($checkCode -eq 0) {
      git apply "$patchFile" 2>&1 | Out-String | ForEach-Object { Emit $_ }
      $applyCode = $LASTEXITCODE
      $gitPost = (Get-FileHash -LiteralPath $tmpPristine -Algorithm SHA256).Hash
      Emit "git apply --check exit: $checkCode; git apply exit: $applyCode; applied file SHA-256: $gitPost"
      if ($applyCode -eq 0 -and $gitPost -eq $expectedPostimage) {
        Emit "git apply proof: PASS (patch applies cleanly and yields expected postimage)"
      } else {
        Emit "git apply proof: FAIL"
        popd
        if ($LogFile) { Set-Content -LiteralPath $LogFile -Value $log -Encoding UTF8 }
        exit 1
      }
    } else {
      Emit "git apply --check: FAIL (patch does not apply cleanly)"
      popd
      if ($LogFile) { Set-Content -LiteralPath $LogFile -Value $log -Encoding UTF8 }
      exit 1
    }
    popd
  } else {
    Emit "git apply proof: skipped (patch file not found at $patchFile)"
  }
  Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Emit "RESULT: PASS - patch applied deterministically to $relFile (3 semantic source-line substitutions)"
if ($LogFile) { Set-Content -LiteralPath $LogFile -Value $log -Encoding UTF8 }
exit 0
