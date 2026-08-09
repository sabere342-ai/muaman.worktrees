# guard_negative_controls.ps1 - MUAMAN-13S negative controls NC01..NC08.
# Proves the delivery-validation harness is fail-closed: for each injected defect
# the corresponding validation must FAIL, and a pristine extraction must PASS.
# Runs fully offline on disposable fixtures under a temp sandbox; never touches
# the live product, the official delivery, or any registry key.
#
# Exit 0 when every negative control behaves as expected, else 1.
#
# IMPORTANT: this file is ASCII-only.

#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$OfficialZipPath,
    [string]$FixtureRoot = 'C:\Users\saber\AppData\Local\Temp\opencode\m13s-negatives'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'delivery_validation.ps1')

$cfg = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'acceptance-config.json') -Raw -Encoding UTF8 | ConvertFrom-Json

if (Test-Path -LiteralPath $FixtureRoot) { Remove-Item -LiteralPath $FixtureRoot -Recurse -Force }
New-Item -ItemType Directory -Path $FixtureRoot -Force | Out-Null
$official = (Resolve-Path -LiteralPath $OfficialZipPath).Path

$results = [ordered]@{}
function Assert-Control {
    param([string]$Name, [bool]$Pass, [string]$Detail)
    $results[$Name] = [ordered]@{ pass = $Pass; detail = $Detail }
    Write-Output ("{0} = {1}  {2}" -f $Name, $(if ($Pass) { 'PASS' } else { 'FAIL' }), $Detail)
}

# Build a pristine extracted delivery (official ZIP -> fixture extract dir).
function New-PristineExtract {
    param([string]$Root)
    $dest = Join-Path $Root 'pristine'
    if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    $expand = Expand-DeliveryArchive -ZipPath $official -DestRoot $dest -ExpectedExtractDirName $cfg.consumer.extractDirName
    if (-not $expand.pass) { throw "could not build pristine extract: $($expand.reason)" }
    return $expand.extractDir
}

function New-DefectiveExtract {
    param([string]$Root, [string]$Name)
    $dest = Join-Path $Root $Name
    if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    $expand = Expand-DeliveryArchive -ZipPath $official -DestRoot $dest -ExpectedExtractDirName $cfg.consumer.extractDirName
    if (-not $expand.pass) { throw "could not build defective extract: $($expand.reason)" }
    return $expand.extractDir
}

function Flip-OneByte {
    param([string]$Path, [string]$OutPath)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 1) { throw 'file too small to flip' }
    $bytes[0] = $bytes[0] -bxor 0x01
    [System.IO.File]::WriteAllBytes($OutPath, $bytes)
}

# ---------------------------------------------------------------- NC00 control
try {
    $ctrlDir = New-PristineExtract -Root (Join-Path $FixtureRoot 'control')
    $val = Invoke-DeliveryPackageValidation -ExtractRoot $ctrlDir -Identities $cfg `
        -ReadmeForbidden $cfg.readmeChecks.forbiddenSubstrings -ReadmeMustContain $cfg.readmeChecks.mustContain
    $zipId = Test-DeliveryZipIdentity -ZipPath $official -ExpectedSha256 $cfg.delivery.zipSha256 -ExpectedSize $cfg.delivery.zipSizeBytes
    Assert-Control -Name 'NC00-pristine-passes' -Pass ($val.pass -and $zipId.pass) -Detail 'pristine official delivery passes all validation'
} catch {
    Assert-Control -Name 'NC00-pristine-passes' -Pass $false -Detail "fixture error: $($_.Exception.Message)"
}

# ---------------------------------------------------------------- NC01 ZIP tamper
try {
    $tamperedZip = Join-Path $FixtureRoot 'nc01-tampered.zip'
    Flip-OneByte -Path $official -OutPath $tamperedZip
    $r = Test-DeliveryZipIdentity -ZipPath $tamperedZip -ExpectedSha256 $cfg.delivery.zipSha256 -ExpectedSize $cfg.delivery.zipSizeBytes
    Assert-Control -Name 'NC01-zip-tamper-rejected' -Pass (-not $r.pass) -Detail "flipped-byte ZIP must fail identity (sha=$($r.zipSha256))"
} catch {
    Assert-Control -Name 'NC01-zip-tamper-rejected' -Pass $false -Detail "fixture error: $($_.Exception.Message)"
}

# ---------------------------------------------------------------- NC02 wrong expected hash
try {
    $r = Test-DeliveryZipIdentity -ZipPath $official -ExpectedSha256 ('0' * 64) -ExpectedSize $cfg.delivery.zipSizeBytes
    Assert-Control -Name 'NC02-wrong-expected-hash-rejected' -Pass (-not $r.pass) -Detail 'incorrect expected hash must fail identity'
} catch {
    Assert-Control -Name 'NC02-wrong-expected-hash-rejected' -Pass $false -Detail "fixture error: $($_.Exception.Message)"
}

# ---------------------------------------------------------------- NC03 missing installer
try {
    $d = New-DefectiveExtract -Root $FixtureRoot -Name 'nc03'
    Remove-Item -LiteralPath (Join-Path $d $cfg.installer.filename) -Force
    $es = Test-ExactFileSet -ExtractRoot $d -ExpectedFiles $cfg.consumer.expectedExtractFiles
    $val = Invoke-DeliveryPackageValidation -ExtractRoot $d -Identities $cfg `
        -ReadmeForbidden $cfg.readmeChecks.forbiddenSubstrings -ReadmeMustContain $cfg.readmeChecks.mustContain
    $ok = (-not $es.pass) -and (-not $val.pass) -and ($val.failedStep -eq 'exactFileSet' -or $val.failedStep -eq 'installer')
    Assert-Control -Name 'NC03-missing-installer-rejected' -Pass $ok -Detail "missing Muaman-Setup.exe rejected (exact=$(-not $es.pass), failedStep=$($val.failedStep))"
} catch {
    Assert-Control -Name 'NC03-missing-installer-rejected' -Pass $false -Detail "fixture error: $($_.Exception.Message)"
}

