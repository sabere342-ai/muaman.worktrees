# delivery_validation.ps1 - MUAMAN-13S delivery validation library.
# Pure, deterministic, fail-closed helpers modelling what an actual Windows
# recipient does with the delivered ZIP: verify -> extract -> exact-content check
# -> verify each extracted file -> content sanity (README) -> manifest cross-check.
#
# Every function returns an [ordered]@{ pass=bool; ... } and never throws for a
# "failed validation" case: any exception is converted to pass=$false with the
# error text (no exception==PASS). Only .NET BCL + Windows Explorer-equivalent
# unzip semantics are used (System.IO.Compression.ZipFile), so results are
# reproducible across runs and hosts.
#
# IMPORTANT: this file is ASCII-only.

#Requires -Version 5.1
Set-StrictMode -Version Latest

function Get-FileSha256Hex {
    <#
    .SYNOPSIS
      SHA-256 of a file as uppercase hex string via .NET (no Get-FileHash).
    #>
    param([Parameter(Mandatory = $true)][string]$Path)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $fs = [System.IO.File]::OpenRead($Path)
        try {
            $hash = $sha.ComputeHash($fs)
            return ([System.BitConverter]::ToString($hash)).Replace('-', '')
        } finally { $fs.Dispose() }
    } finally { $sha.Dispose() }
}

function Get-FileSizeBytes {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (New-Object System.IO.FileInfo($Path)).Length
}

function ConvertTo-NormalizedRel {
    <# relative path list -> sorted '\' separated lowercase-insensitive names #>
    param([string[]]$RelativePaths)
    $out = @()
    foreach ($p in $RelativePaths) {
        $out += $p.Replace('/', '\')
    }
    return @($out | Sort-Object -Unique)
}

function Test-DeliveryZipIdentity {
    <#
    .SYNOPSIS
      S1: recipient verifies the received ZIP against the expected SHA-256 and
      byte size (as the README/ SHA256SUMS would instruct).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ZipPath,
        [Parameter(Mandatory = $true)][string]$ExpectedSha256,
        [Parameter(Mandatory = $true)][long]$ExpectedSize
    )
    $res = [ordered]@{ name = 'Test-DeliveryZipIdentity'; pass = $false; zipPath = $ZipPath }
    try {
        if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
            $res['reason'] = "zip not found: $ZipPath"; return $res
        }
        $actualHash = Get-FileSha256Hex -Path $ZipPath
        $actualSize = Get-FileSizeBytes -Path $ZipPath
        $res['zipSha256'] = $actualHash
        $res['zipSize'] = $actualSize
        $res['expectedSha256'] = $ExpectedSha256
        $res['expectedSize'] = $ExpectedSize
        $res['shaMatch'] = ($actualHash -eq $ExpectedSha256)
        $res['sizeMatch'] = ($actualSize -eq $ExpectedSize)
        $res['pass'] = ($res['shaMatch'] -and $res['sizeMatch'])
        if (-not $res['pass']) { $res['reason'] = 'hash/size mismatch' }
    } catch {
        $res['reason'] = $_.Exception.Message
        $res['pass'] = $false
    }
    return $res
}

function Expand-DeliveryArchive {
    <#
    .SYNOPSIS
      S2/S3: extract the ZIP into $DestRoot producing $ExpectedExtractDirName.
      Uses System.IO.Compression (same engine as Windows "Extract All"). On
      failure the partially-created destination is removed (fail-closed).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ZipPath,
        [Parameter(Mandatory = $true)][string]$DestRoot,
        [Parameter(Mandatory = $true)][string]$ExpectedExtractDirName
    )
    $res = [ordered]@{ name = 'Expand-DeliveryArchive'; pass = $false; zipPath = $ZipPath; destRoot = $DestRoot }
    try {
        if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
            $res['reason'] = "zip not found: $ZipPath"; return $res
        }
        New-Item -ItemType Directory -Path $DestRoot -Force | Out-Null
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $DestRoot)
        $extractDir = Join-Path $DestRoot $ExpectedExtractDirName
        if (-not (Test-Path -LiteralPath $extractDir -PathType Container)) {
            $res['reason'] = "expected top-level directory '$ExpectedExtractDirName' not produced"
            return $res
        }
        $res['extractDir'] = $extractDir
        $res['pass'] = $true
    } catch {
        if (Test-Path -LiteralPath (Join-Path $DestRoot $ExpectedExtractDirName)) {
            Remove-Item -LiteralPath (Join-Path $DestRoot $ExpectedExtractDirName) -Recurse -Force -ErrorAction SilentlyContinue
        }
        $res['reason'] = $_.Exception.Message
        $res['pass'] = $false
    }
    return $res
}

