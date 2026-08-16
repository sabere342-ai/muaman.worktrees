# guard_tests_13q.ps1 - MUAMAN-13Q Q1..Q18 acceptance gates.
# Computes the mandatory acceptance gates from the recorded worker evidence plus
# live repo/toolchain state. Writes guards-result.json (UTF-8 no BOM) and exits
# 0 when allPass=true, otherwise 1.
#
# IMPORTANT: this file is ASCII-only.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$EvidenceRoot,
    [Parameter(Mandatory = $true)][string]$WorktreePath,
    [Parameter(Mandatory = $true)][string]$MainRepoPath,
    [Parameter(Mandatory = $true)][string]$ConfigPath,
    [Parameter(Mandatory = $true)][string]$RefDir,
    [Parameter(Mandatory = $true)][string]$OutFile,
    [Parameter(Mandatory = $true)][string]$OwnerUsername,
    [Parameter(Mandatory = $true)][string]$OwnerDisplayName,
    [Parameter(Mandatory = $true)][string]$AccountSid,
    [string]$InstallerPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib\common.ps1')

$cfg = Read-JsonUtf8 -Path $ConfigPath
$EvidenceRoot = [System.IO.Path]::GetFullPath($EvidenceRoot)
$jsonDir = Join-Path $EvidenceRoot 'json'
$shotsDir = Join-Path $EvidenceRoot 'shots'

function Read-Evidence {
    param([string]$Name)
    $p = Join-Path $jsonDir $Name
    if (-not (Test-Path -LiteralPath $p)) { throw "evidence missing: $Name" }
    return Read-JsonUtf8 -Path $p
}

$gates = [ordered]@{}
function Add-Gate {
    param([string]$Name, [bool]$Pass, [string]$Reason)
    $gates[$Name] = [ordered]@{ pass = $Pass; reason = $Reason }
}

# ---------------------------------------------------------------- Q1
try {
    $gitViolations = $null
    $scopeOk = Test-GitCleanScope -RepoPath $WorktreePath -ExpectedHead $cfg.baselineCommit -AllowedPrefixes $cfg.allowedChangedPrefixes -Violations ([ref]$gitViolations)
    $head = (& git -C $WorktreePath rev-parse HEAD 2>$null | Select-Object -First 1)
    $q1 = ($head -eq $cfg.baselineCommit) -and $scopeOk
    Add-Gate 'Q1' $q1 "baseline integrity: HEAD=$head expected=$($cfg.baselineCommit) scopeOk=$scopeOk violations=$($gitViolations -join ';')"
} catch { Add-Gate 'Q1' $false $_.Exception.Message }

# ---------------------------------------------------------------- Q2
try {
    $orchPath = Join-Path (Split-Path -Parent $EvidenceRoot) '00-orchestration.json'
    if (-not (Test-Path -LiteralPath $orchPath)) { $orchPath = Join-Path $EvidenceRoot '00-orchestration.json' }
    if (-not (Test-Path -LiteralPath $orchPath)) { throw '00-orchestration.json missing from run evidence' }
    $orch = Read-JsonUtf8 -Path $orchPath
    $instHash = [string]$orch.installerSha256
    $instSize = [int64]$orch.installerSize
    $q2 = ($instHash -eq $cfg.installer.sha256) -and ($instSize -eq [int64]$cfg.installer.sizeBytes)
    if ($q2 -and $InstallerPath -and (Test-Path -LiteralPath $InstallerPath)) {
        $q2 = ((Get-FileSha256 -Path $InstallerPath) -eq $cfg.installer.sha256) -and
              ((Get-Item -LiteralPath $InstallerPath).Length -eq $cfg.installer.sizeBytes)
    }
    Add-Gate 'Q2' $q2 "frozen installer identity sha=$instHash size=$instSize expected=$($cfg.installer.sha256)/$($cfg.installer.sizeBytes)"
} catch { Add-Gate 'Q2' $false $_.Exception.Message }

# ---------------------------------------------------------------- Q3
try {
    $id = Read-Evidence '04-user-identity.json'
    $q3 = ($id.tokenNameMatchesExpected -eq $true) -and
          ($id.tokenSid -eq $AccountSid) -and
          ($id.localUserExists -eq $true) -and
          ($id.localUserEnabled -eq $true) -and
          ($id.inAdministrators -eq $false) -and
          ($id.groupMembership -notcontains 'Administrators') -and
          ($id.integrity.level -like 'Medium*') -and
          ($id.elevation.isInAdministrators -eq $false) -and
          ($id.privilegeSummary.forbiddenEnabledPresent.Count -eq 0) -and
          ($id.localUserSid -eq $AccountSid)
    Add-Gate 'Q3' $q3 "fresh independent standard user (SID $($id.tokenSid), groups=$($id.groupMembership -join '+'), integrity=$($id.integrity.level), no admin privileges)"
} catch { Add-Gate 'Q3' $false $_.Exception.Message }

