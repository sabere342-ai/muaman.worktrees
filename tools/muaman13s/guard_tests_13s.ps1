# guard_tests_13s.ps1 - MUAMAN-13S guard gates S01..S18.
# Reads the fresh-user worker evidence plus repo-side facts and computes every
# gate. Exit 0 only when all gates PASS. Fail-closed: a missing evidence file,
# unreadable JSON or unexpected shape makes the affected gate FAIL.
#
# IMPORTANT: this file is ASCII-only.

#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$EvidenceRoot,
    [Parameter(Mandatory = $true)][string]$ConfigPath,
    [Parameter(Mandatory = $true)][string]$RepoZipPath,
    [Parameter(Mandatory = $true)][string]$OrchestrationRecord,
    [Parameter(Mandatory = $true)][string]$OutFile,
    [Parameter(Mandatory = $true)][string]$AccountSid,
    [Parameter(Mandatory = $true)][string]$SecretPattern,
    [Parameter(Mandatory = $true)][string]$ExpectedFinalHead
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib\common.ps1')

$cfg = Read-JsonUtf8 -Path $ConfigPath
$jsonDir = Join-Path $EvidenceRoot 'json'

function Read-Evidence {
    param([string]$Name)
    $p = Join-Path $jsonDir $Name
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) {
        throw "evidence file missing: $Name"
    }
    return Read-JsonUtf8 -Path $p
}

$gates = [ordered]@{}

function Add-Gate {
    param(
        [string]$Name,
        [bool]$Pass,
        [string]$Detail,
        $Expected,
        $Actual
    )
    $gates[$Name] = [ordered]@{
        gate = $Name
        pass = $Pass
        detail = $Detail
        expected = $Expected
        actual = $Actual
    }
    Write-Output ("{0} = {1}  {2}" -f $Name, $(if ($Pass) { 'PASS' } else { 'FAIL' }), $Detail)
}

$failures = @()

function Test-Pass {
    param([bool]$Pass, [string]$Gate, [string]$Detail)
    if (-not $Pass) { $script:failures += $Gate }
}

# ---------------------------------------------------------------------------
# S01  Independence
# ---------------------------------------------------------------------------
try {
    $id = Read-Evidence '03-identity.json'
    $meta = Read-Evidence '01-run-metadata.json'
    $cmdLine = [string]$meta.commandLine
    $repoSentinelHits = @($id.repoSentinelHits)
    $p = ($id.tokenNameMatchesExpected -eq $true) -and
         ($id.inAdministrators -eq $false) -and
         ($id.elevation.isInAdministrators -eq $false) -and
         ($repoSentinelHits.Count -eq 0) -and
         ([string]$id.restrictedPath).Length -gt 0 -and
         ([string]$AccountSid -eq [string]$id.localUserSid)
    Add-Gate -Name 'S01-independence' -Pass $p -Detail 'worker is the fresh standard user, not elevated, repo-path isolated, restricted PATH' `
        -Expected "user=$($cfg.accountName) admin=no repoHits=0 sid=$AccountSid" -Actual "user=$($id.tokenName) admin=$($id.inAdministrators) repoHits=$($repoSentinelHits.Count) sid=$($id.localUserSid) elevAdmins=$($id.elevation.isInAdministrators)"
    Test-Pass -Pass $p -Gate 'S01-independence' -Detail ''
} catch {
    Add-Gate -Name 'S01-independence' -Pass $false -Detail "evidence error: $($_.Exception.Message)" -Expected '' -Actual ''
    Test-Pass -Pass $false -Gate 'S01-independence' -Detail ''
}

# ---------------------------------------------------------------------------
# S02  Received delivery identity (consumer ZIP copy == official)
# ---------------------------------------------------------------------------
try {
    $rcv = Read-Evidence '02-receive.json'
    $dv = Read-Evidence '04-delivery-verify.json'
    $v = $dv.verify
    $p = ($dv.zipCopyExists -eq $true) -and ($v.pass -eq $true) -and ($v.shaMatch -eq $true) -and ($v.sizeMatch -eq $true) -and
         ($rcv.copyPreservedBytes -eq $true) -and ($rcv.receivedSha256 -eq $cfg.delivery.zipSha256)
    Add-Gate -Name 'S02-received-delivery' -Pass $p -Detail 'consumer ZIP copy sha256+size match official; byte-preserved receive' `
        -Expected "$($cfg.delivery.zipSha256) / $($cfg.delivery.zipSizeBytes)" -Actual "sha=$($v.zipSha256) size=$($v.zipSize) copyPreserved=$($rcv.copyPreservedBytes)"
    Test-Pass -Pass $p -Gate 'S02-received-delivery' -Detail ''
} catch {
    Add-Gate -Name 'S02-received-delivery' -Pass $false -Detail "evidence error: $($_.Exception.Message)" -Expected '' -Actual ''
    Test-Pass -Pass $false -Gate 'S02-received-delivery' -Detail ''
}