function Get-ExtractionFileList {
    <# all files recursively under $ExtractRoot as '\' relative paths #>
    param([Parameter(Mandatory = $true)][string]$ExtractRoot)
    $rel = @()
    if (-not (Test-Path -LiteralPath $ExtractRoot -PathType Container)) { return @($rel) }
    foreach ($f in @(Get-ChildItem -LiteralPath $ExtractRoot -Recurse -File -Force -ErrorAction SilentlyContinue)) {
        $rel += $f.FullName.Substring($ExtractRoot.TrimEnd('\').Length + 1)
    }
    return @(ConvertTo-NormalizedRel -RelativePaths $rel)
}

function Test-ExactFileSet {
    <#
    .SYNOPSIS
      S4: the extracted delivery must contain EXACTLY the expected files and
      nothing else (recipient checks contents are the three documented files).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ExtractRoot,
        [Parameter(Mandatory = $true)][string[]]$ExpectedFiles
    )
    $res = [ordered]@{ name = 'Test-ExactFileSet'; pass = $false; extractRoot = $ExtractRoot }
    try {
        $actual = @(Get-ExtractionFileList -ExtractRoot $ExtractRoot)
        $expected = @(ConvertTo-NormalizedRel -RelativePaths $ExpectedFiles)
        $res['actualFiles'] = $actual
        $res['expectedFiles'] = $expected
        $res['actualCount'] = $actual.Count
        $res['expectedCount'] = $expected.Count
        $res['unexpected'] = @($actual | Where-Object { $_ -notin $expected })
        $res['missing'] = @($expected | Where-Object { $_ -notin $actual })
        $res['pass'] = ($res['unexpected'].Count -eq 0 -and $res['missing'].Count -eq 0)
        if (-not $res['pass']) { $res['reason'] = 'file set differs from expected delivery contents' }
    } catch {
        $res['reason'] = $_.Exception.Message
        $res['pass'] = $false
    }
    return $res
}

function Test-FileIdentity {
    <# identity (sha256+size) of a single extracted file #>
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ExpectedSha256,
        [Parameter(Mandatory = $true)][long]$ExpectedSize
    )
    $res = [ordered]@{ name = "Test-FileIdentity:$Name"; pass = $false; path = $Path }
    try {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            $res['reason'] = 'file not found'; return $res
        }
        $actualHash = Get-FileSha256Hex -Path $Path
        $actualSize = Get-FileSizeBytes -Path $Path
        $res['sha256'] = $actualHash
        $res['size'] = $actualSize
        $res['expectedSha256'] = $ExpectedSha256
        $res['expectedSize'] = $ExpectedSize
        $res['shaMatch'] = ($actualHash -eq $ExpectedSha256)
        $res['sizeMatch'] = ($actualSize -eq $ExpectedSize)
        $res['pass'] = ($res['shaMatch'] -and $res['sizeMatch'])
        if (-not $res['pass']) { $res['reason'] = 'sha256/size mismatch' }
    } catch {
        $res['reason'] = $_.Exception.Message
        $res['pass'] = $false
    }
    return $res
}

function Test-ReadmeContent {
    <#
    .SYNOPSIS
      S6: README content sanity. Must decode as UTF-8, must NOT contain any
      dev-repo/placeholder/secret sentinel, and must contain the product name and
      version. This is the "device-ready" check for what a recipient reads.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$ForbiddenSubstrings,
        [Parameter(Mandatory = $true)][string[]]$MustContain,
        [switch]$PassOnNonAscii = $true
    )
    $res = [ordered]@{ name = 'Test-ReadmeContent'; pass = $false; path = $Path }
    try {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            $res['reason'] = 'file not found'; return $res
        }
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        $res['bytes'] = $bytes.Length
        $text = [System.Text.UTF8Encoding]::new($false, $true).GetString($bytes)
        $res['decodedOk'] = $true
        $res['chars'] = $text.Length
        $hits = @()
        foreach ($s in $ForbiddenSubstrings) {
            if ($text.IndexOf($s, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) { $hits += $s }
        }
        $missing = @()
        foreach ($s in $MustContain) {
            if ($text.IndexOf($s, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) { $missing += $s }
        }
        $res['forbiddenHits'] = $hits
        $res['missingRequired'] = $missing
        $res['pass'] = ($hits.Count -eq 0 -and $missing.Count -eq 0)
        if (-not $res['pass']) { $res['reason'] = 'README content check failed' }
    } catch {
        $res['decodedOk'] = $false
        $res['reason'] = $_.Exception.Message
        $res['pass'] = $false
    }
    return $res
}

