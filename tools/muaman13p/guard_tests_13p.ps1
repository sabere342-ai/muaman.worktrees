# guard_tests_13p.ps1 - MUAMAN-13P P1..P16 acceptance gates.
# Computes the mandatory acceptance gates from the recorded worker evidence plus
# live repo/toolchain state. P15/P16 are the deterministic row-targeting
# regression gates (see below). Writes guards-result.json (UTF-8 no BOM) and
# exits 0 when allPass=true, otherwise 1.
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
$U = Read-JsonUtf8 -Path (Join-Path $RefDir 'ui_strings.json')
# The Windows OCR API requires absolute paths; normalize the evidence root so
# the regression gate works whether the caller passes relative or absolute.
$EvidenceRoot = [System.IO.Path]::GetFullPath($EvidenceRoot)
$jsonDir = Join-Path $EvidenceRoot 'json'
$shotsDir = Join-Path $EvidenceRoot 'shots'
$uiaDir = Join-Path $EvidenceRoot 'uia'

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

# ---------------------------------------------------------------- P1
try {
    $id = Read-Evidence '04-fresh-user-context.json'
    $p1 = ($id.tokenNameMatchesExpected -eq $true) -and
          ($id.tokenSid -eq $AccountSid) -and
          ($id.localUserExists -eq $true) -and
          ($id.localUserEnabled -eq $true) -and
          ($id.inAdministrators -eq $false) -and
          (($id.groupMembership -notcontains 'Administrators')) -and
          ($id.integrity.level -like 'Medium*') -and
          ($id.elevation.isInAdministrators -eq $false) -and
          ($id.privilegeSummary.forbiddenEnabledPresent.Count -eq 0)
    Add-Gate 'P1' $p1 "fresh independent standard user context (SID $($id.tokenSid), groups=$($id.groupMembership -join '+'), integrity=$($id.integrity.level), no admin privileges)"
} catch { Add-Gate 'P1' $false $_.Exception.Message }

# ---------------------------------------------------------------- P2
try {
    $orchPath = Join-Path (Split-Path -Parent $EvidenceRoot) '00-orchestration.json'
    if (-not (Test-Path -LiteralPath $orchPath)) { $orchPath = Join-Path $EvidenceRoot '00-orchestration.json' }
    if (-not (Test-Path -LiteralPath $orchPath)) { throw '00-orchestration.json missing from run evidence' }
    $orch = Read-JsonUtf8 -Path $orchPath
    $instHash = [string]$orch.installerSha256
    $instSize = [int64]$orch.installerSize
    $p2 = ($instHash -eq $cfg.installer.sha256) -and ($instSize -eq [int64]$cfg.installer.sizeBytes)
    if ($p2 -and $InstallerPath -and (Test-Path -LiteralPath $InstallerPath)) {
        $p2 = ((Get-FileSha256 -Path $InstallerPath) -eq $cfg.installer.sha256) -and
              ((Get-Item -LiteralPath $InstallerPath).Length -eq $cfg.installer.sizeBytes)
    }
    Add-Gate 'P2' $p2 "frozen installer identity (from run evidence) sha=$instHash size=$instSize expected=$($cfg.installer.sha256)/$($cfg.installer.sizeBytes)"
} catch { Add-Gate 'P2' $false $_.Exception.Message }

# ---------------------------------------------------------------- P3
try {
    $inst = Read-Evidence '07-install-run.json'
    $payload = Read-Evidence '09-installed-payload.json'
    $p3 = ($inst.exitCode -eq 0) -and ($inst.timedOut -eq $false) -and ($inst.appExeExists -eq $true) -and
          ($payload.payloadAllMatch -eq $true) -and ($payload.unexpectedFiles.Count -eq 0) -and
          ($payload.exeSizeMatch -eq $true) -and ($payload.exeSha256Match -eq $true)
    Add-Gate 'P3' $p3 "silent install exit=$($inst.exitCode) appExeExists=$($inst.appExeExists) payloadAllMatch=$($payload.payloadAllMatch) unexpected=$($payload.unexpectedFiles.Count)"
} catch { Add-Gate 'P3' $false $_.Exception.Message }