# ---------------------------------------------------------------------------
# S03  Recipient verification executed (recorded PASS)
# ---------------------------------------------------------------------------
try {
    $dv = Read-Evidence '04-delivery-verify.json'
    $p = ($dv.step -eq 'S1-verify-received-zip') -and ($dv.verify.pass -eq $true)
    Add-Gate -Name 'S03-verify-executed' -Pass $p -Detail 'recipient-side verify step recorded and passed' -Expected 'pass=true' -Actual "step=$($dv.step) pass=$($dv.verify.pass)"
    Test-Pass -Pass $p -Gate 'S03-verify-executed' -Detail ''
} catch {
    Add-Gate -Name 'S03-verify-executed' -Pass $false -Detail "evidence error: $($_.Exception.Message)" -Expected '' -Actual ''
    Test-Pass -Pass $false -Gate 'S03-verify-executed' -Detail ''
}

# ---------------------------------------------------------------------------
# S04  Extraction produced the correct top-level directory
# ---------------------------------------------------------------------------
try {
    $ev = Read-Evidence '05-extract-verify.json'
    $p = ($ev.expand.pass -eq $true) -and
         ((Split-Path -Leaf $ev.extractDir) -eq $cfg.consumer.extractDirName) -and
         ((Split-Path -Leaf $ev.expand.destRoot) -eq 'extracted')
    Add-Gate -Name 'S04-extract' -Pass $p -Detail 'archive extracted into consumer workspace, correct top-level dir' `
        -Expected $cfg.consumer.extractDirName -Actual (Split-Path -Leaf $ev.extractDir)
    Test-Pass -Pass $p -Gate 'S04-extract' -Detail ''
} catch {
    Add-Gate -Name 'S04-extract' -Pass $false -Detail "evidence error: $($_.Exception.Message)" -Expected '' -Actual ''
    Test-Pass -Pass $false -Gate 'S04-extract' -Detail ''
}

# ---------------------------------------------------------------------------
# S05  Exact three files, nothing more
# ---------------------------------------------------------------------------
try {
    $ev = Read-Evidence '05-extract-verify.json'
    $ef = $ev.exactFileSet
    $p = ($ef.pass -eq $true) -and ($ef.actualCount -eq 3) -and (@($ef.unexpected).Count -eq 0) -and (@($ef.missing).Count -eq 0)
    Add-Gate -Name 'S05-exact-three-files' -Pass $p -Detail 'extraction contains exactly the three documented delivery files' `
        -Expected ($cfg.consumer.expectedExtractFiles -join ', ') -Actual ($ef.actualFiles -join ', ')
    Test-Pass -Pass $p -Gate 'S05-exact-three-files' -Detail ''
} catch {
    Add-Gate -Name 'S05-exact-three-files' -Pass $false -Detail "evidence error: $($_.Exception.Message)" -Expected '' -Actual ''
    Test-Pass -Pass $false -Gate 'S05-exact-three-files' -Detail ''
}