# ---------------------------------------------------------------- Q4
try {
    $pre = Read-Evidence '05-preinstall-state.json'
    $q4 = ($pre.install.installDirExistsBefore -eq $false) -and
          ($pre.install.appExeExistsBefore -eq $false) -and
          ($pre.install.uninstallRegistrationAbsent -eq $true) -and
          ($pre.install.hkcuMuamanUninstallKeys.Count -eq 0) -and
          ($pre.processes.appProcessIdsBefore.Count -eq 0) -and
          ($pre.processes.uninstallerProcessIdsBefore.Count -eq 0) -and
          ($pre.osAccountPicturePlaceholder.exists -eq $true)
    Add-Gate 'Q4' $q4 "clean pre-install state for fresh user: no install dir, no exe, no HKCU registration, no app/uninstaller processes; OS account-picture placeholder present (known false positive)"
} catch { Add-Gate 'Q4' $false $_.Exception.Message }

# ---------------------------------------------------------------- Q5
try {
    $inst = Read-Evidence '07-first-install-result.json'
    $q5 = ($inst.exitCode -eq 0) -and ($inst.timedOut -eq $false) -and ($inst.appExeExists -eq $true) -and
          ($inst.installerSha256 -eq $cfg.installer.sha256) -and ($inst.installerSize -eq $cfg.installer.sizeBytes)
    Add-Gate 'Q5' $q5 "first silent install exit=$($inst.exitCode) timedOut=$($inst.timedOut) appExeExists=$($inst.appExeExists) installerShaMatches=$($inst.installerSha256 -eq $cfg.installer.sha256)"
} catch { Add-Gate 'Q5' $false $_.Exception.Message }

# ---------------------------------------------------------------- Q6
try {
    $st = Read-Evidence '08-installed-state.json'
    $payload = $st.payload
    $q6 = ($st.hkcuUninstallPresent -eq $true) -and
          ($st.hkcuMuamanUninstallKeys.Count -eq 1) -and
          ($payload.payloadAllMatch -eq $true) -and
          ($payload.unexpectedFiles.Count -eq 0) -and
          ($payload.exeSizeMatch -eq $true) -and ($payload.exeSha256Match -eq $true) -and
          ($payload.flutterWindowsDllSha256 -eq $cfg.application.flutterWindowsDllSha256) -and
          ($st.startMenuLinkExists -eq $true) -and
          ($st.machineStartMenuLinkExists -eq $false) -and
          ($st.startMenuShortcutTarget -eq (Join-Path $payload.installDir $cfg.application.mainExecutable)) -and
          ($st.hklmUninstallHits.Count -eq 0)
    Add-Gate 'Q6' $q6 "installed-state integrity: registration=$($st.hkcuUninstallPresent) keys=$($st.hkcuMuamanUninstallKeys.Count) payloadAllMatch=$($payload.payloadAllMatch) unexpected=$($payload.unexpectedFiles.Count) startMenu=$($st.startMenuLinkExists)/machine=$($st.machineStartMenuLinkExists) hklmHits=$($st.hklmUninstallHits.Count)"
} catch { Add-Gate 'Q6' $false $_.Exception.Message }