# ---------------------------------------------------------------- P4
try {
    $inst = Read-Evidence '07-install-run.json'
    $reg = Read-Evidence '08-install-registry.json'
    $id2 = Read-Evidence '04-fresh-user-context.json'
    $pre = Read-Evidence '06-prestate.json'
    $installDir = $inst.installDir
    $freshLocalAppData = [string]$pre.localAppData
    $inLocalAppData = $installDir -and $freshLocalAppData -and
        $installDir.StartsWith((Join-Path $freshLocalAppData 'Programs'), [System.StringComparison]::OrdinalIgnoreCase)
    $p4 = ($inst.exitCode -eq 0) -and ($id2.inAdministrators -eq $false) -and $inLocalAppData -and ($reg.hkcuUninstallPresent -eq $true)
    Add-Gate 'P4' $p4 "no elevation required: non-admin fresh user installed per-user (exit 0, dir=$installDir inLocalAppData=$inLocalAppData hkcuUninstall=$($reg.hkcuUninstallPresent))"
} catch { Add-Gate 'P4' $false $_.Exception.Message }

# ---------------------------------------------------------------- P5
try {
    $payload = Read-Evidence '09-installed-payload.json'
    $p5 = ($payload.payloadFileCountInstalled -eq $cfg.application.payloadFileCount) -and
          ($payload.payloadAllMatch -eq $true) -and
          ($payload.unexpectedFiles.Count -eq 0) -and
          ($payload.innoUninstallerExtrasPresent.Count -gt 0) -and
          ($payload.flutterWindowsDllSha256 -eq $cfg.application.flutterWindowsDllSha256)
    Add-Gate 'P5' $p5 "installed payload matches 13K/13N contract ($($payload.payloadFileCountInstalled)/$($cfg.application.payloadFileCount), allMatch=$($payload.payloadAllMatch), unexpected=$($payload.unexpectedFiles.Count))"
} catch { Add-Gate 'P5' $false $_.Exception.Message }

# ---------------------------------------------------------------- P6
try {
    $reg = Read-Evidence '08-install-registry.json'
    $pre = Read-Evidence '06-prestate.json'
    $freshLocalAppData = [string]$pre.localAppData
    $freshAppData = [string]$pre.appData
    $expectedExe = Join-Path (Join-Path (Join-Path $freshLocalAppData 'Programs') $cfg.application.appDirName) $cfg.application.mainExecutable
    $startMenuInFreshProfile = $reg.startMenuLink -and $freshAppData -and
        $reg.startMenuLink.StartsWith((Join-Path $freshAppData 'Microsoft\Windows\Start Menu'), [System.StringComparison]::OrdinalIgnoreCase)
    $autorunAllEmpty = $true
    foreach ($k in $reg.autorun.PSObject.Properties) { if ($k.Value.Count -gt 0) { $autorunAllEmpty = $false } }
    $p6 = ($reg.startMenuLinkExists -eq $true) -and ($reg.machineStartMenuLinkExists -eq $false) -and
          ($reg.startMenuShortcutTarget -eq $expectedExe) -and $startMenuInFreshProfile -and
          ($reg.startupFolderHits.Count -eq 0) -and $autorunAllEmpty
    Add-Gate 'P6' $p6 "start menu link (per-user only, target=$($reg.startMenuShortcutTarget) expected=$expectedExe) + no autorun/startup entries"
} catch { Add-Gate 'P6' $false $_.Exception.Message }

# ---------------------------------------------------------------- P7
try {
    $l1 = Read-Evidence '10-launch1-window.json'
    $shot = $l1.launch.window.firstScreenshot
    $shotOk = $shot -and (Test-Path -LiteralPath $shot)
    $p7 = ($l1.launch.windowFound -eq $true) -and ($null -ne $l1.launch.window.title) -and ($l1.launch.window.title -ne '') -and $shotOk
    Add-Gate 'P7' $p7 "first launch: main window found (title='$($l1.launch.window.title)'), screenshot=$shotOk"
} catch { Add-Gate 'P7' $false $_.Exception.Message }