# ---------------------------------------------------------------------------
# S06 / S07 / S08  Extracted file identities
# ---------------------------------------------------------------------------
try {
    $ev = Read-Evidence '05-extract-verify.json'
    $checks = $ev.packageValidation.checks

    $p6 = ($checks.installer.pass -eq $true)
    Add-Gate -Name 'S06-installer-identity' -Pass $p6 -Detail 'extracted Muaman-Setup.exe identity' `
        -Expected "$($cfg.installer.sha256) / $($cfg.installer.sizeBytes)" -Actual "sha=$($checks.installer.sha256) size=$($checks.installer.size)"
    Test-Pass -Pass $p6 -Gate 'S06-installer-identity' -Detail ''

    $p7 = ($checks.readme.pass -eq $true)
    Add-Gate -Name 'S07-readme-identity' -Pass $p7 -Detail 'extracted README.txt identity' `
        -Expected "$($cfg.readme.sha256) / $($cfg.readme.sizeBytes)" -Actual "sha=$($checks.readme.sha256) size=$($checks.readme.size)"
    Test-Pass -Pass $p7 -Gate 'S07-readme-identity' -Detail ''

    $p8 = ($checks.manifest.manifestIdentity.pass -eq $true)
    Add-Gate -Name 'S08-manifest-identity' -Pass $p8 -Detail 'extracted SHA256SUMS.txt identity' `
        -Expected "$($cfg.manifest.sha256) / $($cfg.manifest.sizeBytes)" -Actual "sha=$($checks.manifest.manifestIdentity.sha256) size=$($checks.manifest.manifestIdentity.size)"
    Test-Pass -Pass $p8 -Gate 'S08-manifest-identity' -Detail ''
} catch {
    Add-Gate -Name 'S06-installer-identity' -Pass $false -Detail "evidence error: $($_.Exception.Message)" -Expected '' -Actual ''
    Add-Gate -Name 'S07-readme-identity' -Pass $false -Detail "evidence error: $($_.Exception.Message)" -Expected '' -Actual ''
    Add-Gate -Name 'S08-manifest-identity' -Pass $false -Detail "evidence error: $($_.Exception.Message)" -Expected '' -Actual ''
    Test-Pass -Pass $false -Gate 'S06-installer-identity' -Detail ''
    Test-Pass -Pass $false -Gate 'S07-readme-identity' -Detail ''
    Test-Pass -Pass $false -Gate 'S08-manifest-identity' -Detail ''
}

# ---------------------------------------------------------------------------
# S09  README content readiness
# ---------------------------------------------------------------------------
try {
    $ev = Read-Evidence '05-extract-verify.json'
    $rc = $ev.packageValidation.checks.readmeContent
    $p = ($rc.pass -eq $true) -and (@($rc.forbiddenHits).Count -eq 0) -and (@($rc.missingRequired).Count -eq 0)
    Add-Gate -Name 'S09-readme-content' -Pass $p -Detail 'README decodes as UTF-8, no dev/placeholder/secret sentinels, contains product+version' `
        -Expected "forbidden=0 missing=0" -Actual "forbidden=$(@($rc.forbiddenHits).Count) missing=$(@($rc.missingRequired).Count) bytes=$($rc.bytes)"
    Test-Pass -Pass $p -Gate 'S09-readme-content' -Detail ''
} catch {
    Add-Gate -Name 'S09-readme-content' -Pass $false -Detail "evidence error: $($_.Exception.Message)" -Expected '' -Actual ''
    Test-Pass -Pass $false -Gate 'S09-readme-content' -Detail ''
}

# ---------------------------------------------------------------------------
# S10  Manifest cross-check
# ---------------------------------------------------------------------------
try {
    $ev = Read-Evidence '05-extract-verify.json'
    $m = $ev.packageValidation.checks.manifest
    $p = ($m.allEntriesPass -eq $true) -and ($m.entryCount -ge 1)
    Add-Gate -Name 'S10-manifest-crosscheck' -Pass $p -Detail 'SHA256SUMS entry matches actual extracted installer hash' `
        -Expected 'all entries match' -Actual "entries=$($m.entryCount) allPass=$($m.allEntriesPass)"
    Test-Pass -Pass $p -Gate 'S10-manifest-crosscheck' -Detail ''
} catch {
    Add-Gate -Name 'S10-manifest-crosscheck' -Pass $false -Detail "evidence error: $($_.Exception.Message)" -Expected '' -Actual ''
    Test-Pass -Pass $false -Gate 'S10-manifest-crosscheck' -Detail ''
}

# ---------------------------------------------------------------------------
# S11  Install executed from extracted delivery ONLY
# ---------------------------------------------------------------------------
try {
    $ins = Read-Evidence '07-install.json'
    $p = ($ins.step -eq 'S7-install-from-delivery') -and
         ($ins.exitCode -eq 0) -and ($ins.timedOut -eq $false) -and
         ($ins.appExeExists -eq $true) -and
         ($ins.installerWithinExtractedDelivery -eq $true) -and
         ($ins.installerSha256 -eq $cfg.installer.sha256)
    Add-Gate -Name 'S11-install-from-delivery' -Pass $p -Detail 'silent install from extracted delivery only; exit 0; installed' `
        -Expected "exit=0 timeout=no within-extract=yes sha=$($cfg.installer.sha256)" -Actual "exit=$($ins.exitCode) timeout=$($ins.timedOut) within=$($ins.installerWithinExtractedDelivery) sha=$($ins.installerSha256) exe=$($ins.appExeExists)"
    Test-Pass -Pass $p -Gate 'S11-install-from-delivery' -Detail ''
} catch {
    Add-Gate -Name 'S11-install-from-delivery' -Pass $false -Detail "evidence error: $($_.Exception.Message)" -Expected '' -Actual ''
    Test-Pass -Pass $false -Gate 'S11-install-from-delivery' -Detail ''
}