# ---------------------------------------------------------------- Q7
try {
    $l1 = Read-Evidence '09-first-launch-result.json'
    $close1 = Read-Evidence '09-first-launch-close.json'
    $shotSetup = $l1.setupToDashboard.setupScreenshot
    $shotDash = $l1.loginToDashboard.dashboardScreenshot
    $shotOk = ($shotSetup -and (Test-Path -LiteralPath $shotSetup)) -and ($shotDash -and (Test-Path -LiteralPath $shotDash))
    $db = $l1.databaseAfterSetup
    $q7 = ($l1.launch.windowFound -eq $true) -and
          ($l1.launch.window.title -ne $null -and $l1.launch.window.title -ne '') -and
          ($l1.launch.processAliveAfter3s -eq $true) -and
          ($l1.launch.mainModuleMatchesInstalledExe -eq $true) -and
          ($l1.launch.windowStillValidAfter3s -eq $true) -and
          ($l1.setupToDashboard.setupTitleFound -eq $true) -and
          ($l1.setupToDashboard.fieldsFound -eq $true) -and
          ($l1.setupToDashboard.createButton.clicked -eq $true) -and
          ($l1.loginToDashboard.loginTitleFound -eq $true) -and
          ($l1.loginToDashboard.loginButtonFound -eq $true) -and
          ($l1.loginToDashboard.loginButton.clicked -eq $true) -and
          ($l1.loginToDashboard.dashboardReached -eq $true) -and
          ($db.dbExists -eq $true) -and ($db.sqliteHeaderValid -eq $true) -and
          ($db.tablesFound -contains 'users') -and ($db.ownerUsernameTextPresent -eq $true) -and
          $shotOk -and
          ($close1.close.exited -eq $true) -and ($close1.dbStillPresentAfterClose -eq $true) -and
          ($close1.orphanProcessIds.Count -eq 0)
    Add-Gate 'Q7' $q7 "first launch: setup->login->dashboard, DB created with owner, clean close, screenshots=$shotOk"
} catch { Add-Gate 'Q7' $false $_.Exception.Message }

# ---------------------------------------------------------------- Q8
try {
    $ud = Read-Evidence '11-uninstall-registration.json'
    $q8 = ($ud.uninstallString -ne $null -and $ud.uninstallString -ne '') -and
          ($ud.uninstallerPath -ne $null -and $ud.uninstallerPath -ne '') -and
          ($ud.uninstallerExists -eq $true) -and
          ($ud.uninstallerMatchesExpected -eq $true)
    Add-Gate 'Q8' $q8 "official uninstaller discovery: path=$($ud.uninstallerPath) exists=$($ud.uninstallerExists) matchesExpected=$($ud.uninstallerMatchesExpected)"
} catch { Add-Gate 'Q8' $false $_.Exception.Message }

# ---------------------------------------------------------------- Q9
try {
    $ur = Read-Evidence '12-uninstall-result.json'
    $q9 = ($ur.exitCode -eq 0) -and ($ur.timedOut -eq $false) -and
          ($ur.registrationRemoved.ok -eq $true) -and
          ($ur.installedExeRemoved.ok -eq $true) -and
          ($ur.uninstallerRemoved.ok -eq $true) -and
          ($ur.processesGone.ok -eq $true)
    Add-Gate 'Q9' $q9 "official uninstall via registered UninstallString exit=$($ur.exitCode) registrationRemoved=$($ur.registrationRemoved.ok) exeRemoved=$($ur.installedExeRemoved.ok) uninstallerRemoved=$($ur.uninstallerRemoved.ok) processesGone=$($ur.processesGone.ok)"
} catch { Add-Gate 'Q9' $false $_.Exception.Message }

# ---------------------------------------------------------------- Q10
try {
    $post = Read-Evidence '13-postuninstall-state.json'
    $q10 = ($post.registrationRemoved -eq $true) -and
           ($post.hkcuMuamanUninstallKeys.Count -eq 0) -and
           ($post.appProcessIds.Count -eq 0) -and
           ($post.uninstallerProcessIds.Count -eq 0)
    Add-Gate 'Q10' $q10 "post-uninstall registration removed (HKCU keys=$($post.hkcuMuamanUninstallKeys.Count)), no app/uninstaller processes"
} catch { Add-Gate 'Q10' $false $_.Exception.Message }

# ---------------------------------------------------------------- Q11
try {
    $post = Read-Evidence '13-postuninstall-state.json'
    $q11 = ($post.appExeExists -eq $false) -and
           ($post.payloadFilesStillPresent.Count -eq 0) -and
           ($post.uninsExtrasStillPresent.Count -eq 0) -and
           ($post.startMenuLinkExists -eq $false)
    Add-Gate 'Q11' $q11 "installer-owned files removed: exeGone=$(-not $post.appExeExists) payloadStill=$($post.payloadFilesStillPresent.Count) uninsExtrasStill=$($post.uninsExtrasStillPresent.Count) startMenuStill=$($post.startMenuLinkExists)"
} catch { Add-Gate 'Q11' $false $_.Exception.Message }

