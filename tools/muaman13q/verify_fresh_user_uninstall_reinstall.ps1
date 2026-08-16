# verify_fresh_user_uninstall_reinstall.ps1 - MUAMAN-13Q orchestrator.
# Runs as the DEVELOPER (current, non-elevated) user. Decrypts the DPAPI-protected
# password for the fresh account, stages the frozen installer into a location the
# fresh user can read, launches fresh_user_worker.ps1 AS the fresh standard user
# (CreateProcessWithLogonW), collects the worker evidence, computes the Q1..Q18
# guard gates, and copies evidence into the worktree.
#
# IMPORTANT: this file is ASCII-only.

[CmdletBinding()]
param(
    [string]$WorktreePath = 'C:\dev\muaman.worktrees\muaman-13q-independent-fresh-user-uninstall-reinstall-acceptance',
    [string]$MainRepoPath = 'C:\dev\muaman',
    [string]$AcceptanceRoot = 'C:\mu13o-acceptance\m13q',
    [string]$InstallerSource = 'C:\mu13o-acceptance\run1\consumer\inbound\muaman-windows-installer.exe',
    [string]$CredFile = 'C:\Users\saber\AppData\Local\Temp\opencode\m13q-cred.txt',
    [string]$AccountName = 'CodexMuaman13Q',
    [string]$Domain = $env:COMPUTERNAME,
    [string]$RunId = (Get-Date -Format 'yyyyMMdd-HHmmss'),
    [string]$ExpectedHead = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib\common.ps1')

$cfg = Read-JsonUtf8 -Path (Join-Path $PSScriptRoot 'acceptance-config.json')
$toolsDir = $PSScriptRoot
$runRoot = Join-Path $AcceptanceRoot "run\$RunId"
$stagedInstaller = Join-Path $runRoot 'installer\muaman-windows-installer.exe'
$refDir = Join-Path $runRoot 'ref'
$evidenceRoot = Join-Path $runRoot 'evidence'
$workRoot = Join-Path $runRoot 'work'
$m13qEvidenceDest = Join-Path $WorktreePath 'docs\muaman-13q\evidence'
$runEvidenceDest = Join-Path $m13qEvidenceDest $RunId
foreach ($d in @($runRoot, (Split-Path -Parent $stagedInstaller), $refDir, $evidenceRoot, $workRoot, $runEvidenceDest)) {
    New-Item -ItemType Directory -Path $d -Force | Out-Null
}

$record = [ordered]@{
    runId = $RunId
    startedAtUtc = Get-UtcString
    phase = 'MUAMAN-13Q'
    worktreePath = $WorktreePath
    mainRepoPath = $MainRepoPath
    accountName = $AccountName
    domain = $Domain
    installerSource = $InstallerSource
    acceptanceRoot = $AcceptanceRoot
}

function Fail {
    param([string]$Message)
    $record['failed'] = $true
    $record['failure'] = $Message
    $record['finishedAtUtc'] = Get-UtcString
    Write-JsonUtf8 -Path (Join-Path $runRoot '00-orchestration.json') -Object $record
    Write-Error "FAIL: $Message"
    exit 1
}

# The worker runs as the fresh standard user (Users group only), which has
# Read+Execute on dirs under the acceptance root. Grant the account Modify so it
# can write evidence/work inside the phase-scoped run root.
$accountPrincipal = "$Domain\$AccountName"
& icacls $runRoot /grant ("${accountPrincipal}:(OI)(CI)M") /Q | Out-Null
if ($LASTEXITCODE -ne 0) {
    Fail "could not grant '$accountPrincipal' access on '$runRoot'"
}

Write-JsonUtf8 -Path (Join-Path $runRoot '00-orchestration.json') -Object $record

# ------------------------------------------------------------- 1. git preflight
Write-Output '[1/9] git preflight'
$gitViolations = $null
$expectedHead = if ([string]::IsNullOrWhiteSpace($ExpectedHead)) { $cfg.baselineCommit } else { $ExpectedHead }
$gitOk = Test-GitCleanScope -RepoPath $WorktreePath -ExpectedHead $expectedHead -AllowedPrefixes $cfg.allowedChangedPrefixes -Violations ([ref]$gitViolations)
if (-not $gitOk) {
    Fail "worktree scope check failed:`n$($gitViolations -join "`n")"
}
$record['gitHead'] = $expectedHead
$record['gitClean'] = $true
Write-JsonUtf8 -Path (Join-Path $runRoot '00-orchestration.json') -Object $record

# ------------------------------------------------------------ 2. account checks
Write-Output '[2/9] fresh account checks'
$localUser = Get-LocalUser -Name $AccountName -ErrorAction SilentlyContinue
if (-not $localUser) { Fail "local account '$AccountName' does not exist. Run the elevated bootstrap first." }
if (-not $localUser.Enabled) { Fail "local account '$AccountName' is disabled" }
$membership = @(Get-AccountGroupMembership -AccountName $AccountName)
if ($membership -contains 'Administrators') { Fail "account '$AccountName' is in Administrators" }
$record['accountSid'] = $localUser.SID.Value
$record['accountGroups'] = $membership
Write-JsonUtf8 -Path (Join-Path $runRoot '00-orchestration.json') -Object $record

# A prior interrupted run may leave muaman_store or unins000 running (as any user),
# locking the install dir and making a re-run fail at install with access denied.
# Sweep only muaman-owned processes by path before the worker starts.
Write-Output '  sweep stale muaman/unins000 processes'
$sweptPids = @()
foreach ($p in @(Get-Process -Name 'muaman_store', 'unins000' -ErrorAction SilentlyContinue)) {
    $pPath = $null
    try { $pPath = (Get-CimInstance Win32_Process -Filter "ProcessId = $($p.Id)" -ErrorAction SilentlyContinue).ExecutablePath } catch {}
    if ($pPath -and $pPath -like '*muaman*') {
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
        $sweptPids += [ordered]@{ pid = $p.Id; path = $pPath }
    }
}
$record['sweptStaleProcesses'] = $sweptPids
Write-JsonUtf8 -Path (Join-Path $runRoot '00-orchestration.json') -Object $record

# --------------------------------------------------------------- 3. credential
Write-Output '[3/9] credential decryption'
if (-not (Test-Path -LiteralPath $CredFile)) { Fail "credential file not found: $CredFile" }
$accountPasswordPlain = Unprotect-CurrentUserText -InFile $CredFile
$accountPasswordSecure = ConvertTo-SecureString -String $accountPasswordPlain -AsPlainText -Force
$ownerPassword = ([System.Guid]::NewGuid().ToString('N') + 'x7K!') # ephemeral app-owner password, never written to disk/repo

# ----------------------------------------------------------- 4. installer stage
Write-Output '[4/9] stage frozen installer'
if (-not (Test-Path -LiteralPath $InstallerSource)) { Fail "installer source missing: $InstallerSource" }
$srcHash = Get-FileSha256 -Path $InstallerSource
$srcSize = (Get-Item -LiteralPath $InstallerSource).Length
if ($srcHash -ne $cfg.installer.sha256 -or $srcSize -ne $cfg.installer.sizeBytes) {
    Fail "installer source identity mismatch: sha=$srcHash size=$srcSize"
}
Copy-Item -LiteralPath $InstallerSource -Destination $stagedInstaller -Force
$stagedHash = Get-FileSha256 -Path $stagedInstaller
if ($stagedHash -ne $cfg.installer.sha256) { Fail "staged installer hash mismatch: $stagedHash" }

# reference files for the worker (manifest + 13N contract + ui strings + config)
Copy-Item -LiteralPath (Join-Path $MainRepoPath $cfg.referenceFiles.manifest13k) -Destination (Join-Path $refDir 'release-manifest.json') -Force
Copy-Item -LiteralPath (Join-Path $MainRepoPath $cfg.referenceFiles.contract13n) -Destination (Join-Path $refDir '03-muaman13n-release-contract.json') -Force
Copy-Item -LiteralPath (Join-Path $toolsDir 'ui_strings.json') -Destination (Join-Path $refDir 'ui_strings.json') -Force
Copy-Item -LiteralPath (Join-Path $toolsDir 'acceptance-config.json') -Destination (Join-Path $refDir 'acceptance-config.json') -Force

$record['installerSha256'] = $stagedHash
$record['installerSize'] = (Get-Item -LiteralPath $stagedInstaller).Length
Write-JsonUtf8 -Path (Join-Path $runRoot '00-orchestration.json') -Object $record

# --------------------------------------------------------- 5. launch the worker
Write-Output '[5/9] launch worker as fresh user'
$workerScript = Join-Path $toolsDir 'fresh_user_worker.ps1'
$workerCapture = Join-Path $runRoot 'worker-capture.txt'
$workerWrapper = Join-Path $runRoot 'worker-run.ps1'
# The wrapper runs AS the fresh user. LoadUserProfile does not forward caller
# process env vars, so owner credentials travel via a run-scoped secrets file that
# the wrapper reads, exports as M13Q_* env vars, then deletes. The child itself
# redirects all streams into worker-capture.txt (.NET pipe-redirect does not
# deliver data across the alternate-credential logon). The worker's `exit N`
# terminates this host.
$secretsFile = Join-Path $runRoot 'worker-secrets.json'
Write-JsonUtf8 -Path $secretsFile -Object ([ordered]@{
    ownerDisplayName = [string](Read-JsonUtf8 -Path (Join-Path $refDir 'ui_strings.json')).owner.displayName
    ownerUsername    = [string](Read-JsonUtf8 -Path (Join-Path $refDir 'ui_strings.json')).owner.username
    ownerPassword    = $ownerPassword
    restrictedPath   = "$env:SystemRoot\System32;$env:SystemRoot"
})

$wrapperContent = @"
param(
    [string]`$SecretsFile, [string]`$RunId, [string]`$ExpectedUserName,
    [string]`$InstallerPath, [string]`$WorkRoot, [string]`$EvidenceRoot,
    [string]`$UiStringsPath, [string]`$ConfigPath, [string]`$ReferenceDir
)
`$ErrorActionPreference = 'Stop'
`$secrets = Get-Content -LiteralPath `$SecretsFile -Raw -Encoding UTF8 | ConvertFrom-Json
`$env:M13Q_OWNER_DISPLAYNAME = `$secrets.ownerDisplayName
`$env:M13Q_OWNER_USERNAME    = `$secrets.ownerUsername
`$env:M13Q_OWNER_PASSWORD    = `$secrets.ownerPassword
`$env:M13Q_RESTRICTED_PATH   = `$secrets.restrictedPath
Remove-Item -LiteralPath `$SecretsFile -Force -ErrorAction SilentlyContinue
& '${workerScript}' -RunId `$RunId -ExpectedUserName `$ExpectedUserName -InstallerPath `$InstallerPath -WorkRoot `$WorkRoot -EvidenceRoot `$EvidenceRoot -UiStringsPath `$UiStringsPath -ConfigPath `$ConfigPath -ReferenceDir `$ReferenceDir *> '$workerCapture'
Write-Output '[wrapper] worker returned without terminating; treating as failure'
exit 1
"@
[System.IO.File]::WriteAllText($workerWrapper, $wrapperContent, (New-Object System.Text.UTF8Encoding $false))

$r = Start-ProcessAsUser `
    -FilePath 'powershell.exe' `
    -Arguments "-NoProfile -ExecutionPolicy Bypass -File `"$workerWrapper`" -SecretsFile `"$secretsFile`" -RunId `"$RunId`" -ExpectedUserName `"$AccountName`" -InstallerPath `"$stagedInstaller`" -WorkRoot `"$workRoot`" -EvidenceRoot `"$evidenceRoot`" -UiStringsPath `"$(Join-Path $refDir 'ui_strings.json')`" -ConfigPath `"$(Join-Path $refDir 'acceptance-config.json')`" -ReferenceDir `"$refDir`"" `
    -WorkingDir $workRoot `
    -Domain $Domain `
    -UserName $AccountName `
    -Password $accountPasswordSecure `
    -TimeoutMs 2400000

$record['workerExitCode'] = $r.exitCode
$record['workerTimedOut'] = $r.timedOut
$record['workerPid'] = $r.processId
Write-JsonUtf8 -Path (Join-Path $runRoot '00-orchestration.json') -Object $record

if ($r.timedOut) { Fail 'worker timed out' }

$donePath = Join-Path $evidenceRoot 'json\worker-done.json'
if (-not (Test-Path -LiteralPath $donePath)) { Fail 'worker produced no worker-done.json' }
$done = Read-JsonUtf8 -Path $donePath
$record['workerAllStepsPassed'] = $done.allStepsPassed
$record['workerFailedSteps'] = $done.failedSteps
Write-JsonUtf8 -Path (Join-Path $runRoot '00-orchestration.json') -Object $record

# The worker deletes the secrets file itself; this safety net guarantees it can
# never reach the evidence copy under the worktree.
Remove-Item -LiteralPath $secretsFile -Force -ErrorAction SilentlyContinue

# ------------------------------------------------------------ 6. guard gates
Write-Output '[6/9] compute Q1..Q18 gates'
& (Join-Path $toolsDir 'guard_tests_13q.ps1') `
    -EvidenceRoot $evidenceRoot `
    -WorktreePath $WorktreePath `
    -MainRepoPath $MainRepoPath `
    -ConfigPath (Join-Path $refDir 'acceptance-config.json') `
    -RefDir $refDir `
    -OutFile (Join-Path $runRoot 'guards-result.json') `
    -OwnerUsername ([string](Read-JsonUtf8 -Path (Join-Path $refDir 'ui_strings.json')).owner.username) `
    -OwnerDisplayName ([string](Read-JsonUtf8 -Path (Join-Path $refDir 'ui_strings.json')).owner.displayName) `
    -AccountSid $localUser.SID.Value `
    -InstallerPath $stagedInstaller
$guardExit = $LASTEXITCODE
$record['guardsExitCode'] = $guardExit
$record['gatesAllPass'] = ((Read-JsonUtf8 -Path (Join-Path $runRoot 'guards-result.json')).allPass -eq $true)
Write-JsonUtf8 -Path (Join-Path $runRoot '00-orchestration.json') -Object $record

# ------------------------------------------------- 7. copy evidence into worktree
Write-Output '[7/9] copy evidence into worktree'
# Copy only reviewable artifacts. The frozen installer binary, worker scratch
# dir, and reference copies stay OUT of the worktree (binary must remain
# untracked; refs are already in the repo).
$evidenceDestEvidence = Join-Path $runEvidenceDest 'evidence'
Copy-Item -LiteralPath $evidenceRoot -Destination $evidenceDestEvidence -Recurse -Force
foreach ($f in @('00-orchestration.json', 'guards-result.json', 'worker-capture.txt', 'worker-run.ps1')) {
    $src = Join-Path $runRoot $f
    if (Test-Path -LiteralPath $src) {
        Copy-Item -LiteralPath $src -Destination (Join-Path $runEvidenceDest $f) -Force
    }
}
$record['evidenceDest'] = $runEvidenceDest
Write-JsonUtf8 -Path (Join-Path $runRoot '00-orchestration.json') -Object $record

# -------------------------------------------------------------- 8. summary
Write-Output '[8/9] summary'
$record['finishedAtUtc'] = Get-UtcString
Write-JsonUtf8 -Path (Join-Path $runRoot '00-orchestration.json') -Object $record
$record | ConvertTo-Json -Depth 10

if ($done.allStepsPassed -ne $true) {
    Write-Output "WORKER REPORT: worker steps failed: $($done.failedSteps -join ', ')"
    exit 3
}
Write-Output 'WORKER REPORT: all worker steps passed.'

# Guards verdict is authoritative; guard_tests_13q.ps1 exits nonzero on failure.
if ($guardExit -ne 0) {
    Write-Output "GUARDS REPORT: Q1..Q18 gates failed (exit=$guardExit) - see guards-result.json"
    exit 4
}
Write-Output 'GUARDS REPORT: all Q1..Q18 gates passed.'
Write-Output '[9/9] complete'