# ---------------------------------------------------------------------------
# S12  Installed payload intact + registration
# ---------------------------------------------------------------------------
try {
    $is = Read-Evidence '08-installed-state.json'
    $pl = $is.payload
    $p = ($is.hkcuUninstallPresent -eq $true) -and
         ($pl.payloadAllMatch -eq $true) -and
         (@($pl.unexpectedFiles).Count -eq 0) -and
         ($pl.exeSha256Match -eq $true) -and
         ($pl.flutterWindowsDllSha256 -eq $cfg.application.flutterWindowsDllSha256) -and
         ($pl.payloadFileCountInstalled -eq $cfg.application.payloadFileCount)
    Add-Gate -Name 'S12-installed-payload' -Pass $p -Detail '13-file payload matches manifest; exe + flutter dll hashes; registration present' `
        -Expected "payload=13 allMatch=yes unexpected=0 reg=yes" -Actual "payload=$($pl.payloadFileCountInstalled) allMatch=$($pl.payloadAllMatch) unexpected=$(@($pl.unexpectedFiles).Count) reg=$($is.hkcuUninstallPresent)"
    Test-Pass -Pass $p -Gate 'S12-installed-payload' -Detail ''
} catch {
    Add-Gate -Name 'S12-installed-payload' -Pass $false -Detail "evidence error: $($_.Exception.Message)" -Expected '' -Actual ''
    Test-Pass -Pass $false -Gate 'S12-installed-payload' -Detail ''
}

# ---------------------------------------------------------------------------
# S13  First launch healthy
# ---------------------------------------------------------------------------
try {
    $l1 = Read-Evidence '09-first-launch.json'
    $la = $l1.launch
    $p = ($la.windowFound -eq $true) -and ($la.processAliveAfter3s -eq $true) -and
         ($la.windowStillValidAfter3s -eq $true) -and ($la.mainModuleMatchesInstalledExe -eq $true)
    Add-Gate -Name 'S13-first-launch' -Pass $p -Detail 'main window appeared, process alive, module is installed exe' `
        -Expected 'window=yes alive=yes module=installed-exe' -Actual "window=$($la.windowFound) alive=$($la.processAliveAfter3s) module=$($la.mainModuleMatchesInstalledExe) sec=$($la.secondsToWindow)"
    Test-Pass -Pass $p -Gate 'S13-first-launch' -Detail ''
} catch {
    Add-Gate -Name 'S13-first-launch' -Pass $false -Detail "evidence error: $($_.Exception.Message)" -Expected '' -Actual ''
    Test-Pass -Pass $false -Gate 'S13-first-launch' -Detail ''
}