# ---------------------------------------------------------------- Q12
try {
    $lc = Read-Evidence '14-leftover-classification.json'
    $retainedOk = @($lc.expectedRetainedUserData | Where-Object { $_.classification -eq 'expected-retained-user-data' }).Count -ge 1
    $q12 = ($lc.classificationComplete -eq $true) -and
           ($lc.unknownInstallerLeftovers.Count -eq 0) -and
           $retainedOk -and
           ($lc.osAccountPicturePlaceholder.classifiedAs -eq 'os-account-picture-placeholder') -and
           ($lc.hklmMuamanHits.Count -eq 0) -and
           ($lc.programDataMuamanHitsExcludingAccountPictures.Count -eq 0)
    Add-Gate 'Q12' $q12 "leftover classification clean: unknown=$($lc.unknownInstallerLeftovers.Count) retained=$(@($lc.expectedRetainedUserData).Count) accountPicture=$($lc.osAccountPicturePlaceholder.classifiedAs) hklmHits=$($lc.hklmMuamanHits.Count) programDataHits=$($lc.programDataMuamanHitsExcludingAccountPictures.Count)"
} catch { Add-Gate 'Q12' $false $_.Exception.Message }

# ---------------------------------------------------------------- Q13
try {
    $ri = Read-Evidence '15-reinstall-result.json'
    $q13 = ($ri.exitCode -eq 0) -and ($ri.timedOut -eq $false) -and ($ri.appExeExists -eq $true) -and
           ($ri.installerSha256 -eq $cfg.installer.sha256) -and ($ri.installerSize -eq $cfg.installer.sizeBytes)
    Add-Gate 'Q13' $q13 "reinstall of same bytes exit=$($ri.exitCode) timedOut=$($ri.timedOut) appExeExists=$($ri.appExeExists) installerShaMatches=$($ri.installerSha256 -eq $cfg.installer.sha256)"
} catch { Add-Gate 'Q13' $false $_.Exception.Message }

# ---------------------------------------------------------------- Q14
try {
    $rst = Read-Evidence '16-reinstalled-state.json'
    $payload = $rst.payload
    $q14 = ($rst.hkcuUninstallPresent -eq $true) -and
           ($rst.hkcuMuamanUninstallKeys.Count -eq 1) -and
           ($rst.duplicateUninstallRegistrations.Count -eq 0) -and
           ($rst.duplicateInstallRoots.Count -eq 0) -and
           ($payload.payloadAllMatch -eq $true) -and
           ($payload.unexpectedFiles.Count -eq 0) -and
           ($rst.dbRetainedAfterReinstall -eq $true)
    Add-Gate 'Q14' $q14 "reinstalled-state integrity: registration=$($rst.hkcuUninstallPresent) keys=$($rst.hkcuMuamanUninstallKeys.Count) dupRegs=$($rst.duplicateUninstallRegistrations.Count) dupRoots=$($rst.duplicateInstallRoots.Count) payloadAllMatch=$($payload.payloadAllMatch) dbRetained=$($rst.dbRetainedAfterReinstall)"
} catch { Add-Gate 'Q14' $false $_.Exception.Message }

# ---------------------------------------------------------------- Q15
try {
    $l2 = Read-Evidence '17-second-launch-result.json'
    $close2 = Read-Evidence '17-second-launch-close.json'
    $shotDash = $l2.loginToDashboard.dashboardScreenshot
    $shotOk = ($shotDash -and (Test-Path -LiteralPath $shotDash))
    $q15 = ($l2.launch.windowFound -eq $true) -and
           ($l2.launch.processAliveAfter3s -eq $true) -and
           ($l2.launch.mainModuleMatchesInstalledExe -eq $true) -and
           ($l2.launch.windowStillValidAfter3s -eq $true) -and
           ($l2.loginToDashboard.loginTitleFound -eq $true) -and
           ($l2.loginToDashboard.dashboardReached -eq $true) -and
           ($l2.databaseAfterLogin.dbExists -eq $true) -and
           $shotOk -and
           ($close2.close.exited -eq $true) -and ($close2.dbStillPresentAfterSecondClose -eq $true) -and
           ($close2.orphanProcessIds.Count -eq 0)
    Add-Gate 'Q15' $q15 "second launch after reinstall: login->dashboard, DB retained, clean close, screenshot=$shotOk"
} catch { Add-Gate 'Q15' $false $_.Exception.Message }