# ---------------------------------------------------------------- NC04 extra file
try {
    $d = New-DefectiveExtract -Root $FixtureRoot -Name 'nc04'
    [System.IO.File]::WriteAllText((Join-Path $d 'LICENSE.txt'), 'extra', (New-Object System.Text.UTF8Encoding $false))
    $es = Test-ExactFileSet -ExtractRoot $d -ExpectedFiles $cfg.consumer.expectedExtractFiles
    $val = Invoke-DeliveryPackageValidation -ExtractRoot $d -Identities $cfg `
        -ReadmeForbidden $cfg.readmeChecks.forbiddenSubstrings -ReadmeMustContain $cfg.readmeChecks.mustContain
    $ok = (-not $es.pass) -and (-not $val.pass)
    Assert-Control -Name 'NC04-extra-file-rejected' -Pass $ok -Detail "extra file rejected (exact=$(-not $es.pass), unexpected=$(@($es.unexpected).Count))"
} catch {
    Assert-Control -Name 'NC04-extra-file-rejected' -Pass $false -Detail "fixture error: $($_.Exception.Message)"
}

# ---------------------------------------------------------------- NC05 tampered installer
try {
    $d = New-DefectiveExtract -Root $FixtureRoot -Name 'nc05'
    $instPath = Join-Path $d $cfg.installer.filename
    $tampered = Join-Path $FixtureRoot 'nc05-tampered-installer.exe'
    Flip-OneByte -Path $instPath -OutPath $tampered
    Copy-Item -LiteralPath $tampered -Destination $instPath -Force
    $fi = Test-FileIdentity -Name 'installer' -Path $instPath -ExpectedSha256 $cfg.installer.sha256 -ExpectedSize $cfg.installer.sizeBytes
    $val = Invoke-DeliveryPackageValidation -ExtractRoot $d -Identities $cfg `
        -ReadmeForbidden $cfg.readmeChecks.forbiddenSubstrings -ReadmeMustContain $cfg.readmeChecks.mustContain
    $ok = (-not $fi.pass) -and (-not $val.pass) -and ($val.failedStep -eq 'installer')
    Assert-Control -Name 'NC05-tampered-installer-rejected' -Pass $ok -Detail "flipped-byte installer rejected (identity=$(-not $fi.pass), failedStep=$($val.failedStep))"
} catch {
    Assert-Control -Name 'NC05-tampered-installer-rejected' -Pass $false -Detail "fixture error: $($_.Exception.Message)"
}

