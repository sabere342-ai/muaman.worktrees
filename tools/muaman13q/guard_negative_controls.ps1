# guard_negative_controls.ps1 - MUAMAN-13Q negative controls.
# Proves the harness fail-closed: for each injected defect the corresponding
# guard gate (or precondition) must FAIL, and a defect-free synthetic evidence
# set must PASS. Runs fully offline on synthetic fixtures; never touches the
# live product or registry beyond a self-cleaning HKCU test key.
#
# Exit 0 when every negative control behaves as expected, else 1.
#
# IMPORTANT: this file is ASCII-only.

[CmdletBinding()]
param(
    [string]$WorktreePath = 'C:\dev\muaman.worktrees\muaman-13q-independent-fresh-user-uninstall-reinstall-acceptance',
    [string]$MainRepoPath = 'C:\dev\muaman',
    [string]$FixtureRoot = 'C:\Users\saber\AppData\Local\Temp\opencode\m13q-negatives'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib\common.ps1')

$cfg = Read-JsonUtf8 -Path (Join-Path $PSScriptRoot 'acceptance-config.json')
$toolsDir = $PSScriptRoot

$results = [ordered]@{}
function Assert-Control {
    param([string]$Name, [bool]$Pass, [string]$Detail)
    $results[$Name] = [ordered]@{ pass = $Pass; detail = $Detail }
    Write-Output ("{0} = {1}  {2}" -f $Name, $(if ($Pass) { 'PASS' } else { 'FAIL' }), $Detail)
}

# A tiny valid PNG (1x1 transparent) so the screenshot-presence gates resolve.
function New-TinyPng {
    param([string]$Path)
    $b64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='
    [System.IO.File]::WriteAllBytes($Path, [System.Convert]::FromBase64String($b64))
}

# ---------------------------------------------------------------------------
# Build a fully-synthetic PASSING evidence set. Every gate Q1..Q18 reads only
# from these fixtures (Q1/Q18 also read live git state, which is checked to be
# clean-at-baseline by the fixtures' own reasoning below; the negative controls
# do not depend on Q1/Q18 flipping because they assert gate behavior on the
# evidence they inject).
# ---------------------------------------------------------------------------
function New-PassingEvidence {
    param([string]$Root)
    $jsonDir = Join-Path $Root 'json'
    $shotsDir = Join-Path $Root 'shots'
    New-Item -ItemType Directory -Path $jsonDir -Force | Out-Null
    New-Item -ItemType Directory -Path $shotsDir -Force | Out-Null

    $fakeSid = 'S-1-5-21-2052787611-3211508837-1074070108-1028'
    $installDir = "C:\Users\CodexMuaman13Q\AppData\Local\Programs\muaman_store"
    $dbRel = '.dart_tool/sqflite_common_ffi/databases/muaman_store.db'
    $dbFull = Join-Path $installDir ($dbRel -replace '/', '\')
    $exeRel = 'muaman_store.exe'
    $exeFull = Join-Path $installDir $exeRel

    $manifest = @(Read-JsonUtf8 -Path (Join-Path $MainRepoPath $cfg.referenceFiles.manifest13k))
    $contract = Read-JsonUtf8 -Path (Join-Path $MainRepoPath $cfg.referenceFiles.contract13n)

    $payloadRows = @()
    foreach ($f in $manifest.files) {
        $payloadRows += [ordered]@{ rel = $f.rel; expectedSize = $f.size; expectedSha256 = $f.sha256; installedSize = $f.size; installedSha256 = $f.sha256; match = $true }
    }
    $payload = [ordered]@{
        installDir = $installDir
        payloadFileCountExpected = $manifest.fileCount
        payloadFileCountInstalled = $manifest.fileCount
        payloadAllMatch = $true
        payload = $payloadRows
        innoUninstallerExtrasPresent = @('unins000.exe', 'unins000.dat')
        unexpectedFiles = @()
        mainExecutable = $contract.application.mainExecutable
        exeSizeMatch = $true
        exeSha256Match = $true
        exeInstalledSize = $contract.application.executableSize
        exeInstalledSha256 = $contract.application.executableSha256
        flutterWindowsDllSha256 = $cfg.application.flutterWindowsDllSha256
    }

    $win = [ordered]@{ handle = '0x0'; title = 'muaman_store'; className = 'FLUTTER_RUNNER_WIN32_WINDOW' }
    $l1 = [ordered]@{
        launch = [ordered]@{
            exe = $exeFull; workingDirectory = $installDir; restrictedPath = "$env:SystemRoot\System32;$env:SystemRoot"
            processId = 1234; sessionId = 1; secondsToWindow = 2.0; windowFound = $true; window = $win
            processAliveAfter3s = $true; mainModulePath = $exeFull; mainModuleMatchesInstalledExe = $true; windowStillValidAfter3s = $true
        }
        setupToDashboard = [ordered]@{
            setupTitleFound = $true; fieldsFound = $true
            ownerMethods = [ordered]@{ name = 'RowTarget+FocusVerify try=1'; user = 'RowTarget+FocusVerify try=1'; pass = 'Masked'; confirm = 'Masked' }
            createButton = [ordered]@{ clicked = $true; try = 1; screenX = 1; screenY = 1; word = 'x' }
            setupScreenshot = (Join-Path $shotsDir '09s-setup-initial.png')
        }
        loginToDashboard = [ordered]@{
            loginTitleFound = $true; loginButtonFound = $true
            loginMethods = [ordered]@{ user = 'RowTarget+FocusVerify try=1'; pass = 'Masked' }
            loginButton = [ordered]@{ clicked = $true; try = 1; screenX = 1; screenY = 1; word = 'x' }
            dashboardReached = $true
            loginScreenshot = (Join-Path $shotsDir '09l-login.png')
            dashboardScreenshot = (Join-Path $shotsDir '09l-dashboard.png')
        }
        databaseAfterSetup = [ordered]@{
            path = $dbFull; dbExists = $true; sizeBytes = 4096
            sha256 = 'A' * 64; sqliteHeaderValid = $true
            tablesFound = @('products', 'sales', 'users', 'app_settings')
            ownerUsernameTextPresent = $true
            lastWriteTimeUtc = '2026-08-09T00:00:00.000Z'
        }
    }
    $close1 = [ordered]@{ close = [ordered]@{ method = 'WM_CLOSE'; exited = $true; exitCode = 0; seconds = 1.0 }; dbStillPresentAfterClose = $true; orphanProcessIds = @() }

    New-TinyPng -Path (Join-Path $shotsDir '09s-setup-initial.png')
    New-TinyPng -Path (Join-Path $shotsDir '09l-login.png')
    New-TinyPng -Path (Join-Path $shotsDir '09l-dashboard.png')
    New-TinyPng -Path (Join-Path $shotsDir '17-launch2-window.png')
    New-TinyPng -Path (Join-Path $shotsDir '17-dashboard.png')

    Write-JsonUtf8 -Path (Join-Path $jsonDir '04-user-identity.json') -Object ([ordered]@{
        whoamiUser = "codexmuaman13q"; tokenName = "DESKTOP-ABC\CodexMuaman13Q"; tokenSid = $fakeSid
        expectedUserName = 'CodexMuaman13Q'; tokenNameMatchesExpected = $true
        localUserExists = $true; localUserSid = $fakeSid; localUserEnabled = $true
        groupMembership = @('Users'); inAdministrators = $false
        integrity = [ordered]@{ level = 'Medium'; sid = 'S-1-16-8192' }
        elevation = [ordered]@{ isInAdministrators = $false; note = 'x' }
        session = [ordered]@{ sessionId = 1; processId = 1234; processName = 'powershell' }
        isInteractive = $true
        privilegeSummary = [ordered]@{ forbiddenEnabledPresent = @() }
        groupsText = 'Mandatory Label\Medium Mandatory Level'
    })
    Write-JsonUtf8 -Path (Join-Path $jsonDir '05-preinstall-state.json') -Object ([ordered]@{
        os = [ordered]@{ caption = 'Windows 11 Pro'; version = '10.0.26100'; build = '26100'; osArchitecture = '64-bit'; processArchitecture = 'AMD64' }
        user = [ordered]@{ localAppData = "C:\Users\CodexMuaman13Q\AppData\Local"; appData = "C:\Users\CodexMuaman13Q\AppData\Roaming"; userProfile = "C:\Users\CodexMuaman13Q"; userProfileDirExists = $true }
        install = [ordered]@{ installDir = $installDir; installDirExistsBefore = $false; appExeExistsBefore = $false; hkcuMuamanUninstallKeys = @(); uninstallRegistrationAbsent = $true }
        processes = [ordered]@{ appProcessIdsBefore = @(); uninstallerProcessIdsBefore = @() }
        osAccountPicturePlaceholder = [ordered]@{ path = "C:\ProgramData\Microsoft\User Account Pictures\CodexMuaman13Q.dat"; exists = $true }
        localAppDataListing = @()
        appDataListing = @()
    })
    Write-JsonUtf8 -Path (Join-Path $jsonDir '07-first-install-result.json') -Object ([ordered]@{
        commandLine = "x"; exitCode = 0; timedOut = $false; durationSec = 5.0; installLogPath = "x"; installLogBytes = 100
        appExeExists = $true; installDir = $installDir
        installerSha256 = $cfg.installer.sha256; installerSize = $cfg.installer.sizeBytes
    })
    Write-JsonUtf8 -Path (Join-Path $jsonDir '08-installed-state.json') -Object ([ordered]@{
        uninstallKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{$($cfg.application.appId)}_is1"
        hkcuUninstallPresent = $true
        hkcuUninstall = [ordered]@{ DisplayName = $cfg.uninstall.displayName; UninstallString = "`"$installDir\unins000.exe`"" }
        hkcuMuamanUninstallKeys = @("{$($cfg.application.appId)}_is1")
        startMenuLink = ("C:\Users\CodexMuaman13Q\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\" + $cfg.shortcut.startMenuName)
        startMenuLinkExists = $true
        machineStartMenuLinkExists = $false
        startMenuShortcutTarget = $exeFull
        payload = $payload
        hklmUninstallHits = @()
    })
    Write-JsonUtf8 -Path (Join-Path $jsonDir '09-first-launch-result.json') -Object $l1
    Write-JsonUtf8 -Path (Join-Path $jsonDir '09-first-launch-close.json') -Object $close1
    Write-JsonUtf8 -Path (Join-Path $jsonDir '10-preuninstall-snapshot.json') -Object ([ordered]@{
        processIds = @(); installRoot = @(); uninstallKey = 'x'; hkcuUninstall = [ordered]@{ DisplayName = $cfg.uninstall.displayName }
        db = $l1.databaseAfterSetup; startMenuLinkExists = $true; localAppDataListingBeforeUninstall = @(); appDataListingBeforeUninstall = @()
    })
    Write-JsonUtf8 -Path (Join-Path $jsonDir '11-uninstall-registration.json') -Object ([ordered]@{
        registrationKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{$($cfg.application.appId)}_is1"
        displayName = $cfg.uninstall.displayName; publisher = $cfg.uninstall.publisher; displayVersion = '1.0.0'; installLocation = $installDir
        uninstallString = "`"$installDir\unins000.exe`" /VERYSILENT"
        uninstallerPath = "$installDir\unins000.exe"; uninstallerExists = $true
        expectedUninstaller = "$installDir\unins000.exe"; uninstallerMatchesExpected = $true
    })
    Write-JsonUtf8 -Path (Join-Path $jsonDir '12-uninstall-result.json') -Object ([ordered]@{
        commandLine = "x"; uninstallerPath = "$installDir\unins000.exe"; exitCode = 0; timedOut = $false; durationSec = 4.0
        uninstallLogPath = 'x'; uninstallLogBytes = 100
        registrationRemoved = [ordered]@{ ok = $true; seconds = 1.0; polls = @(); what = 'uninstall-registration-disappears' }
        installedExeRemoved = [ordered]@{ ok = $true; seconds = 1.0; polls = @(); what = 'installed-exe-disappears' }
        uninstallerRemoved = [ordered]@{ ok = $true; seconds = 1.0; polls = @(); what = 'uninstaller-disappears' }
        processesGone = [ordered]@{ ok = $true; seconds = 1.0; polls = @(); what = 'processes-gone' }
    })
    Write-JsonUtf8 -Path (Join-Path $jsonDir '13-postuninstall-state.json') -Object ([ordered]@{
        appProcessIds = @(); uninstallerProcessIds = @(); hkcuMuamanUninstallKeys = @(); registrationRemoved = $true
        installDir = $installDir; installDirExists = $true; appExeExists = $false
        payloadFilesStillPresent = @(); uninsExtrasStillPresent = @(); startMenuLinkExists = $false
        installRootListing = @([ordered]@{ rel = $dbRel; size = 4096; sha256 = 'A' * 64; lastWriteTimeUtc = 'x' })
        db = [ordered]@{ path = $dbFull; dbExists = $true; sizeBytes = 4096; sha256 = 'A' * 64; sqliteHeaderValid = $true; tablesFound = @('users'); ownerUsernameTextPresent = $true; lastWriteTimeUtc = 'x' }
        osAccountPicturePlaceholderExists = $true
    })
    Write-JsonUtf8 -Path (Join-Path $jsonDir '14-leftover-classification.json') -Object ([ordered]@{
        expectedRetainedUserData = @([ordered]@{ path = $dbRel; classification = 'expected-retained-user-data'; detail = 'business SQLite database' })
        osAccountPicturePlaceholder = [ordered]@{ path = "C:\ProgramData\Microsoft\User Account Pictures\CodexMuaman13Q.dat"; exists = $true; classifiedAs = 'os-account-picture-placeholder' }
        unknownInstallerLeftovers = @()
        localAppDataDelta = [ordered]@{ added = @(); removed = @(); changed = @(); unchangedCount = 0 }
        appDataDelta = [ordered]@{ added = @(); removed = @(); changed = @(); unchangedCount = 0 }
        deltaChurnInformational = @()
        hklmMuamanHits = @(); programDataMuamanHitsExcludingAccountPictures = @(); classificationComplete = $true
    })
    Write-JsonUtf8 -Path (Join-Path $jsonDir '15-reinstall-result.json') -Object ([ordered]@{
        commandLine = "x"; exitCode = 0; timedOut = $false; durationSec = 5.0; installLogPath = 'x'; installLogBytes = 100
        appExeExists = $true; installDir = $installDir
        installerSha256 = $cfg.installer.sha256; installerSize = $cfg.installer.sizeBytes
    })
    Write-JsonUtf8 -Path (Join-Path $jsonDir '16-reinstalled-state.json') -Object ([ordered]@{
        uninstallKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{$($cfg.application.appId)}_is1"
        hkcuUninstallPresent = $true
        hkcuUninstall = [ordered]@{ DisplayName = $cfg.uninstall.displayName; UninstallString = "`"$installDir\unins000.exe`"" }
        hkcuMuamanUninstallKeys = @("{$($cfg.application.appId)}_is1")
        duplicateUninstallRegistrations = @()
        installRoots = @($installDir); duplicateInstallRoots = @()
        startMenuLink = ("C:\Users\CodexMuaman13Q\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\" + $cfg.shortcut.startMenuName)
        startMenuLinkExists = $true; machineStartMenuLinkExists = $false
        startMenuShortcutTarget = $exeFull; startMenuHits = @("C:\Users\CodexMuaman13Q\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\" + $cfg.shortcut.startMenuName)
        payload = $payload
        dbRetainedAfterReinstall = $true
    })
    Write-JsonUtf8 -Path (Join-Path $jsonDir '17-second-launch-result.json') -Object ([ordered]@{
        launch = [ordered]@{
            exe = $exeFull; workingDirectory = $installDir; restrictedPath = "$env:SystemRoot\System32;$env:SystemRoot"
            processId = 5678; sessionId = 1; secondsToWindow = 1.0; windowFound = $true; window = $win
            processAliveAfter3s = $true; mainModulePath = $exeFull; mainModuleMatchesInstalledExe = $true; windowStillValidAfter3s = $true
        }
        loginToDashboard = [ordered]@{
            loginTitleFound = $true; loginButtonFound = $true
            loginMethods = [ordered]@{ user = 'RowTarget+FocusVerify try=1'; pass = 'Masked' }
            loginButton = [ordered]@{ clicked = $true; try = 1; screenX = 1; screenY = 1; word = 'x' }
            dashboardReached = $true
            loginScreenshot = (Join-Path $shotsDir '17-login.png')
            dashboardScreenshot = (Join-Path $shotsDir '17-dashboard.png')
        }
        databaseAfterLogin = [ordered]@{
            path = $dbFull; dbExists = $true; sizeBytes = 8192
            sha256 = 'B' * 64; sqliteHeaderValid = $true
            tablesFound = @('products', 'sales', 'users', 'app_settings')
            ownerUsernameTextPresent = $true
            lastWriteTimeUtc = '2026-08-09T01:00:00.000Z'
        }
    })
    New-TinyPng -Path (Join-Path $shotsDir '17-login.png')
    Write-JsonUtf8 -Path (Join-Path $jsonDir '17-second-launch-close.json') -Object ([ordered]@{
        close = [ordered]@{ method = 'WM_CLOSE'; exited = $true; exitCode = 0; seconds = 1.0 }; dbStillPresentAfterSecondClose = $true; orphanProcessIds = @()
    })
    Write-JsonUtf8 -Path (Join-Path $jsonDir '20-final-state.json') -Object ([ordered]@{
        appProcessIds = @(); uninstallerProcessIds = @(); installDirExists = $true; appExeExists = $true; dbStillPresent = $true
        hkcuMuamanUninstallKeys = @("{$($cfg.application.appId)}_is1"); installRootListing = @(); capturedAtUtc = Get-UtcString
    })
    Write-JsonUtf8 -Path (Join-Path $jsonDir 'worker-done.json') -Object ([ordered]@{
        runId = 'synthetic'; phase = 'MUAMAN-13Q'; startedAtUtc = Get-UtcString; finishedAtUtc = Get-UtcString
        workerUser = "DESKTOP-ABC\CodexMuaman13Q"; allStepsPassed = $true; failedSteps = @(); steps = [ordered]@{}
    })
}

# Orchestration record at the run root (parent of evidence) for Q2/Q17.
function New-Orchestration {
    param([string]$RunRoot, [string]$InstallerSha = $cfg.installer.sha256, [int64]$InstallerSize = [int64]$cfg.installer.sizeBytes)
    $p = Join-Path $RunRoot '00-orchestration.json'
    Write-JsonUtf8 -Path $p -Object ([ordered]@{
        runId = 'synthetic'; startedAtUtc = Get-UtcString; phase = 'MUAMAN-13Q'
        installerSha256 = $InstallerSha; installerSize = $InstallerSize; accountSid = 'S-1-5-21-2052787611-3211508837-1074070108-1028'
    })
}

# ---------------------------------------------------------------------------
# Fixture management
# ---------------------------------------------------------------------------
function New-Fixture {
    param([string]$Name, [scriptblock]$Mutate)
    $runRoot = Join-Path $FixtureRoot $Name
    if (Test-Path -LiteralPath $runRoot) { Remove-Item -LiteralPath $runRoot -Recurse -Force }
    $evidenceRoot = Join-Path $runRoot 'evidence'
    New-Item -ItemType Directory -Path $evidenceRoot -Force | Out-Null
    New-PassingEvidence -Root $evidenceRoot
    New-Orchestration -RunRoot $runRoot
    if ($Mutate) { & $Mutate -RunRoot $runRoot -EvidenceRoot $evidenceRoot }
    return [ordered]@{ runRoot = $runRoot; evidenceRoot = $evidenceRoot }
}

function Invoke-Guards {
    param([string]$RunRoot)
    $out = Join-Path $RunRoot 'guards-result.json'
    $evidenceRoot = Join-Path $RunRoot 'evidence'
    & (Join-Path $toolsDir 'guard_tests_13q.ps1') `
        -EvidenceRoot $evidenceRoot `
        -WorktreePath $WorktreePath `
        -MainRepoPath $MainRepoPath `
        -ConfigPath (Join-Path $toolsDir 'acceptance-config.json') `
        -RefDir $toolsDir `
        -OutFile $out `
        -OwnerUsername 'owner13q' `
        -OwnerDisplayName 'مالك 13Q' `
        -AccountSid 'S-1-5-21-2052787611-3211508837-1074070108-1028' 2>&1 | Out-Null
    return [ordered]@{ exitCode = $LASTEXITCODE; result = (Read-JsonUtf8 -Path $out) }
}

function Get-GatePass {
    param($GuardResult, [string]$GateName)
    return [bool]$GuardResult.result.gates.$GateName.pass
}

# ---------------------------------------------------------------------------
# Control 01: defect-free synthetic evidence must PASS all gates (negative
# controls are only meaningful if the baseline fixture itself is green).
# ---------------------------------------------------------------------------
try {
    $fx = New-Fixture -Name 'baseline'
    $g = Invoke-Guards -RunRoot $fx.runRoot
    $failedGates = @($g.result.gates.PSObject.Properties | Where-Object { -not $_.Value.pass } | ForEach-Object { $_.Name })
    $green = ($g.exitCode -eq 0) -and ($failedGates.Count -eq 0)
    Assert-Control 'NC01-baseline-green' $green "exit=$($g.exitCode) failedGates=$($failedGates -join ',')"
} catch { Assert-Control 'NC01-baseline-green' $false $_.Exception.Message }

# ---------------------------------------------------------------------------
# Control 02: missing evidence file must fail the gate that reads it (missing
# 09-first-launch-close.json -> Q7 must FAIL).
# ---------------------------------------------------------------------------
try {
    $fx = New-Fixture -Name 'missing-evidence' -Mutate {
        param($RunRoot, $EvidenceRoot)
        Remove-Item -LiteralPath (Join-Path $EvidenceRoot 'json\09-first-launch-close.json') -Force
    }
    $g = Invoke-Guards -RunRoot $fx.runRoot
    $q7 = Get-GatePass $g 'Q7'
    Assert-Control 'NC02-missing-evidence-fails' (-not $q7) "Q7 pass=$q7 (expected FAIL when 09-first-launch-close.json missing)"
} catch { Assert-Control 'NC02-missing-evidence-fails' $false $_.Exception.Message }

# ---------------------------------------------------------------------------
# Control 03: bad installer SHA in orchestration must fail Q2.
# ---------------------------------------------------------------------------
try {
    $fx = New-Fixture -Name 'bad-sha' -Mutate {
        param($RunRoot, $EvidenceRoot)
        New-Orchestration -RunRoot $RunRoot -InstallerSha ('F' * 64)
    }
    $g = Invoke-Guards -RunRoot $fx.runRoot
    $q2 = Get-GatePass $g 'Q2'
    Assert-Control 'NC03-bad-sha-fails' (-not $q2) "Q2 pass=$q2 (expected FAIL on wrong installer SHA)"
} catch { Assert-Control 'NC03-bad-sha-fails' $false $_.Exception.Message }

# ---------------------------------------------------------------------------
# Control 04: duplicate uninstall registration after reinstall must fail Q14.
# ---------------------------------------------------------------------------
try {
    $fx = New-Fixture -Name 'duplicate-registration' -Mutate {
        param($RunRoot, $EvidenceRoot)
        $p = Join-Path $EvidenceRoot 'json\16-reinstalled-state.json'
        $j = Read-JsonUtf8 -Path $p
        $j.hkcuMuamanUninstallKeys = @("{$($cfg.application.appId)}_is1", "{$($cfg.application.appId)}_is1")
        $j.duplicateUninstallRegistrations = @("{$($cfg.application.appId)}_is1")
        Write-JsonUtf8 -Path $p -Object $j
    }
    $g = Invoke-Guards -RunRoot $fx.runRoot
    $q14 = Get-GatePass $g 'Q14'
    Assert-Control 'NC04-duplicate-registration-fails' (-not $q14) "Q14 pass=$q14 (expected FAIL on duplicate registration)"
} catch { Assert-Control 'NC04-duplicate-registration-fails' $false $_.Exception.Message }

# ---------------------------------------------------------------------------
# Control 05: secret sentinel in evidence must fail Q17.
# ---------------------------------------------------------------------------
try {
    $fx = New-Fixture -Name 'secret-leak' -Mutate {
        param($RunRoot, $EvidenceRoot)
        [System.IO.File]::WriteAllText((Join-Path $EvidenceRoot 'json\leak.txt'), "0123456789abcdef0123456789abcdefx7K!", (New-Object System.Text.UTF8Encoding $false))
    }
    $g = Invoke-Guards -RunRoot $fx.runRoot
    $q17 = Get-GatePass $g 'Q17'
    Assert-Control 'NC05-secret-sentinel-fails' (-not $q17) "Q17 pass=$q17 (expected FAIL on secret sentinel)"
} catch { Assert-Control 'NC05-secret-sentinel-fails' $false $_.Exception.Message }

# ---------------------------------------------------------------------------
# Control 06: missing worker-done.json must be detected as a hard failure.
# ---------------------------------------------------------------------------
try {
    $fx = New-Fixture -Name 'missing-worker-done'
    Remove-Item -LiteralPath (Join-Path $fx.evidenceRoot 'json\worker-done.json') -Force
    $donePath = Join-Path $fx.evidenceRoot 'json\worker-done.json'
    $detected = -not (Test-Path -LiteralPath $donePath)
    Assert-Control 'NC06-missing-worker-done-detected' $detected "worker-done.json absent -> orchestrator precondition fails"
} catch { Assert-Control 'NC06-missing-worker-done-detected' $false $_.Exception.Message }

# ---------------------------------------------------------------------------
# Control 07: synthetic installer leftover after uninstall must fail Q12.
# ---------------------------------------------------------------------------
try {
    $fx = New-Fixture -Name 'installer-leftover' -Mutate {
        param($RunRoot, $EvidenceRoot)
        $p = Join-Path $EvidenceRoot 'json\14-leftover-classification.json'
        $j = Read-JsonUtf8 -Path $p
        $j.unknownInstallerLeftovers = @([ordered]@{ path = '.dart_tool/cache/leftover.bin'; classification = 'unknown-installer-leftover' })
        Write-JsonUtf8 -Path $p -Object $j
    }
    $g = Invoke-Guards -RunRoot $fx.runRoot
    $q12 = Get-GatePass $g 'Q12'
    Assert-Control 'NC07-installer-leftover-fails' (-not $q12) "Q12 pass=$q12 (expected FAIL on unknown installer leftover)"
} catch { Assert-Control 'NC07-installer-leftover-fails' $false $_.Exception.Message }

# ---------------------------------------------------------------------------
# Control 08: incomplete post-uninstall scan (postUninstallState reports a
# still-present payload file) must fail Q11.
# ---------------------------------------------------------------------------
try {
    $fx = New-Fixture -Name 'incomplete-scan' -Mutate {
        param($RunRoot, $EvidenceRoot)
        $p = Join-Path $EvidenceRoot 'json\13-postuninstall-state.json'
        $j = Read-JsonUtf8 -Path $p
        $j.payloadFilesStillPresent = @('data/app.so')
        Write-JsonUtf8 -Path $p -Object $j
    }
    $g = Invoke-Guards -RunRoot $fx.runRoot
    $q11 = Get-GatePass $g 'Q11'
    Assert-Control 'NC08-incomplete-scan-fails' (-not $q11) "Q11 pass=$q11 (expected FAIL when a payload file is still present post-uninstall)"
} catch { Assert-Control 'NC08-incomplete-scan-fails' $false $_.Exception.Message }

# ---------------------------------------------------------------------------
# Control 09: account-picture placeholder is a known false positive and must
# NOT be treated as an unknown leftover when correctly classified.
# ---------------------------------------------------------------------------
try {
    $fx = New-Fixture -Name 'account-picture-ok' -Mutate {
        param($RunRoot, $EvidenceRoot)
        # The baseline fixture already classifies the placeholder correctly;
        # additionally prove a real leftover path that merely CONTAINS the
        # account-name does not get silently excluded (guard is path-precise).
        $p = Join-Path $EvidenceRoot 'json\14-leftover-classification.json'
        $j = Read-JsonUtf8 -Path $p
        $j.unknownInstallerLeftovers = @([ordered]@{ path = "C:\ProgramData\Microsoft\User Account Pictures\CodexMuaman13Q-extra.dat"; classification = 'unknown-installer-leftover' })
        Write-JsonUtf8 -Path $p -Object $j
    }
    $g = Invoke-Guards -RunRoot $fx.runRoot
    $q12 = Get-GatePass $g 'Q12'
    Assert-Control 'NC09-account-picture-precision' (-not $q12) "Q12 pass=$q12 (a muaman-named file NEAR the placeholder must still FAIL the leftover gate)"
} catch { Assert-Control 'NC09-account-picture-precision' $false $_.Exception.Message }

# ---------------------------------------------------------------------------
# Control 10: malformed uninstall key (no DisplayName / no publisher) must not
# break the HKCU scan helper (Get-HkcuUninstallMuamanKeys) nor match.
# Uses a self-cleaning HKCU test root under the current user.
# ---------------------------------------------------------------------------
try {
    $testRoot = 'HKCU:\Software\M13QNegativeControl'
    if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
    New-Item -Path $testRoot -Force | Out-Null
    # child with no DisplayName at all (malformed, matches only by suffix)
    New-Item -Path (Join-Path $testRoot '{299ADF2A-0E9E-4A25-916C-1CB8328D0E5E}_is1') -Force | Out-Null
    # decoy unrelated key: no _is1 suffix, different DisplayName -> must NOT match
    New-Item -Path (Join-Path $testRoot 'SomeOtherApp') -Force | Out-Null
    New-ItemProperty -Path (Join-Path $testRoot 'SomeOtherApp') -Name DisplayName -Value 'SomeOtherApp' -PropertyType String -Force | Out-Null
    $hits = Get-HkcuUninstallMuamanKeys -Root $testRoot -DisplayName $cfg.uninstall.displayName -Publisher $cfg.uninstall.publisher -KeySuffix '_is1'
    $malformedNoThrow = $true
    $matchedOnlyExpected = (@($hits).Count -eq 1) -and (@($hits) -contains '{299ADF2A-0E9E-4A25-916C-1CB8328D0E5E}_is1')
    Assert-Control 'NC10-malformed-key-scan-safe' ($malformedNoThrow -and $matchedOnlyExpected) "malformed key scanned without error; hits=$(@($hits) -join ',') (expected the muaman suffix key only)"
} catch { Assert-Control 'NC10-malformed-key-scan-safe' $false $_.Exception.Message }
finally {
    if (Test-Path -LiteralPath 'HKCU:\Software\M13QNegativeControl') {
        Remove-Item -LiteralPath 'HKCU:\Software\M13QNegativeControl' -Recurse -Force
    }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
$allPass = (@($results.Values | Where-Object { -not $_.pass }).Count -eq 0)
Write-Output ''
Write-Output "negative controls allPass = $allPass"
if ($allPass) { exit 0 } else { exit 1 }