# ---------------------------------------------------------------- P8
try {
    $setup = Read-Evidence '11-launch1-setup.json'
    $filled = Read-Evidence '12-launch1-setup-filled.json'
    $login = Read-Evidence '13-launch1-login.json'
    $dash = Read-Evidence '14-launch1-dashboard.json'
    $db = Read-Evidence '15-database.json'
    $fieldKeys = @('name', 'user', 'pass', 'confirm')
    $setupFieldsOk = ($null -ne $setup.fields) -and
        (@($fieldKeys | Where-Object { $setup.fields.PSObject.Properties.Name -contains $_ }).Count -eq 4)
    $ownerMethodsOk = ($null -ne $filled.methods) -and (@($filled.methods.PSObject.Properties).Count -ge 4) -and
        ($filled.button.clicked -eq $true)
    $p8 = ($setup.setupTitleFound -eq $true) -and $setupFieldsOk -and $ownerMethodsOk -and
          ($login.loginTitleFound -eq $true) -and ($login.loginButtonFound -eq $true) -and
          ($dash.dashboardTitleFound -eq $true) -and
          ($db.dbExists -eq $true) -and ($db.db.sqliteHeaderValid -eq $true) -and
          (($db.db.tablesFound -contains 'users')) -and ($db.db.ownerUsernameTextPresent -eq $true)
    Add-Gate 'P8' $p8 "documented login flow: first-owner setup -> login -> dashboard; DB created with owner"
} catch { Add-Gate 'P8' $false $_.Exception.Message }

# ---------------------------------------------------------------- P9
try {
    $tools = Read-Evidence '05-tool-isolation.json'
    $l1 = Read-Evidence '10-launch1-window.json'
    $dash = Read-Evidence '14-launch1-dashboard.json'
    $devToolsOnRestrictedPath = @($tools.restrictedEnvironmentResolved.PSObject.Properties | Where-Object { $_.Name -in @('flutter','dart','git','cmake','ninja','msbuild','dotnet','node','npm','java','python','go','rustc','cl') })
    $expectedRestrictedPath = $cfg.restrictedPath -replace '%SystemRoot%', $env:SystemRoot
    # The worker resolves tools in the fresh-user context (flutter is not on the
    # fresh user's PATH), so flutter-on-machine is asserted here in the
    # developer context, the same way P14 locates the flutter SDK.
    $flutterPresent = $null -ne (Get-Command flutter -ErrorAction SilentlyContinue)
    if (-not $flutterPresent) {
        foreach ($c in @('C:\dev\flutter\bin\flutter.bat', 'C:\flutter\bin\flutter.bat', "$env:USERPROFILE\flutter\bin\flutter.bat")) {
            if (Test-Path -LiteralPath $c) { $flutterPresent = $true; break }
        }
    }
    $p9 = ($devToolsOnRestrictedPath.Count -eq 0) -and
          ($l1.launch.restrictedPath -eq $expectedRestrictedPath) -and
          ($dash.dashboardTitleFound -eq $true) -and
          $flutterPresent
    Add-Gate 'P9' $p9 "app ran with restricted PATH (no SDK/toolchain), no missing runtime; flutter present on machine but not on restricted PATH"
} catch { Add-Gate 'P9' $false $_.Exception.Message }

# ---------------------------------------------------------------- P10
try {
    $dl = Read-Evidence '16-data-locations.json'
    $p10 = ($dl.dbWithinUserProfile -eq $true) -and
           ($dl.machineWide.hklmUninstallHits.Count -eq 0) -and
           ($dl.machineWide.hklmSoftwareMuaman.Count -eq 0) -and
           ($dl.machineWide.programDataMuamanHits.Count -eq 0)
    Add-Gate 'P10' $p10 "per-user data only: DB under fresh-user profile, no machine-wide registrations/data"
} catch { Add-Gate 'P10' $false $_.Exception.Message }

# ---------------------------------------------------------------- P11
try {
    $close = Read-Evidence '17-close1.json'
    $p11 = ($close.close.exited -eq $true) -and
           ($close.close.method -in @('WM_CLOSE','CloseMainWindow')) -and
           ($close.dbStillPresentAfterClose -eq $true) -and
           ($close.orphanProcessIds.Count -eq 0)
    Add-Gate 'P11' $p11 "clean close via $($close.close.method), no orphans, DB persisted"
} catch { Add-Gate 'P11' $false $_.Exception.Message }

# ---------------------------------------------------------------- P12
try {
    $l2 = Read-Evidence '18-launch2.json'
    $p12 = ($l2.loginScreenShown -eq $true) -and ($l2.dashboardReached -eq $true) -and
           ($null -ne $l2.databaseAfterSecondLogin) -and ($l2.close.exited -eq $true) -and
           ($l2.dbStillPresentAfterSecondClose -eq $true)
    Add-Gate 'P12' $p12 "second launch: login screen persisted, login -> dashboard, DB intact after second close"
} catch { Add-Gate 'P12' $false $_.Exception.Message }

