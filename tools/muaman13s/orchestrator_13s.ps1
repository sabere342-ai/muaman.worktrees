# orchestrator_13s.ps1 - MUAMAN-13S controller.
# Runs as the DEVELOPER (current, non-elevated) user. Coordinates the full
# independent real-user delivery-to-launch acceptance:
#
#   [1] git preflight (clean worktree at expected HEAD, allowed scope only)
#   [2] fresh-account checks
#   [3] credential decryption (DPAPI)
#   [4] stage the official delivery ZIP into a neutral staging area
#   [5] launch consumer_worker.ps1 AS the fresh standard user
#       (CreateProcessWithLogonW + profile) - the worker performs S0..S12
#       entirely inside its own Downloads area and records evidence
#   [6] compute guard gates S01..S20 from worker evidence + repo facts
#   [7] run negative controls NC01..NC08 on disposable fixtures
#   [8] copy evidence into the worktree docs/muaman-13s/evidence/<RunId>
#   [9] summary
#
# The worker is given NO repository path. The config copy handed to it is
# self-contained (no repo path inside). Independence is proven by gate S01.
#
# IMPORTANT: this file is ASCII-only.

#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$WorktreePath = 'C:\dev\muaman.worktrees\muaman-13s-independent-real-user-delivery-to-launch-acceptance',
    [string]$MainRepoPath = 'C:\dev\muaman',
    [string]$AcceptanceRoot = 'C:\m13s-acceptance',
    [string]$CredFile = 'C:\Users\saber\AppData\Local\Temp\opencode\m13s-cred.txt',
    [string]$AccountName = 'CodexMuaman13S',
    [string]$Domain = $env:COMPUTERNAME,
    [string]$RunId = (Get-Date -Format 'yyyyMMdd-HHmmss'),
    [string]$ExpectedHead = 'fdf2d33762635dc89e5fb0cffd765649c402e078',
    [string]$ExpectedFinalHead = 'fdf2d33762635dc89e5fb0cffd765649c402e078',
    [switch]$SkipEvidenceCopy
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib\common.ps1')