function Test-DeliveryManifest {
    <#
    .SYNOPSIS
      S7/S8: SHA256SUMS.txt must itself match its documented identity and every
      listed "HASH  FILE" entry must match the actual extracted file. This is the
      checksum-suite cross-check the recipient performs before running the
      installer.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ManifestPath,
        [Parameter(Mandatory = $true)][string]$ExtractRoot,
        [Parameter(Mandatory = $true)][string]$ExpectedManifestSha256,
        [Parameter(Mandatory = $true)][long]$ExpectedManifestSize
    )
    $res = [ordered]@{ name = 'Test-DeliveryManifest'; pass = $false; manifestPath = $ManifestPath }
    try {
        $id = Test-FileIdentity -Name 'SHA256SUMS' -Path $ManifestPath -ExpectedSha256 $ExpectedManifestSha256 -ExpectedSize $ExpectedManifestSize
        $res['manifestIdentity'] = $id
        if (-not $id.pass) { $res['reason'] = 'manifest file identity mismatch'; return $res }
        $text = [System.IO.File]::ReadAllText($ManifestPath)
        $entries = @()
        foreach ($line in @($text -split "`r?`n")) {
            $t = $line.Trim()
            if ($t -eq '') { continue }
            $parts = $t -split '\s+', 2
            if ($parts.Count -ne 2) { $entries += [ordered]@{ malformed = $true; raw = $t; pass = $false }; continue }
            $hash = $parts[0].Trim().ToUpperInvariant()
            $file = $parts[1].Trim()
            if ($file -match '^[*]') { $file = $file.Substring(1) }
            $abs = Join-Path $ExtractRoot ($file.Replace('/', '\'))
            $ok = $false
            $actualHash = $null
            if (Test-Path -LiteralPath $abs -PathType Leaf) {
                $actualHash = Get-FileSha256Hex -Path $abs
                $ok = ($actualHash -eq $hash)
            }
            $entries += [ordered]@{ file = $file; listedHash = $hash; actualHash = $actualHash; present = (Test-Path -LiteralPath $abs -PathType Leaf); pass = $ok }
        }
        $res['entryCount'] = $entries.Count
        $res['entries'] = $entries
        $res['allEntriesPass'] = (@($entries | Where-Object { $_.pass -ne $true }).Count -eq 0)
        $res['pass'] = $res['allEntriesPass']
        if (-not $res['pass']) { $res['reason'] = 'one or more manifest entries failed' }
    } catch {
        $res['reason'] = $_.Exception.Message
        $res['pass'] = $false
    }
    return $res
}

function Invoke-DeliveryPackageValidation {
    <#
    .SYNOPSIS
      Aggregate the recipient-side delivery checks against an already-extracted
      delivery directory. Fail-closed: returns pass=$false with 'failedStep' set
      to the first failing check.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ExtractRoot,
        [Parameter(Mandatory = $true)]$Identities,
        [string[]]$ReadmeForbidden,
        [string[]]$ReadmeMustContain
    )
    $res = [ordered]@{ name = 'Invoke-DeliveryPackageValidation'; pass = $false; extractRoot = $ExtractRoot; checks = [ordered]@{} }
    $checks = $res['checks']
    $checks['exactFileSet'] = Test-ExactFileSet -ExtractRoot $ExtractRoot -ExpectedFiles $Identities.consumer.expectedExtractFiles
    if (-not $checks['exactFileSet'].pass) { $res['failedStep'] = 'exactFileSet'; $res['reason'] = $checks['exactFileSet'].reason; return $res }
    foreach ($n in @('installer', 'readme', 'manifest')) {
        $c = $Identities.PSObject.Properties[$n].Value
        $p = Join-Path $ExtractRoot $c.filename
        $checks[$n] = Test-FileIdentity -Name $n -Path $p -ExpectedSha256 $c.sha256 -ExpectedSize $c.sizeBytes
        if (-not $checks[$n].pass) { $res['failedStep'] = $n; $res['reason'] = $checks[$n].reason; return $res }
    }
    $readmePath = Join-Path $ExtractRoot $Identities.readme.filename
    $checks['readmeContent'] = Test-ReadmeContent -Path $readmePath -ForbiddenSubstrings $ReadmeForbidden -MustContain $ReadmeMustContain
    if (-not $checks['readmeContent'].pass) { $res['failedStep'] = 'readmeContent'; $res['reason'] = $checks['readmeContent'].reason; return $res }
    $manifestPath = Join-Path $ExtractRoot $Identities.manifest.filename
    $checks['manifest'] = Test-DeliveryManifest -ManifestPath $manifestPath -ExtractRoot $ExtractRoot `
        -ExpectedManifestSha256 $Identities.manifest.sha256 -ExpectedManifestSize $Identities.manifest.sizeBytes
    if (-not $checks['manifest'].pass) { $res['failedStep'] = 'manifest'; $res['reason'] = $checks['manifest'].reason; return $res }
    $res['pass'] = $true
    return $res
}