# ---------------------------------------------------------------- P13
try {
    $ur = Read-Evidence '19-uninstall-registration.json'
    $p13 = ($ur.hkcuUninstallPresent -eq $true) -and ($ur.hklmUninstallHits.Count -eq 0) -and
           ($ur.uninstallNotExecuted_appExeStillPresent -eq $true) -and
           ($ur.uninstallNotExecuted_dbStillPresent -eq $true) -and
           ($ur.uninstallNotExecuted_installDirStillPresent -eq $true)
    Add-Gate 'P13' $p13 "uninstall registered per-user (HKCU only); uninstall NOT executed"
} catch { Add-Gate 'P13' $false $_.Exception.Message }

# ---------------------------------------------------------------- P14
try {
    $appDir = Join-Path $WorktreePath 'app'
    $flutterExe = (Get-Command flutter -ErrorAction SilentlyContinue).Source
    if (-not $flutterExe) {
        $candidates = @('C:\dev\flutter\bin\flutter.bat', 'C:\flutter\bin\flutter.bat', "$env:USERPROFILE\flutter\bin\flutter.bat")
        foreach ($c in $candidates) { if (Test-Path -LiteralPath $c) { $flutterExe = $c; break } }
    }
    if (-not $flutterExe) { throw 'flutter not found for P14' }

    $pubGetLog = Join-Path $RefDir 'p14-pubget.log'
    $analyzeLog = Join-Path $RefDir 'p14-analyze.log'
    $testLog = Join-Path $RefDir 'p14-test.log'

    # Drive flutter through generated batch files: the redirect lives inside the
    # .cmd (cmd merges stderr via 2>&1) so no `>` ever appears in a .NET
    # argument string, and the merged stream is captured by PowerShell's own *>
    # redirection without tripping $ErrorActionPreference=Stop on native stderr.
    foreach ($spec in @(
        @{ cmd = Join-Path $RefDir 'p14-pubget.cmd'; verb = 'pub get' },
        @{ cmd = Join-Path $RefDir 'p14-analyze.cmd'; verb = 'analyze' },
        @{ cmd = Join-Path $RefDir 'p14-test.cmd'; verb = 'test' }
    )) {
        $lines = "@echo off`r`n`"$flutterExe`" $($spec.verb) 2>&1`r`nexit /b %ERRORLEVEL%`r`n"
        [System.IO.File]::WriteAllText($spec.cmd, $lines, (New-Object System.Text.UTF8Encoding $false))
    }

    $pubGetCmd = Join-Path $RefDir 'p14-pubget.cmd'
    $analyzeCmd = Join-Path $RefDir 'p14-analyze.cmd'
    $testCmd = Join-Path $RefDir 'p14-test.cmd'

    Push-Location $appDir
    try {
        & cmd.exe /c $pubGetCmd *> $pubGetLog; $pubGetExit = $LASTEXITCODE
        & cmd.exe /c $analyzeCmd *> $analyzeLog; $analyzeExit = $LASTEXITCODE
        & cmd.exe /c $testCmd *> $testLog; $testExit = $LASTEXITCODE
    } finally {
        Pop-Location
    }

    $analyzeOut = if (Test-Path -LiteralPath $analyzeLog) { Get-Content -LiteralPath $analyzeLog -Raw } else { '' }
    $testOut = if (Test-Path -LiteralPath $testLog) { Get-Content -LiteralPath $testLog -Raw } else { '' }

    $analyzeClean = ($analyzeExit -eq 0) -and ($analyzeOut -match 'No issues found')
    $testPass = ($testExit -eq 0) -and ($testOut -match 'All tests passed')
    $testCountMatch = ($testOut -match '\+\s*(\d+)')

    # flutter pub get regenerates tracked platform plugin registrant files under
    # app/; restore the app tree so the worktree scope check only ever sees the
    # allowed prefixes.
    & git -C $WorktreePath checkout -- app 2>$null

    $gitViolations = $null
    $scopeOk = Test-GitCleanScope -RepoPath $WorktreePath -ExpectedHead $cfg.baselineCommit -AllowedPrefixes $cfg.allowedChangedPrefixes -Violations ([ref]$gitViolations)

    $p14 = $analyzeClean -and $testPass -and $scopeOk
    Add-Gate 'P14' $p14 "analyzeClean=$analyzeClean testPass=$testPass scopeOk=$scopeOk gitViolations=$($gitViolations -join ';')"
} catch { Add-Gate 'P14' $false $_.Exception.Message }

# ---------------------------------------------------------------- P15
# Regression: the row-based matcher must resolve every field of the RECORDED
# first-owner setup frame. This is the exact defect that killed the last run
# (the single-word matcher can never match the two-word label "اسم المستخدم").
# A reintroduced single-word matcher makes Resolve-OcrFieldRows return $null and
# this gate fails. OCR is deterministic on a stored frame.
try {
    $setupShot = Join-Path $shotsDir '11-launch1-setup-initial.png'
    $shotOk = Test-Path -LiteralPath $setupShot
    if (-not $shotOk) { throw 'setup screenshot missing from evidence' }
    $words = @(Invoke-OcrFile -Path $setupShot -LanguageTag 'ar-SA')
    $fdefs = [ordered]@{
        name = [ordered]@{ label = $U.setup.fieldName; value = $OwnerDisplayName }
        user = [ordered]@{ label = $U.setup.fieldUsername; value = $OwnerUsername }
        pass = [ordered]@{ label = $U.setup.fieldPassword; value = 'x'; secret = $true }
        confirm = [ordered]@{ label = $U.setup.fieldConfirmPassword; value = 'x'; secret = $true }
    }
    $resolved = Resolve-OcrFieldRows -Words $words -FieldDefs $fdefs
    $resolvedOk = ($null -ne $resolved)
    $nameTop = if ($resolvedOk) { [int]$resolved['name'].top } else { -1 }
    $userTop = if ($resolvedOk) { [int]$resolved['user'].top } else { -1 }
    $passTop = if ($resolvedOk) { [int]$resolved['pass'].top } else { -1 }
    $confirmTop = if ($resolvedOk) { [int]$resolved['confirm'].top } else { -1 }
    $ordered = $resolvedOk -and ($nameTop -lt $userTop) -and ($userTop -lt $passTop) -and ($passTop -lt $confirmTop)
    $userRows = @(Find-OcrLabelRows -Words $words -Parts @($U.setup.fieldUsername -split '\s+'))
    $pwRows = @(Find-OcrLabelRows -Words $words -Parts @($U.setup.fieldPassword -split '\s+'))
    $uniqueUser = ($userRows.Count -eq 1)
    $sharedPw = ($pwRows.Count -ge 2)
    $p15 = $shotOk -and $resolvedOk -and $ordered -and $uniqueUser -and $sharedPw
    Add-Gate 'P15' $p15 "row-based regression on recorded setup frame: words=$($words.Count) resolved=$resolvedOk tops=name/$nameTop user/$userTop pass/$passTop confirm/$confirmTop usernameRows=$($userRows.Count) passwordRows=$($pwRows.Count)"
} catch { Add-Gate 'P15' $false $_.Exception.Message }

# ---------------------------------------------------------------- P16
# Deterministic unit gates for the row targeting / focus / value / post-secret
# helpers, the fail-closed (no typing) behavior, and the secret-leak scan. All
# word sets are synthetic ASCII-safe constructions built from ui_strings so no
# real password is ever involved.
function New-OcrWord {
    param([Parameter(Mandatory = $true)][string]$Text, [int]$X, [int]$Y, [int]$W = 40, [int]$H = 22)
    return [pscustomobject]@{ Text = $Text; X = $X; Y = $Y; W = $W; H = $H }
}
function New-ResolvedRow {
    param($Words, [int]$Top, [int]$Bottom, [int]$Left, [int]$Right, [string]$Label)
    return [ordered]@{ label = $Label; words = @($Words); top = $Top; bottom = $Bottom; left = $Left; right = $Right }
}
function Test-ReasonsHas {
    param($Reasons, [string]$Sub)
    return (@($Reasons | Where-Object { $_.IndexOf($Sub, [System.StringComparison]::Ordinal) -ge 0 }).Count -gt 0)
}
try {
    $pw = 'a1b2c3d4e5f60718293a4b5c6d7e8f90x7K!'
    $fds = [ordered]@{
        name = [ordered]@{ label = $U.setup.fieldName; value = $OwnerDisplayName }
        user = [ordered]@{ label = $U.setup.fieldUsername; value = $OwnerUsername }
        pass = [ordered]@{ label = $U.setup.fieldPassword; value = $pw; secret = $true }
        confirm = [ordered]@{ label = $U.setup.fieldConfirmPassword; value = $pw; secret = $true }
    }
    $dnParts = @($OwnerDisplayName -split '\s+')
    $unLabel = @($U.setup.fieldUsername -split '\s+')
    $pwParts = @($U.setup.fieldPassword -split '\s+')
    $cnParts = @($U.setup.fieldConfirmPassword -split '\s+')
    $nmParts = @($U.setup.fieldName -split '\s+')
    $btnParts = @($U.setup.buttonCreateOwner -split '\s+')
    $title = [string]$U.setup.title

    # base pre-fill frame (name/user/pass/confirm + title/button decoys)
    $wBase = @(
        (New-OcrWord $title 700 260 60 20)
        (New-OcrWord $nmParts[0] 1320 379 44 22)
        (New-OcrWord $unLabel[0] 1333 454 71 27)
        (New-OcrWord $unLabel[1] 1230 456 90 22)
        (New-OcrWord $pwParts[1] 1330 535 90 18)
        (New-OcrWord $pwParts[0] 1373 539 36 13)
        (New-OcrWord $cnParts[0] 1325 615 38 23)
        (New-OcrWord $pwParts[1] 1330 617 90 18)
        (New-OcrWord $pwParts[0] 1373 621 36 13)
        (New-OcrWord $btnParts[0] 580 710 60 24)
        (New-OcrWord $btnParts[1] 650 710 60 24)
        (New-OcrWord $btnParts[2] 720 710 70 24)
    )
    $resBase = Resolve-OcrFieldRows -Words $wBase -FieldDefs $fds
    $resBaseOk = ($null -ne $resBase)
    $userRows = @(Find-OcrLabelRows -Words $wBase -Parts $unLabel)
    $pwRows = @(Find-OcrLabelRows -Words $wBase -Parts $pwParts)
    $uniqueUserOk = ($userRows.Count -eq 1)
    $sharedPwOk = ($pwRows.Count -eq 2)
    $orderedBase = $resBaseOk -and ([int]$resBase['name'].top -lt [int]$resBase['user'].top) -and
        ([int]$resBase['user'].top -lt [int]$resBase['pass'].top) -and ([int]$resBase['pass'].top -lt [int]$resBase['confirm'].top)

    # fail-closed: label split defect (username part missing) and out-of-order rows
    $wDefect = @($wBase | Where-Object { $_.Text -ne $unLabel[1] })
    $defectFailsClosed = ($null -eq (Resolve-OcrFieldRows -Words $wDefect -FieldDefs $fds))
    $wOoo = @($wBase)
    $wOoo = @($wOoo | ForEach-Object { if ($_.Text -eq $nmParts[0]) { New-OcrWord $_.Text 1320 500 44 22 } else { $_ } })
    $oooFailsClosed = ($null -eq (Resolve-OcrFieldRows -Words $wOoo -FieldDefs $fds))

    # focus assertion (label float = height shrink vs baseline)
    $baseRows = [ordered]@{
        name = New-ResolvedRow -Words @((New-OcrWord $nmParts[0] 1320 379 44 22)) -Top 379 -Bottom 401 -Left 1320 -Right 1364 -Label $U.setup.fieldName
        user = New-ResolvedRow -Words @((New-OcrWord $unLabel[0] 1333 454 71 27), (New-OcrWord $unLabel[1] 1230 456 90 22)) -Top 454 -Bottom 481 -Left 1230 -Right 1424 -Label $U.setup.fieldUsername
        pass = New-ResolvedRow -Words @((New-OcrWord $pwParts[1] 1330 535 90 18), (New-OcrWord $pwParts[0] 1373 539 36 13)) -Top 535 -Bottom 553 -Left 1330 -Right 1409 -Label $U.setup.fieldPassword
        confirm = New-ResolvedRow -Words @((New-OcrWord $cnParts[0] 1325 615 38 23), (New-OcrWord $pwParts[1] 1330 617 90 18), (New-OcrWord $pwParts[0] 1373 621 36 13)) -Top 615 -Bottom 638 -Left 1325 -Right 1409 -Label $U.setup.fieldConfirmPassword
    }
    $curUserFocused = [ordered]@{
        name = $baseRows.name
        user = New-ResolvedRow -Words @((New-OcrWord $unLabel[0] 1333 432 71 17), (New-OcrWord $unLabel[1] 1230 432 90 17)) -Top 432 -Bottom 449 -Left 1230 -Right 1424 -Label $U.setup.fieldUsername
        pass = $baseRows.pass
        confirm = $baseRows.confirm
    }
    $curUserNotFocused = [ordered]@{
        name = $baseRows.name
        user = $baseRows.user
        pass = New-ResolvedRow -Words @((New-OcrWord $pwParts[1] 1330 512 90 15), (New-OcrWord $pwParts[0] 1373 512 36 11)) -Top 512 -Bottom 527 -Left 1330 -Right 1409 -Label $U.setup.fieldPassword
        confirm = $baseRows.confirm
    }
    $focusUserOk = Test-OcrRowsFocused -Rows $curUserFocused -Baseline $baseRows -Key 'user' -FieldDefs $fds -FieldIndex 1
    $focusUserMiss = Test-OcrRowsFocused -Rows $curUserNotFocused -Baseline $baseRows -Key 'user' -FieldDefs $fds -FieldIndex 1
    $focusFirstOk = Test-OcrRowsFocused -Rows $baseRows -Baseline $baseRows -Key 'name' -FieldDefs $fds -FieldIndex 0
    $focusFirstWithSibling = Test-OcrRowsFocused -Rows $curUserFocused -Baseline $baseRows -Key 'name' -FieldDefs $fds -FieldIndex 0

    # value-in-band (own row below the floated label; Ordinal probe distinctness)
    $wUserTyped = @(
        (New-OcrWord $nmParts[0] 1320 379 44 22)
        (New-OcrWord $unLabel[0] 1333 432 71 17)
        (New-OcrWord $unLabel[1] 1230 432 90 17)
        (New-OcrWord 'wner13pO' 1280 454 90 24)
        (New-OcrWord $pwParts[1] 1330 535 90 18)
        (New-OcrWord $pwParts[0] 1373 539 36 13)
        (New-OcrWord $cnParts[0] 1325 615 38 23)
        (New-OcrWord $pwParts[1] 1330 617 90 18)
        (New-OcrWord $pwParts[0] 1373 621 36 13)
    )
    $resUserTyped = Resolve-OcrFieldRows -Words $wUserTyped -FieldDefs $fds
    $inBandOk = Test-OcrValueInBand -Rows @(ConvertTo-OcrRows -Words $wUserTyped) -Resolved $resUserTyped -FieldDefs $fds -Key 'user' -Probe '13p'
    $caseDistinct = (-not (Test-OcrValueInBand -Rows @(ConvertTo-OcrRows -Words $wUserTyped) -Resolved $resUserTyped -FieldDefs $fds -Key 'user' -Probe '13P'))
    $wLeak = @($wUserTyped | ForEach-Object { if ($_.Text -eq 'wner13pO') { New-OcrWord $_.Text 1280 560 90 24 } else { $_ } })
    $resLeak = Resolve-OcrFieldRows -Words $wLeak -FieldDefs $fds
    $leakDetected = (-not (Test-OcrValueInBand -Rows @(ConvertTo-OcrRows -Words $wLeak) -Resolved $resLeak -FieldDefs $fds -Key 'user' -Probe '13p'))

    # post-secret: masked passwords + values in place -> ok
    $dnParts = @($OwnerDisplayName -split '\s+')
    $wSecretOk = @(
        (New-OcrWord $nmParts[0] 1320 356 44 17)
        (New-OcrWord $dnParts[0] 1180 378 50 20)
        (New-OcrWord $dnParts[1] 1240 378 40 20)
        (New-OcrWord $unLabel[0] 1333 432 71 17)
        (New-OcrWord $unLabel[1] 1230 432 90 17)
        (New-OcrWord 'wner13pO' 1280 454 90 24)
        (New-OcrWord $pwParts[1] 1330 512 90 15)
        (New-OcrWord $pwParts[0] 1373 512 36 11)
        (New-OcrWord '*' 1280 532 20 24)
        (New-OcrWord $cnParts[0] 1325 615 38 23)
        (New-OcrWord $pwParts[1] 1330 617 90 18)
        (New-OcrWord $pwParts[0] 1373 621 36 13)
        (New-OcrWord '*' 1280 640 20 24)
        (New-OcrWord $btnParts[0] 580 710 60 24)
        (New-OcrWord $btnParts[1] 650 710 60 24)
        (New-OcrWord $btnParts[2] 720 710 70 24)
    )
    $secretProbe = Get-OcrValueProbe -Value $pw
    $checkOk = Test-OcrSecretPostWords -Words $wSecretOk -FieldDefs $fds -SecretProbe $secretProbe
    $secretOk = ($checkOk.ok -eq $true)

    # post-secret negatives: plaintext password, secret-probe leak, missing
    # username value, username contaminated into another field's band
    $wPlain = @($wSecretOk | ForEach-Object { if ($_.Text -eq '*') { New-OcrWord $pw 1280 532 400 24 } else { $_ } })
    $cPlain = Test-OcrSecretPostWords -Words $wPlain -FieldDefs $fds -SecretProbe $secretProbe
    $plainFail = ($cPlain.ok -eq $false) -and (Test-ReasonsHas $cPlain.reasons 'secret-not-masked-pass')

    $wProbeLeak = @($wSecretOk) + @(New-OcrWord 'xx7K!yy' 300 280 60 20)
    $cProbeLeak = Test-OcrSecretPostWords -Words $wProbeLeak -FieldDefs $fds -SecretProbe $secretProbe
    $probeLeakFail = ($cProbeLeak.ok -eq $false) -and (Test-ReasonsHas $cProbeLeak.reasons 'secret-probe-visible')

    $wMissUser = @($wSecretOk | Where-Object { $_.Text -ne 'wner13pO' })
    $cMissUser = Test-OcrSecretPostWords -Words $wMissUser -FieldDefs $fds -SecretProbe $secretProbe
    $missingUserFail = ($cMissUser.ok -eq $false) -and (Test-ReasonsHas $cMissUser.reasons 'expected-value-missing-in-user')

    $wContam = @($wSecretOk | ForEach-Object { if ($_.Text -eq 'wner13pO') { New-OcrWord $_.Text 1280 378 90 24 } else { $_ } })
    $cContam = Test-OcrSecretPostWords -Words $wContam -FieldDefs $fds -SecretProbe $secretProbe
    $contamFail = ($cContam.ok -eq $false) -and (Test-ReasonsHas $cContam.reasons 'value-contamination-user')

    # no persisted evidence may contain a plaintext owner-password frame
    # (32 lowercase hex digits + literal suffix)
    $leakFiles = @()
    foreach ($f in @(Get-ChildItem -LiteralPath $EvidenceRoot -Recurse -File -ErrorAction SilentlyContinue)) {
        if ($f.Extension.ToLowerInvariant() -notin @('.json', '.txt', '.log', '.ps1', '.cmd', '.md', '.xml')) { continue }
        if ([System.IO.File]::ReadAllText($f.FullName) -match '[0-9a-f]{32}x7K!') { $leakFiles += $f.FullName }
    }
    $noSecretLeak = ($leakFiles.Count -eq 0)

    $p16 = $resBaseOk -and $orderedBase -and $uniqueUserOk -and $sharedPwOk -and
           $defectFailsClosed -and $oooFailsClosed -and
           $focusUserOk -and (-not $focusUserMiss) -and $focusFirstOk -and (-not $focusFirstWithSibling) -and
           $inBandOk -and $caseDistinct -and $leakDetected -and
           $secretOk -and $plainFail -and $probeLeakFail -and $missingUserFail -and $contamFail -and
           $noSecretLeak
    Add-Gate 'P16' $p16 "row-target/focus/value/post-secret unit gates (resolve=$resBaseOk ordered=$orderedBase uniqueUser=$uniqueUserOk sharedPw=$sharedPwOk failClosed=$defectFailsClosed/$oooFailsClosed focus=$focusUserOk/$focusUserMiss/$focusFirstOk/$focusFirstWithSibling band=$inBandOk distinct=$caseDistinct leakDetect=$leakDetected secretOk=$secretOk plainFail=$plainFail probeLeak=$probeLeakFail missingUser=$missingUserFail contam=$contamFail evidenceSecretScan=$noSecretLeak leakFiles=$($leakFiles.Count))"
} catch { Add-Gate 'P16' $false $_.Exception.Message }

$allPass = (@($gates.Values | Where-Object { -not $_.pass }).Count -eq 0)
$result = [ordered]@{
    phase = 'MUAMAN-13P'
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