$cfg = Read-JsonUtf8 -Path (Join-Path $PSScriptRoot 'acceptance-config.json')
$toolsDir = $PSScriptRoot
$runRoot = Join-Path $AcceptanceRoot "run\$RunId"
$stageDir = Join-Path $runRoot 'stage'
$refDir = Join-Path $runRoot 'ref'
$evidenceRoot = Join-Path $runRoot 'evidence'
$workRoot = Join-Path $runRoot 'work'
$stagedZip = Join-Path $stageDir $cfg.consumer.zipFilename
$repoZip = Join-Path $WorktreePath ('delivery\' + $cfg.consumer.zipFilename)
$m13sEvidenceDest = Join-Path $WorktreePath 'docs\muaman-13s\evidence'
$runEvidenceDest = Join-Path $m13sEvidenceDest $RunId
foreach ($d in @($runRoot, $stageDir, $refDir, $evidenceRoot, $workRoot, $runEvidenceDest)) {
    New-Item -ItemType Directory -Path $d -Force | Out-Null
}

$record = [ordered]@{
    runId = $RunId
    startedAtUtc = Get-UtcString
    phase = 'MUAMAN-13S'
    worktreePath = $WorktreePath
    mainRepoPath = $MainRepoPath
    accountName = $AccountName
    domain = $Domain
    acceptanceRoot = $AcceptanceRoot
    expectedHead = $ExpectedHead
    expectedFinalHead = $ExpectedFinalHead
    repoZip = $repoZip
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

$accountPrincipal = "$Domain\$AccountName"
& icacls $runRoot /grant ("${accountPrincipal}:(OI)(CI)M") /Q | Out-Null
if ($LASTEXITCODE -ne 0) {
    Fail "could not grant '$accountPrincipal' access on '$runRoot'"
}

Write-JsonUtf8 -Path (Join-Path $runRoot '00-orchestration.json') -Object $record

# ------------------------------------------------------------- 1. git preflight
Write-Output '[1/9] git preflight'
$gitViolations = $null
$gitOk = Test-GitCleanScope -RepoPath $WorktreePath -ExpectedHead $ExpectedHead -AllowedPrefixes $cfg.allowedChangedPrefixes -Violations ([ref]$gitViolations)
if (-not $gitOk) {
    Fail "worktree scope check failed:`n$($gitViolations -join "`n")"
}
$record['gitHead'] = $ExpectedHead
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

# A prior interrupted run may leave muaman_store or unins000 running (as any
# user), locking the install dir and making a re-run fail at install with access
# denied. Sweep only muaman-owned processes by path before the worker starts.
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

# ------------------------------------------------------------- 4. stage delivery
Write-Output '[4/9] stage official delivery ZIP'
if (-not (Test-Path -LiteralPath $repoZip)) { Fail "official delivery ZIP missing: $repoZip" }
$repoZipHash = Get-FileSha256 -Path $repoZip
$repoZipSize = (Get-Item -LiteralPath $repoZip).Length
if ($repoZipHash -ne $cfg.delivery.zipSha256 -or $repoZipSize -ne $cfg.delivery.zipSizeBytes) {
    Fail "official delivery ZIP identity mismatch: sha=$repoZipHash size=$repoZipSize"
}
Copy-Item -LiteralPath $repoZip -Destination $stagedZip -Force
$stagedHash = Get-FileSha256 -Path $stagedZip
if ($stagedHash -ne $cfg.delivery.zipSha256) { Fail "staged ZIP hash mismatch: $stagedHash" }

# reference copies for the worker (self-contained config + UI strings)
Copy-Item -LiteralPath (Join-Path $toolsDir 'acceptance-config.json') -Destination (Join-Path $refDir 'acceptance-config.json') -Force
Copy-Item -LiteralPath (Join-Path $toolsDir 'ui_strings.json') -Destination (Join-Path $refDir 'ui_strings.json') -Force

# Stage the worker itself into the neutral run root so the fresh user's process
# tree never references the repository path (independence, gate S01).
$workerDir = Join-Path $runRoot 'worker'
New-Item -ItemType Directory -Path (Join-Path $workerDir 'lib') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $toolsDir 'consumer_worker.ps1') -Destination (Join-Path $workerDir 'consumer_worker.ps1') -Force
Copy-Item -LiteralPath (Join-Path $toolsDir 'delivery_validation.ps1') -Destination (Join-Path $workerDir 'delivery_validation.ps1') -Force
Copy-Item -LiteralPath (Join-Path $toolsDir 'lib\common.ps1') -Destination (Join-Path $workerDir 'lib\common.ps1') -Force

$record['repoZipSha256'] = $stagedHash
$record['stagedZip'] = $stagedZip
Write-JsonUtf8 -Path (Join-Path $runRoot '00-orchestration.json') -Object $record

# --------------------------------------------------------- 5. launch the worker
Write-Output '[5/9] launch worker as fresh user'
$workerScript = Join-Path $workerDir 'consumer_worker.ps1'
$workerCapture = Join-Path $runRoot 'worker-capture.txt'
$workerWrapper = Join-Path $runRoot 'worker-run.ps1'
$secretsFile = Join-Path $runRoot 'worker-secrets.json'
Write-JsonUtf8 -Path $secretsFile -Object ([ordered]@{
    ownerDisplayName = [string](Read-JsonUtf8 -Path (Join-Path $refDir 'ui_strings.json')).owner.displayName
    ownerUsername    = [string](Read-JsonUtf8 -Path (Join-Path $refDir 'ui_strings.json')).owner.username
    ownerPassword    = $ownerPassword
    restrictedPath   = "$env:SystemRoot\System32;$env:SystemRoot"
})

$consumerWorkspace = "C:\Users\$AccountName\Downloads\Muaman-13S"

$wrapperContent = @"
param(
    [string]`$SecretsFile, [string]`$RunId, [string]`$ExpectedUserName,
    [string]`$ConsumerWorkspace, [string]`$StagedZip, [string]`$EvidenceRoot,
    [string]`$UiStringsPath, [string]`$ConfigPath
)
`$ErrorActionPreference = 'Stop'
`$secrets = Get-Content -LiteralPath `$SecretsFile -Raw -Encoding UTF8 | ConvertFrom-Json
`$env:M13S_OWNER_DISPLAYNAME = `$secrets.ownerDisplayName
`$env:M13S_OWNER_USERNAME    = `$secrets.ownerUsername
`$env:M13S_OWNER_PASSWORD    = `$secrets.ownerPassword
`$env:M13S_RESTRICTED_PATH   = `$secrets.restrictedPath
Remove-Item -LiteralPath `$SecretsFile -Force -ErrorAction SilentlyContinue
& '${workerScript}' -RunId `$RunId -ExpectedUserName `$ExpectedUserName -ConsumerWorkspace `$ConsumerWorkspace -StagedZip `$StagedZip -EvidenceRoot `$EvidenceRoot -UiStringsPath `$UiStringsPath -ConfigPath `$ConfigPath *> '$workerCapture'
`$donePath = Join-Path `$EvidenceRoot 'json\worker-done.json'
`$completed = `$false
if (Test-Path -LiteralPath `$donePath) {
    try {
        `$done = Get-Content -LiteralPath `$donePath -Raw -Encoding UTF8 | ConvertFrom-Json
        `$completed = (`$done.allStepsPassed -eq `$true)
    } catch {}
}
if (`$completed) { Write-Output '[wrapper] worker done: all steps passed'; exit 0 }
Write-Output '[wrapper] worker did not complete successfully'
exit 1
"@
[System.IO.File]::WriteAllText($workerWrapper, $wrapperContent, (New-Object System.Text.UTF8Encoding $false))

$r = Start-ProcessAsUser `
    -FilePath 'powershell.exe' `
    -Arguments "-NoProfile -ExecutionPolicy Bypass -File `"$workerWrapper`" -SecretsFile `"$secretsFile`" -RunId `"$RunId`" -ExpectedUserName `"$AccountName`" -ConsumerWorkspace `"$consumerWorkspace`" -StagedZip `"$stagedZip`" -EvidenceRoot `"$evidenceRoot`" -UiStringsPath `"$(Join-Path $refDir 'ui_strings.json')`" -ConfigPath `"$(Join-Path $refDir 'acceptance-config.json')`"" `
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
Write-Output '[6/9] compute S01..S20 gates'
& (Join-Path $toolsDir 'guard_tests_13s.ps1') `
    -EvidenceRoot $evidenceRoot `
    -ConfigPath (Join-Path $refDir 'acceptance-config.json') `
    -RepoZipPath $repoZip `
    -OrchestrationRecord (Join-Path $runRoot '00-orchestration.json') `
    -OutFile (Join-Path $runRoot 'guards-result.json') `
    -AccountSid $localUser.SID.Value `
    -SecretPattern 'x7K!' `
    -ExpectedFinalHead $ExpectedFinalHead
$guardExit = $LASTEXITCODE
$record['guardsExitCode'] = $guardExit
$record['gatesAllPass'] = ((Read-JsonUtf8 -Path (Join-Path $runRoot 'guards-result.json')).allPass -eq $true)
Write-JsonUtf8 -Path (Join-Path $runRoot '00-orchestration.json') -Object $record

# ---------------------------------------------------- 7. negative controls
Write-Output '[7/9] negative controls NC01..NC08'
$negFixtureRoot = Join-Path $AcceptanceRoot "negatives\$RunId"
$negOut = Join-Path $runRoot 'negative-controls-result.json'
& (Join-Path $toolsDir 'guard_negative_controls.ps1') `
    -OfficialZipPath $repoZip `
    -FixtureRoot $negFixtureRoot
$negExit = $LASTEXITCODE
if (Test-Path -LiteralPath (Join-Path $negFixtureRoot 'negative-controls-result.json')) {
    Copy-Item -LiteralPath (Join-Path $negFixtureRoot 'negative-controls-result.json') -Destination $negOut -Force
}
$record['negativeControlsExitCode'] = $negExit
$record['negativeControlsAllPass'] = ($negExit -eq 0)
Write-JsonUtf8 -Path (Join-Path $runRoot '00-orchestration.json') -Object $record

# ------------------------------------------------- 8. copy evidence into worktree
if ($SkipEvidenceCopy) {
    Write-Output '[8/9] evidence copy skipped (post-commit final-HEAD run; evidence stays external)'
    $record['evidenceDest'] = $null
} else {
    Write-Output '[8/9] copy evidence into worktree'
    $evidenceDestEvidence = Join-Path $runEvidenceDest 'evidence'
    Copy-Item -LiteralPath $evidenceRoot -Destination $evidenceDestEvidence -Recurse -Force
    foreach ($f in @('00-orchestration.json', 'guards-result.json', 'negative-controls-result.json', 'worker-capture.txt', 'worker-run.ps1')) {
        $src = Join-Path $runRoot $f
        if (Test-Path -LiteralPath $src) {
            Copy-Item -LiteralPath $src -Destination (Join-Path $runEvidenceDest $f) -Force
        }
    }
    $record['evidenceDest'] = $runEvidenceDest
}
Write-JsonUtf8 -Path (Join-Path $runRoot '00-orchestration.json') -Object $record

# -------------------------------------------------------------- 9. summary
Write-Output '[9/9] summary'
$record['finishedAtUtc'] = Get-UtcString
Write-JsonUtf8 -Path (Join-Path $runRoot '00-orchestration.json') -Object $record
$record | ConvertTo-Json -Depth 10

if ($done.allStepsPassed -ne $true) {
    Write-Output "WORKER REPORT: worker steps failed: $($done.failedSteps -join ', ')"
    exit 3
}
Write-Output 'WORKER REPORT: all worker steps passed.'

# Guards verdict is authoritative.
if ($guardExit -ne 0) {
    Write-Output "GUARDS REPORT: S01..S20 gates failed (exit=$guardExit) - see guards-result.json"
    exit 4
}
Write-Output 'GUARDS REPORT: all S01..S20 gates passed.'

if ($negExit -ne 0) {
    Write-Output "NEGATIVE CONTROLS REPORT: NC01..NC08 failed (exit=$negExit)"
    exit 5
}
Write-Output 'NEGATIVE CONTROLS REPORT: all NC01..NC08 behaved as expected.'
Write-Output '[9/9] complete'
exit 0