# ---------------------------------------------------------------- NC06 wrong manifest
try {
    $d = New-DefectiveExtract -Root $FixtureRoot -Name 'nc06'
    $manifestPath = Join-Path $d $cfg.manifest.filename
    [System.IO.File]::WriteAllText($manifestPath, ('0' * 64) + '  Muaman-Setup.exe' + "`r`n", (New-Object System.Text.UTF8Encoding $false))
    $mi = Test-FileIdentity -Name 'manifest' -Path $manifestPath -ExpectedSha256 $cfg.manifest.sha256 -ExpectedSize $cfg.manifest.sizeBytes
    $val = Invoke-DeliveryPackageValidation -ExtractRoot $d -Identities $cfg `
        -ReadmeForbidden $cfg.readmeChecks.forbiddenSubstrings -ReadmeMustContain $cfg.readmeChecks.mustContain
    $ok = (-not $mi.pass) -and (-not $val.pass)
    Assert-Control -Name 'NC06-wrong-manifest-rejected' -Pass $ok -Detail "modified SHA256SUMS rejected (identity=$(-not $mi.pass), failedStep=$($val.failedStep))"
} catch {
    Assert-Control -Name 'NC06-wrong-manifest-rejected' -Pass $false -Detail "fixture error: $($_.Exception.Message)"
}

# ---------------------------------------------------------------- NC07 missing README
try {
    $d = New-DefectiveExtract -Root $FixtureRoot -Name 'nc07'
    Remove-Item -LiteralPath (Join-Path $d $cfg.readme.filename) -Force
    $es = Test-ExactFileSet -ExtractRoot $d -ExpectedFiles $cfg.consumer.expectedExtractFiles
    $val = Invoke-DeliveryPackageValidation -ExtractRoot $d -Identities $cfg `
        -ReadmeForbidden $cfg.readmeChecks.forbiddenSubstrings -ReadmeMustContain $cfg.readmeChecks.mustContain
    $ok = (-not $es.pass) -and (-not $val.pass)
    Assert-Control -Name 'NC07-missing-readme-rejected' -Pass $ok -Detail "missing README.txt rejected (exact=$(-not $es.pass), failedStep=$($val.failedStep))"
} catch {
    Assert-Control -Name 'NC07-missing-readme-rejected' -Pass $false -Detail "fixture error: $($_.Exception.Message)"
}

# ---------------------------------------------------------------- NC08 dev-path README
try {
    $d = New-DefectiveExtract -Root $FixtureRoot -Name 'nc08'
    $readmePath = Join-Path $d $cfg.readme.filename
    $orig = [System.IO.File]::ReadAllText($readmePath)
    [System.IO.File]::WriteAllText($readmePath, $orig + "`r`nSource: C:\dev\muaman.worktrees\something\\placeholder", (New-Object System.Text.UTF8Encoding $false))
    $rc = Test-ReadmeContent -Path $readmePath -ForbiddenSubstrings $cfg.readmeChecks.forbiddenSubstrings -MustContain $cfg.readmeChecks.mustContain
    $val = Invoke-DeliveryPackageValidation -ExtractRoot $d -Identities $cfg `
        -ReadmeForbidden $cfg.readmeChecks.forbiddenSubstrings -ReadmeMustContain $cfg.readmeChecks.mustContain
    $ok = (-not $rc.pass) -and (-not $val.pass)
    Assert-Control -Name 'NC08-dev-path-readme-rejected' -Pass $ok -Detail "README containing dev path rejected (content=$(-not $rc.pass), failedStep=$($val.failedStep))"
} catch {
    Assert-Control -Name 'NC08-dev-path-readme-rejected' -Pass $false -Detail "fixture error: $($_.Exception.Message)"
}

# ---------------------------------------------------------------- summary
$allPass = (@($results.Keys | Where-Object { $results[$_].pass -ne $true }).Count -eq 0)
$out = [ordered]@{
    allPass = $allPass
    fixtureRoot = $FixtureRoot
    controls = $results
    computedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
}
[System.IO.File]::WriteAllText((Join-Path $FixtureRoot 'negative-controls-result.json'), ($out | ConvertTo-Json -Depth 8), (New-Object System.Text.UTF8Encoding $false))

Write-Output ''
if ($allPass) {
    Write-Output 'NEGATIVE CONTROLS: all NC01..NC08 behaved as expected.'
    exit 0
} else {
    $failed = @($results.Keys | Where-Object { $results[$_].pass -ne $true })
    Write-Output "NEGATIVE CONTROLS: FAILED: $($failed -join ', ')"
    exit 1
}