# ---------------------------------------------------------------------------
# S14  First-owner setup -> login -> dashboard
# ---------------------------------------------------------------------------
try {
    $l1 = Read-Evidence '09-first-launch.json'
    $p = ($l1.setupToLogin.setupTitleFound -eq $true) -and
         ($l1.setupToLogin.fieldsFound -eq $true) -and
         ($l1.setupToLogin.createButton.clicked -eq $true) -and
         ($l1.loginToDashboard.loginTitleFound -eq $true) -and
         ($l1.loginToDashboard.loginButtonFound -eq $true) -and
         ($l1.loginToDashboard.dashboardReached -eq $true)
    Add-Gate -Name 'S14-setup-login-dashboard' -Pass $p -Detail 'first-owner setup completed; login reached; dashboard reached' `
        -Expected 'setup=yes login=yes dashboard=yes' -Actual "setup=$($l1.setupToLogin.setupTitleFound) login=$($l1.loginToDashboard.loginTitleFound) dashboard=$($l1.loginToDashboard.dashboardReached)"
    Test-Pass -Pass $p -Gate 'S14-setup-login-dashboard' -Detail ''
} catch {
    Add-Gate -Name 'S14-setup-login-dashboard' -Pass $false -Detail "evidence error: $($_.Exception.Message)" -Expected '' -Actual ''
    Test-Pass -Pass $false -Gate 'S14-setup-login-dashboard' -Detail ''
}

# ---------------------------------------------------------------------------
# S15  Business database created
# ---------------------------------------------------------------------------
try {
    $l1 = Read-Evidence '09-first-launch.json'
    $db = $l1.databaseAfterSetup
    $p = ($db.dbExists -eq $true) -and ($db.sqliteHeaderValid -eq $true) -and
         (@($db.tablesFound) -contains 'users') -and ($db.ownerUsernameTextPresent -eq $true)
    Add-Gate -Name 'S15-business-db' -Pass $p -Detail 'SQLite DB created with users table and owner username' `
        -Expected 'exists=yes sqlite=yes users=yes owner=yes' -Actual "exists=$($db.dbExists) sqlite=$($db.sqliteHeaderValid) tables=$(@($db.tablesFound).Count) owner=$($db.ownerUsernameTextPresent)"
    Test-Pass -Pass $p -Gate 'S15-business-db' -Detail ''
} catch {
    Add-Gate -Name 'S15-business-db' -Pass $false -Detail "evidence error: $($_.Exception.Message)" -Expected '' -Actual ''
    Test-Pass -Pass $false -Gate 'S15-business-db' -Detail ''
}

# ---------------------------------------------------------------------------
# S16  Clean close
# ---------------------------------------------------------------------------
try {
    $c1 = Read-Evidence '10-close.json'
    $p = ($c1.close.exited -eq $true) -and (@($c1.orphanProcessIds).Count -eq 0) -and ($c1.dbStillPresentAfterClose -eq $true)
    Add-Gate -Name 'S16-clean-close' -Pass $p -Detail 'WM_CLOSE exited, no orphans, DB retained' `
        -Expected 'exited=yes orphans=0 db=yes' -Actual "exited=$($c1.close.exited) orphans=$(@($c1.orphanProcessIds).Count) db=$($c1.dbStillPresentAfterClose)"
    Test-Pass -Pass $p -Gate 'S16-clean-close' -Detail ''
} catch {
    Add-Gate -Name 'S16-clean-close' -Pass $false -Detail "evidence error: $($_.Exception.Message)" -Expected '' -Actual ''
    Test-Pass -Pass $false -Gate 'S16-clean-close' -Detail ''
}

# ---------------------------------------------------------------------------
# S17  Relaunch persists (no re-setup; login -> dashboard)
# ---------------------------------------------------------------------------
try {
    $l2 = Read-Evidence '11-relaunch.json'
    $r2 = $l2.relaunchToDashboard
    $p = ($l2.relaunch.windowFound -eq $true) -and ($l2.relaunch.processAliveAfter3s -eq $true) -and
         ($r2.setupNeverSeen -eq $true) -and ($r2.loginReached -eq $true) -and ($r2.dashboardReached -eq $true)
    Add-Gate -Name 'S17-relaunch-persists' -Pass $p -Detail 'relaunch shows login directly (no setup); login -> dashboard works' `
        -Expected 'setupNever=yes login=yes dashboard=yes' -Actual "setupNever=$($r2.setupNeverSeen) login=$($r2.loginReached) dashboard=$($r2.dashboardReached)"
    Test-Pass -Pass $p -Gate 'S17-relaunch-persists' -Detail ''
} catch {
    Add-Gate -Name 'S17-relaunch-persists' -Pass $false -Detail "evidence error: $($_.Exception.Message)" -Expected '' -Actual ''
    Test-Pass -Pass $false -Gate 'S17-relaunch-persists' -Detail ''
}