# ---------------------------------------------------------------- Q16
try {
    $i1 = Read-Evidence '07-first-install-result.json'
    $i2 = Read-Evidence '15-reinstall-result.json'
    $q16 = ($i1.installerSha256 -eq $cfg.installer.sha256) -and ($i1.installerSize -eq $cfg.installer.sizeBytes) -and
           ($i2.installerSha256 -eq $cfg.installer.sha256) -and ($i2.installerSize -eq $cfg.installer.sizeBytes)
    Add-Gate 'Q16' $q16 "same installer provenance for both installs (sha=$($i1.installerSha256) == $($cfg.installer.sha256), size=$($i1.installerSize)==$($i2.installerSize))"
} catch { Add-Gate 'Q16' $false $_.Exception.Message }

# ---------------------------------------------------------------- Q17
try {
    $leakFiles = @()
    $scanRoots = @($EvidenceRoot)
    $orchPath = Join-Path (Split-Path -Parent $EvidenceRoot) '00-orchestration.json'
    if (-not (Test-Path -LiteralPath $orchPath)) { $orchPath = Join-Path $EvidenceRoot '00-orchestration.json' }
    $runRoot = Split-Path -Parent $orchPath
    if ($runRoot -and (Test-Path -LiteralPath $runRoot)) { $scanRoots += $runRoot }
    foreach ($root in $scanRoots) {
        foreach ($f in @(Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue)) {
            if ($f.Extension.ToLowerInvariant() -notin @('.json', '.txt', '.log', '.ps1', '.cmd', '.md', '.xml')) { continue }
            if ([System.IO.File]::ReadAllText($f.FullName) -match '[0-9a-f]{32}x7K!') { $leakFiles += $f.FullName }
        }
    }
    $secretsGone = $true
    if (Test-Path -LiteralPath $orchPath) {
        $orch = Read-JsonUtf8 -Path $orchPath
        $secretsFile = Join-Path $runRoot 'worker-secrets.json'
        $secretsGone = -not (Test-Path -LiteralPath $secretsFile)
    }
    $q17 = ($leakFiles.Count -eq 0) -and $secretsGone
    Add-Gate 'Q17' $q17 "secret hygiene: evidence+run-root secret-scan leaks=$($leakFiles.Count) secretsFileGone=$secretsGone"
} catch { Add-Gate 'Q17' $false $_.Exception.Message }

# ---------------------------------------------------------------- Q18
try {
    $gitViolations = $null
    $scopeOk = Test-GitCleanScope -RepoPath $WorktreePath -ExpectedHead $cfg.baselineCommit -AllowedPrefixes $cfg.allowedChangedPrefixes -Violations ([ref]$gitViolations)
    # Suppress native stderr via cmd: PowerShell 5.1 converts git warnings on
    # stderr (e.g. CRLF normalization notes) into terminating errors when
    # $ErrorActionPreference=Stop, regardless of PS-level redirection.
    $prodDiff = @(& cmd /c "git -C `"$WorktreePath`" diff --name-only $($cfg.baselineCommit) 2>nul")
    # Any path outside the governed campaign scope (cfg.allowedChangedPrefixes)
    # is a production-scope violation; changes inside the allowed prefixes are
    # the governed acceptance/tooling state of this campaign worktree.
    $prodViolations = @()
    foreach ($line in $prodDiff) {
        $allowed = $false
        foreach ($p in $cfg.allowedChangedPrefixes) {
            if ($line.StartsWith($p, [System.StringComparison]::Ordinal)) { $allowed = $true; break }
        }
        if (-not $allowed -and $line -ne '') { $prodViolations += $line }
    }
    $q18 = $scopeOk -and ($prodViolations.Count -eq 0)
    Add-Gate 'Q18' $q18 "repository integrity at gate time: scopeOk=$scopeOk prodDiffViolations=$($prodViolations.Count) ($($prodViolations -join ';'))"
} catch { Add-Gate 'Q18' $false $_.Exception.Message }

$allPass = (@($gates.Values | Where-Object { -not $_.pass }).Count -eq 0)
$result = [ordered]@{
    phase = 'MUAMAN-13Q'
    capturedAtUtc = Get-UtcString
    allPass = $allPass
    gateCount = $gates.Count
    gates = $gates
    evidenceRoot = $EvidenceRoot
    worktreePath = $WorktreePath
}
Write-JsonUtf8 -Path $OutFile -Object $result

$gates.GetEnumerator() | ForEach-Object { Write-Output ("{0} = {1}" -f $_.Key, $(if ($_.Value.pass) { 'PASS' } else { 'FAIL' })) }
Write-Output "allPass = $allPass"
if ($allPass) { exit 0 } else { exit 1 }