# ---------------------------------------------------------------------------
# S18  Final state consistent + no secrets in evidence
# ---------------------------------------------------------------------------
$secHits = @()
try {
    if (Test-Path -LiteralPath $EvidenceRoot) {
        foreach ($f in @(Get-ChildItem -LiteralPath $EvidenceRoot -Recurse -File -Force -ErrorAction SilentlyContinue)) {
            try {
                $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
                $text = [System.Text.Encoding]::GetEncoding(28591).GetString($bytes)
                if ($text.IndexOf($SecretPattern, [System.StringComparison]::Ordinal) -ge 0) {
                    $secHits += $f.FullName.Substring($EvidenceRoot.TrimEnd('\').Length + 1)
                }
            } catch {}
        }
    }
} catch {}
try {
    $fs = Read-Evidence '12-final-state.json'
    $done = Read-Evidence 'worker-done.json'
    $p = ($fs.close.exited -eq $true) -and (@($fs.orphanProcessIds).Count -eq 0) -and
         ($fs.dbStillPresentAfterFinalClose -eq $true) -and
         ($done.allStepsPassed -eq $true) -and (@($done.failedSteps).Count -eq 0) -and
         ($secHits.Count -eq 0)
    Add-Gate -Name 'S18-final-state' -Pass $p -Detail 'final close clean; DB persisted; all worker steps passed; no secrets in evidence' `
        -Expected 'close=yes orphans=0 db=yes allPassed=yes secrets=0' -Actual "close=$($fs.close.exited) orphans=$(@($fs.orphanProcessIds).Count) db=$($fs.dbStillPresentAfterFinalClose) allPassed=$($done.allStepsPassed) secrets=$($secHits.Count)"
    Test-Pass -Pass $p -Gate 'S18-final-state' -Detail ''
} catch {
    Add-Gate -Name 'S18-final-state' -Pass $false -Detail "evidence error: $($_.Exception.Message)" -Expected '' -Actual ''
    Test-Pass -Pass $false -Gate 'S18-final-state' -Detail ''
}

# ---------------------------------------------------------------------------
# Repository-side contract checks (informational gates that also gate the run):
#   repo ZIP identity, git HEAD, commit contract for the authoritative run.
# ---------------------------------------------------------------------------
try {
    $repoHash = Get-FileSha256 -Path $RepoZipPath
    $repoSize = (Get-Item -LiteralPath $RepoZipPath).Length
    $p = ($repoHash -eq $cfg.delivery.zipSha256) -and ($repoSize -eq $cfg.delivery.zipSizeBytes)
    Add-Gate -Name 'S19-repo-delivery-identity' -Pass $p -Detail 'repository delivery ZIP matches official identity' `
        -Expected "$($cfg.delivery.zipSha256) / $($cfg.delivery.zipSizeBytes)" -Actual "sha=$repoHash size=$repoSize"
    Test-Pass -Pass $p -Gate 'S19-repo-delivery-identity' -Detail ''
} catch {
    Add-Gate -Name 'S19-repo-delivery-identity' -Pass $false -Detail "repo zip check error: $($_.Exception.Message)" -Expected '' -Actual ''
    Test-Pass -Pass $false -Gate 'S19-repo-delivery-identity' -Detail ''
}

$gitCleanAtBaseline = $false
try {
    $rec = Read-JsonUtf8 -Path $OrchestrationRecord
    $gitCleanAtBaseline = ($rec.gitClean -eq $true)
    $headOk = ($rec.gitHead -eq $ExpectedFinalHead)
    $p = $gitCleanAtBaseline -and $headOk
    Add-Gate -Name 'S20-git-contract' -Pass $p -Detail 'worktree clean at expected HEAD with allowed scope only' `
        -Expected "clean=yes head=$ExpectedFinalHead" -Actual "clean=$gitCleanAtBaseline head=$($rec.gitHead)"
    Test-Pass -Pass $p -Gate 'S20-git-contract' -Detail ''
} catch {
    Add-Gate -Name 'S20-git-contract' -Pass $false -Detail "orchestration record error: $($_.Exception.Message)" -Expected '' -Actual ''
    Test-Pass -Pass $false -Gate 'S20-git-contract' -Detail ''
}

$allPass = ($failures.Count -eq 0)
$result = [ordered]@{
    allPass = $allPass
    failedGates = $failures
    gateCount = $gates.Count
    gates = $gates
    computedAtUtc = Get-UtcString
}
Write-JsonUtf8 -Path $OutFile -Object $result

Write-Output ''
if ($allPass) {
    Write-Output "GUARDS: all $($gates.Count) gates PASSED (S01..S20)."
    exit 0
} else {
    Write-Output "GUARDS: FAILED gates: $($failures -join ', ')"
    exit 1
}
