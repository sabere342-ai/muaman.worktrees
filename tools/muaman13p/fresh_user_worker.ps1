# fresh_user_worker.ps1 - MUAMAN-13P worker.
# Runs AS the independent fresh standard user (launched by the orchestrator via
# CreateProcessWithLogonW). Performs: identity proof, tool isolation, silent
# install of the frozen installer with a restricted PATH, payload/shortcut/
# registry verification, first-launch UI automation (first-owner setup -> login
# -> dashboard), database + per-user data-location evidence, clean close,
# second launch, and uninstall-registration-only evidence.
#
# IMPORTANT: this file is ASCII-only. Arabic UI strings are read from ui_strings.json.
#
# Environment variables set by the orchestrator:
#   M13P_OWNER_DISPLAYNAME, M13P_OWNER_USERNAME, M13P_OWNER_PASSWORD, M13P_RESTRICTED_PATH

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$RunId,
    [Parameter(Mandatory = $true)][string]$ExpectedUserName,
    [Parameter(Mandatory = $true)][string]$InstallerPath,
    [Parameter(Mandatory = $true)][string]$WorkRoot,
    [Parameter(Mandatory = $true)][string]$EvidenceRoot,
    [Parameter(Mandatory = $true)][string]$UiStringsPath,
    [Parameter(Mandatory = $true)][string]$ConfigPath,
    [string]$ReferenceDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# The native window/OCR stack captures at physical pixel resolution when this
# process is DPI-aware; OCR word coordinates are then used 1:1 with the window
# rect (DpiScale=1.0). Must be set before common.ps1 loads M13PWinNative.
$env:M13P_DPI_AWARE = '1'

. (Join-Path $PSScriptRoot 'lib\common.ps1')

$LogFile = Join-Path $EvidenceRoot 'logs\worker.log'
$JsonDir = Join-Path $EvidenceRoot 'json'
$ShotsDir = Join-Path $EvidenceRoot 'shots'
$UiaDir = Join-Path $EvidenceRoot 'uia'
foreach ($d in @($JsonDir, $ShotsDir, $UiaDir, (Split-Path -Parent $LogFile))) {
    New-Item -ItemType Directory -Path $d -Force | Out-Null
}

function Log {
    param([string]$Message)
    $line = "$(Get-UtcString) $Message"
    Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8
    Write-Output $line
}

function Save-Json {
    param([string]$Name, $Object)
    Write-JsonUtf8 -Path (Join-Path $JsonDir $Name) -Object $Object
}

function Save-Uia {
    param([string]$Name, [string]$Text)
    [System.IO.File]::WriteAllText((Join-Path $UiaDir $Name), $Text, (New-Object System.Text.UTF8Encoding $false))
}

function Save-OcrDump {
    param([string]$Name, $Words)
    $sb = New-Object System.Text.StringBuilder
    foreach ($w in $Words) {
        [void]$sb.AppendLine(("{0}|x={1} y={2} w={3} h={4}" -f $w.Text, [int]$w.X, [int]$w.Y, [int]$w.W, [int]$w.H))
    }
    [System.IO.File]::WriteAllText((Join-Path $UiaDir $Name), $sb.ToString(), (New-Object System.Text.UTF8Encoding $false))
}

$steps = [ordered]@{}
$allFailed = @()
$capturedAtStart = Get-UtcString

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [scriptblock]$Body,
        [switch]$Fatal
    )
    try {
        $result = & $Body
        if ($null -eq $result) { $result = @{} }
        $steps[$Name] = [ordered]@{ ok = $true; at = Get-UtcString; result = $result }
        Log "[STEP:OK] $Name"
    } catch {
        $steps[$Name] = [ordered]@{ ok = $false; at = Get-UtcString; error = $_.Exception.Message }
        $script:allFailed += $Name
        Log "[STEP:FAIL] $Name :: $($_.Exception.Message)"
        if ($Fatal) { throw }
    }
}

try {

    Initialize-WinNative
    [void][M13PWinNative]::SetProcessDPIAware()
    Prevent-SystemSleep

    $cfg = Read-JsonUtf8 -Path $ConfigPath
    $U = Read-JsonUtf8 -Path $UiStringsPath

    $ownerDisplay = $env:M13P_OWNER_DISPLAYNAME
    $ownerUsername = $env:M13P_OWNER_USERNAME
    $ownerPassword = $env:M13P_OWNER_PASSWORD
    $restrictedPath = $env:M13P_RESTRICTED_PATH
    if (-not $ownerDisplay -or -not $ownerUsername -or -not $ownerPassword -or -not $restrictedPath) {
        throw 'Missing required environment variables (M13P_OWNER_* / M13P_RESTRICTED_PATH)'
    }

    $localAppData = $env:LOCALAPPDATA
    $appData = $env:APPDATA
    $userProfile = $env:USERPROFILE
    $installDir = Join-Path (Join-Path $localAppData 'Programs') $cfg.application.appDirName
    $appExe = Join-Path $installDir $cfg.application.mainExecutable
    $dbDir = Join-Path $installDir ($cfg.data.ffiDbRelDir -replace '/', '\')
    $dbPath = Join-Path $dbDir $cfg.data.dbFileName
    $uninstallKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\' + $cfg.application.appId + '_is1'

    Log "RUN BEGIN runId=$RunId user=$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) installDir=$installDir"

    # ---------------------------------------------------------------- identity
    Invoke-Step -Name 'identity' -Fatal {
        $id = Get-PrivateTokenFacts
        $groups = Get-WhoamiGroups
        $priv = Get-WhoamiPriv
        $integrity = Get-IntegrityLevel
        $elev = Test-ElevationViaToken
        $session = Get-SessionInfo
        $localUser = Get-LocalUser -Name $ExpectedUserName -ErrorAction SilentlyContinue
        $membership = @(Get-AccountGroupMembership -AccountName $ExpectedUserName)
        $forbiddenPrivs = Assert-NoAdminPrivileges -WhoamiPriv $priv
        $result = [ordered]@{
            whoamiUser = (& whoami) -join ''
            tokenName = $id.name
            tokenSid = $id.sid
            expectedUserName = $ExpectedUserName
            tokenNameMatchesExpected = ($id.name -like "*\$ExpectedUserName")
            localUserExists = ($null -ne $localUser)
            localUserSid = if ($localUser) { $localUser.SID.Value } else { $null }
            localUserEnabled = if ($localUser) { $localUser.Enabled } else { $null }
            groupMembership = $membership
            inAdministrators = ($membership -contains 'Administrators')
            integrity = $integrity
            elevation = $elev
            session = $session
            isInteractive = $id.isInteractive
            privilegeSummary = [ordered]@{
                fullText = $priv
                forbiddenEnabledPresent = $forbiddenPrivs
            }
            groupsText = $groups
        }
        Save-Json -Name '04-fresh-user-context.json' -Object $result
        $result
    }

    # ------------------------------------------------------- tool isolation
    Invoke-Step -Name 'toolIsolation' {
        $tools = @('flutter', 'dart', 'git', 'cmake', 'ninja', 'msbuild', 'dotnet', 'node', 'npm', 'java', 'python', 'go', 'rustc', 'cl', 'where', 'reg', 'msiexec', 'cscript')
        $normalEnvResolved = @{}
        $savedPath = $env:PATH
        foreach ($t in $tools) {
            $c = Get-Command $t -ErrorAction SilentlyContinue
            if ($c) { $normalEnvResolved[$t] = $c.Source }
        }
        $env:PATH = $restrictedPath
        $restrictedResolved = @{}
        foreach ($t in $tools) {
            $c = Get-Command $t -ErrorAction SilentlyContinue
            if ($c) { $restrictedResolved[$t] = $c.Source }
        }
        $env:PATH = $savedPath
        $devToolPresentOnMachineButNotOnRestrictedPath = @{}
        foreach ($t in $tools) {
            $normal = $normalEnvResolved[$t]
            if ($normal -and -not $restrictedResolved.ContainsKey($t)) {
                $devToolPresentOnMachineButNotOnRestrictedPath[$t] = $normal
            }
        }
        $result = [ordered]@{
            restrictedPathUsed = $restrictedPath
            normalEnvironmentResolved = $normalEnvResolved
            restrictedEnvironmentResolved = $restrictedResolved
            devToolsPresentOnMachineButNotOnRestrictedPath = $devToolPresentOnMachineButNotOnRestrictedPath
            appRuntimeToolDeps = @()
        }
        Save-Json -Name '05-tool-isolation.json' -Object $result
        $result
    }

    # -------------------------------------------------------- account reset
    # The acceptance runs on a dedicated account that persists across runs, so a
    # previous run's residue (install dir, DB, HKCU uninstall key, start-menu
    # link) must be removed before install. Otherwise a stale muaman_store.db
    # makes hasAnyUser() return true and the app skips first-owner setup.
    Invoke-Step -Name 'accountReset' -Fatal {
        $startMenuLink = Join-Path (Join-Path $appData $cfg.shortcut.startMenuDir) $cfg.shortcut.startMenuName
        $before = [ordered]@{
            installDirExists = Test-Path -LiteralPath $installDir
            dbExists = Test-Path -LiteralPath $dbPath
            hkcuUninstallKeyExists = Test-Path -LiteralPath $uninstallKey
            startMenuLinkExists = Test-Path -LiteralPath $startMenuLink
        }
        Get-Process -Name ([System.IO.Path]::GetFileNameWithoutExtension($cfg.application.mainExecutable)) -ErrorAction SilentlyContinue |
            Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        foreach ($target in @($installDir, $uninstallKey, $startMenuLink)) {
            if (-not (Test-Path -LiteralPath $target)) { continue }
            for ($attempt = 1; $attempt -le 5; $attempt++) {
                try {
                    Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction Stop
                    break
                } catch {
                    if ($attempt -eq 5) { throw }
                    Start-Sleep -Milliseconds 1000
                }
            }
        }
        $after = [ordered]@{
            installDirExists = Test-Path -LiteralPath $installDir
            dbExists = Test-Path -LiteralPath $dbPath
            hkcuUninstallKeyExists = Test-Path -LiteralPath $uninstallKey
            startMenuLinkExists = Test-Path -LiteralPath $startMenuLink
        }
        $result = [ordered]@{
            before = $before
            after = $after
            resetOk = (-not $after.installDirExists) -and (-not $after.dbExists) -and
                      (-not $after.hkcuUninstallKeyExists) -and (-not $after.startMenuLinkExists)
        }
        Save-Json -Name '05a-account-reset.json' -Object $result
        if (-not $result.resetOk) { throw 'account reset failed: leftover app state still present' }
        $result
    }

    # ---------------------------------------------------------- pre-state
    Invoke-Step -Name 'prestate' {
        $result = [ordered]@{
            installDirExistsBeforeInstall = Test-Path -LiteralPath $installDir
            localAppData = $localAppData
            appData = $appData
            userProfile = $userProfile
            userProfileDirExists = Test-Path -LiteralPath $userProfile
            installDirListing = Get-DirListing -Root $installDir
            localAppDataListing = Get-DirListing -Root $localAppData
        }
        Save-Json -Name '06-prestate.json' -Object $result
        $result
    }

    # ------------------------------------------------------------- install
    Invoke-Step -Name 'install' -Fatal {
        $installLog = Join-Path (Split-Path -Parent $LogFile) 'install.log'
        $envMap = New-RestrictedEnvironment -RestrictedPath $restrictedPath
        $start = Get-Date
        $args = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /LOG="' + $installLog + '"'
        $r = Start-ChildProcess -FilePath $InstallerPath -Arguments $args -WorkingDir $installDir -Environment $envMap -TimeoutMs 300000
        $durationSec = [math]::Round(((Get-Date) - $start).TotalSeconds, 1)
        $installedExists = Test-Path -LiteralPath $appExe
        $result = [ordered]@{
            commandLine = "`"$InstallerPath`" $args"
            exitCode = $r.exitCode
            timedOut = $r.timedOut
            durationSec = $durationSec
            installLogPath = $installLog
            installLogBytes = if (Test-Path -LiteralPath $installLog) { (Get-Item -LiteralPath $installLog).Length } else { 0 }
            appExeExists = $installedExists
            installDir = $installDir
        }
        Save-Json -Name '07-install-run.json' -Object $result
        if ($r.timedOut -or $r.exitCode -ne 0 -or -not $installedExists) {
            throw "install failed: exit=$($r.exitCode) timedOut=$($r.timedOut) appExeExists=$installedExists"
        }
        $result
    }

    # ------------------------------------------- registry / shortcuts / payload
    Invoke-Step -Name 'installedState' -Fatal {
        $startMenuLink = Join-Path (Join-Path $appData $cfg.shortcut.startMenuDir) $cfg.shortcut.startMenuName
        $machineStartMenuLink = Join-Path (Join-Path $env:ProgramData $cfg.shortcut.machineStartMenuDir) $cfg.shortcut.startMenuName

        $hkcuUninstall = $null
        $uninstallKeyMatched = $null
        foreach ($candidateKey in @($uninstallKey, ('HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{' + $cfg.application.appId + '}_is1'))) {
            try { $hkcuUninstall = Get-ItemProperty -LiteralPath $candidateKey -ErrorAction Stop } catch {}
            if ($hkcuUninstall) { $uninstallKeyMatched = $candidateKey; break }
        }
        $hkcuUninstallProps = $null
        if ($hkcuUninstall) {
            $hkcuUninstallProps = [ordered]@{}
            $hkcuUninstall.PSObject.Properties | ForEach-Object {
                if ($_.Name -notlike 'PS*') { $hkcuUninstallProps[$_.Name] = [string]$_.Value }
            }
        }

        $hklmUninstallHits = @()
        $hklmKeys = @('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
                      'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')
        foreach ($pattern in $hklmKeys) {
            Get-Item -Path $pattern -ErrorAction SilentlyContinue | ForEach-Object {
                $child = $_.PSChildName
                $display = $null
                try { $display = [string](Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue).DisplayName } catch {}
                if ($child -like '*muaman*' -or ($display -like '*muaman*') -or ($display -like '*I-TECH*')) { $hklmUninstallHits += $child }
            }
        }

        $autorun = [ordered]@{}
        $autorunScopes = [ordered]@{
            'HKLM\Run' = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run'
            'HKLM\RunOnce' = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
            'HKCU\Run' = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
            'HKCU\RunOnce' = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
        }
        foreach ($scopeName in $autorunScopes.Keys) {
            $hits = @()
            try {
                $k = Get-Item -LiteralPath $autorunScopes[$scopeName] -ErrorAction SilentlyContinue
                if ($k) {
                    $k.Property | Where-Object { $_ -like '*muaman*' -or $_ -like '*I-TECH*' } | ForEach-Object { $hits += $_ }
                }
            } catch {}
            $autorun[$scopeName] = $hits
        }
        $startupFolders = @()
        foreach ($sf in @((Join-Path $appData 'Microsoft\Windows\Start Menu\Programs\Startup'),
                          (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\Startup'))) {
            if (Test-Path -LiteralPath $sf) {
                Get-ChildItem -LiteralPath $sf -File -ErrorAction SilentlyContinue | ForEach-Object {
                    if ($_.Name -like '*muaman*') { $startupFolders += $_.FullName }
                }
            }
        }

        $result = [ordered]@{
            uninstallKeyPath = $uninstallKey
            uninstallKeyMatched = $uninstallKeyMatched
            hkcuUninstallPresent = ($null -ne $hkcuUninstall)
            hkcuUninstall = $hkcuUninstallProps
            hklmUninstallHits = $hklmUninstallHits
            startMenuLink = $startMenuLink
            startMenuLinkExists = Test-Path -LiteralPath $startMenuLink
            machineStartMenuLink = $machineStartMenuLink
            machineStartMenuLinkExists = Test-Path -LiteralPath $machineStartMenuLink
            startMenuShortcutTarget = if (Test-Path -LiteralPath $startMenuLink) {
                $resolved = $null
                try {
                    # WScript.Shell mangles non-ASCII (Arabic) shortcut names;
                    # Shell.Application resolves them correctly.
                    $shellApp = New-Object -ComObject Shell.Application
                    $ns = $shellApp.NameSpace((Split-Path $startMenuLink))
                    $item = $ns.ParseName((Split-Path $startMenuLink -Leaf))
                    if ($item) {
                        $link = $item.GetLink()
                        if ($link) { $resolved = $link.Path }
                    }
                } catch {}
                if (-not $resolved) {
                    $sh = New-Object -ComObject WScript.Shell
                    $resolved = $sh.CreateShortcut($startMenuLink).TargetPath
                }
                $resolved
            } else { $null }
            autorun = $autorun
            startupFolderHits = $startupFolders
        }
        Save-Json -Name '08-install-registry.json' -Object $result
        $result
    }

    Invoke-Step -Name 'installedPayload' -Fatal {
        $installed = Get-DirListing -Root $installDir -IncludeSha
        $manifest13k = Read-JsonUtf8 -Path (Join-Path $ReferenceDir 'release-manifest.json')
        $contract13n = Read-JsonUtf8 -Path (Join-Path $ReferenceDir '03-muaman13n-release-contract.json')

        $manifestMap = @{}
        foreach ($f in $manifest13k.files) { $manifestMap[$f.rel] = $f }
        $contractExeSha = $contract13n.application.executableSha256
        $contractExeSize = $contract13n.application.executableSize

        $payload = @()
        $unexpected = @()
        $installedMap = @{}
        foreach ($f in $installed) { $installedMap[$f.rel -replace '\\', '/'] = $f }

        foreach ($f in $manifest13k.files) {
            $match = $false
            if ($installedMap.ContainsKey($f.rel)) {
                $match = ($installedMap[$f.rel].size -eq $f.size) -and
                         ($installedMap[$f.rel].sha256 -eq $f.sha256)
            }
            $payload += [ordered]@{ rel = $f.rel; expectedSize = $f.size; expectedSha256 = $f.sha256; installedSize = $installedMap[$f.rel].size; installedSha256 = $installedMap[$f.rel].sha256; match = $match }
        }
        $innoExtras = @('unins000.exe', 'unins000.dat', 'unins000.msg', 'unins000.shl')
        foreach ($f in $installed) {
            $rel = $f.rel -replace '\\', '/'
            $isPayload = $manifestMap.ContainsKey($rel)
            $isInnoExtra = $innoExtras -contains $rel
            if (-not $isPayload -and -not $isInnoExtra) {
                $unexpected += $rel
            }
        }

        $installedExe = $installedMap[$contract13n.application.mainExecutable]
        $result = [ordered]@{
            installDir = $installDir
            payloadFileCountExpected = $manifest13k.fileCount
            payloadFileCountInstalled = $payload.Count
            payloadAllMatch = (@($payload | Where-Object { -not $_.match }).Count -eq 0)
            payload = $payload
            innoUninstallerExtrasPresent = @($innoExtras | Where-Object { $installedMap.ContainsKey($_) })
            unexpectedFiles = $unexpected
            mainExecutable = $contract13n.application.mainExecutable
            exeSizeMatch = ($installedExe.size -eq $contractExeSize)
            exeSha256Match = ($installedExe.sha256 -eq $contractExeSha)
            exeInstalledSize = $installedExe.size
            exeInstalledSha256 = $installedExe.sha256
            flutterWindowsDllSha256 = $installedMap['flutter_windows.dll'].sha256
        }
        Save-Json -Name '09-installed-payload.json' -Object $result
        if (-not $result.payloadAllMatch) { throw 'payload mismatch' }
        $result
    }

    # ------------------------------------------------------ first launch
    $launch1 = $null
    Invoke-Step -Name 'launch1' -Fatal {
        $envMap = New-RestrictedEnvironment -RestrictedPath $restrictedPath
        $start = Get-Date
        $lw = Get-LaunchWindow -Exe $appExe -WorkDir $installDir -Environment $envMap -TimeoutSec $cfg.launchTimeoutsSec.windowFirst
        $proc = $lw.proc
        $handle = $lw.handle
        $windowFound = $lw.windowFound
        $windowFacts = $null
        if ($windowFound) {
            $windowFacts = Get-WindowFacts -Handle $handle
            $windowFacts['rect'] = Get-WindowRectOut -Handle $handle
            $shot = Join-Path $ShotsDir '10-launch1-first-window.png'
            Capture-WindowPng -Handle $handle -File $shot | Out-Null
            $windowFacts['firstScreenshot'] = $shot
        }
        $result = [ordered]@{
            launch = [ordered]@{
                exe = $appExe
                workingDirectory = $installDir
                restrictedPath = $restrictedPath
                startedAtUtc = (Get-UtcString)
                processId = $proc.Id
                sessionId = $proc.SessionId
                secondsToWindow = [math]::Round(((Get-Date) - $start).TotalSeconds, 1)
                windowFound = $windowFound
                window = $windowFacts
            }
        }
        Save-Json -Name '10-launch1-window.json' -Object $result
        if (-not $windowFound) { throw 'first launch: no main window' }
        $script:launch1 = [ordered]@{ handle = $handle; proc = $proc; result = $result }
        $result
    }

    Invoke-Step -Name 'launch1Setup' -Fatal {
        $h = $script:launch1.handle
        $shot = Join-Path $ShotsDir '11-launch1-setup-initial.png'
        $capNote = Capture-AppWindowPng -Handle $h -File $shot
        $words = @(Invoke-OcrFile -Path $shot -LanguageTag 'ar-SA')
        Save-OcrDump -Name '11-launch1-setup-initial.txt' -Words $words
        $titleHit = Find-OcrWordByParts -Words $words -Parts @($U.setup.title -split '\s+')
        $fields = Get-OcrFields -PngPath $shot -FieldLabels ([ordered]@{
            name = $U.setup.fieldName
            user = $U.setup.fieldUsername
            pass = $U.setup.fieldPassword
            confirm = $U.setup.fieldConfirmPassword
        })
        $setupTitleFound = ($null -ne $titleHit)
        $fieldsFound = ($null -ne $fields['name']) -and ($null -ne $fields['user']) -and ($null -ne $fields['pass']) -and ($null -ne $fields['confirm'])
        $result = [ordered]@{
            screenshot = $shot
            captureNote = $capNote
            ocrDumpFile = '11-launch1-setup-initial.txt'
            wordCount = $words.Count
            setupTitleFound = $setupTitleFound
            fieldsFound = $fieldsFound
            fields = $fields
        }
        Save-Json -Name '11-launch1-setup.json' -Object $result
        if (-not ($setupTitleFound -and $fieldsFound)) {
            throw 'first-owner setup screen not recognized via OCR'
        }
        $result
    }

    Invoke-Step -Name 'launch1OwnerCreate' -Fatal {
        $h = $script:launch1.handle
        $fieldDefs = [ordered]@{
            name = [ordered]@{ label = $U.setup.fieldName; value = $ownerDisplay }
            user = [ordered]@{ label = $U.setup.fieldUsername; value = $ownerUsername }
            pass = [ordered]@{ label = $U.setup.fieldPassword; value = $ownerPassword; secret = $true }
            confirm = [ordered]@{ label = $U.setup.fieldConfirmPassword; value = $ownerPassword; secret = $true }
        }
        $methods = Invoke-OcrFieldFlow -Handle $h -FieldDefs $fieldDefs -ShotDir $ShotsDir -Tag '12'
        $btnParts = @($U.setup.buttonCreateOwner -split '\s+')
        # This frame is post-password, so the button capture is transient and
        # never persisted; the masked state was already verified by the flow.
        $btn = Click-OcrButtonByParts -Handle $h -Parts $btnParts -ShotDir $ShotsDir -Tag '12b' -Transient
        if (-not $btn.clicked) { throw 'create-owner button not found via OCR' }
        $result = [ordered]@{
            methods = $methods
            button = $btn
        }
        Save-Json -Name '12-launch1-setup-filled.json' -Object $result
        $result
    }

    Invoke-Step -Name 'launch1Login' -Fatal {
        $h = $script:launch1.handle
        $loginTitleFound = $false
        $loginButtonFound = $false
        $words = @()
        $shot = $null
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        while ($sw.Elapsed.TotalSeconds -lt $cfg.launchTimeoutsSec.screenTransition) {
            $shot = Join-Path $ShotsDir '13-launch1-login.png'
            $capNote = Capture-AppWindowPng -Handle $h -File $shot
            $words = @(Invoke-OcrFile -Path $shot -LanguageTag 'ar-SA')
            $titleHit = Find-OcrWordByParts -Words $words -Parts @($U.login.title -split '\s+')
            $btnHit = Find-OcrWordByParts -Words $words -Parts @($U.login.buttonLogin -split '\s+')
            $loginTitleFound = ($null -ne $titleHit)
            $loginButtonFound = ($null -ne $btnHit)
            if ($loginTitleFound -and $loginButtonFound) { break }
            Start-Sleep -Milliseconds 800
        }
        if (-not ($loginTitleFound -and $loginButtonFound)) { throw 'login screen not reached after owner creation' }
        Save-OcrDump -Name '13-launch1-login.txt' -Words $words

        $fieldDefs = [ordered]@{
            user = [ordered]@{ label = $U.login.fieldUsername; value = $ownerUsername }
            pass = [ordered]@{ label = $U.login.fieldPassword; value = $ownerPassword; secret = $true }
        }
        $methods = Invoke-OcrFieldFlow -Handle $h -FieldDefs $fieldDefs -ShotDir $ShotsDir -Tag '13'
        $btnParts = @($U.login.buttonLogin -split '\s+')
        $btn = Click-OcrButtonByParts -Handle $h -Parts $btnParts -ShotDir $ShotsDir -Tag '13b' -Transient
        if (-not $btn.clicked) { throw 'login button not found via OCR' }
        $methods[$U.login.buttonLogin] = "ClickAt+TypeText($($btn.word)) try=$($btn.try)"

        $result = [ordered]@{
            loginTitleFound = $loginTitleFound
            loginButtonFound = $loginButtonFound
            methods = $methods
            button = $btn
            ocrDumpFile = '13-launch1-login.txt'
            screenshot = $shot
        }
        Save-Json -Name '13-launch1-login.json' -Object $result
        $result
    }

    Invoke-Step -Name 'launch1Dashboard' -Fatal {
        $h = $script:launch1.handle
        $foundDashboard = $false
        $words = @()
        $shot = $null
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        while ($sw.Elapsed.TotalSeconds -lt $cfg.launchTimeoutsSec.screenTransition) {
            $shot = Join-Path $ShotsDir '14-launch1-dashboard.png'
            $capNote = Capture-AppWindowPng -Handle $h -File $shot
            $words = @(Invoke-OcrFile -Path $shot -LanguageTag 'ar-SA')
            $titleHit = Find-OcrWordByParts -Words $words -Parts @($U.dashboard.title -split '\s+')
            $navHit = Find-OcrWordByParts -Words $words -Parts @($U.dashboard.navSales -split '\s+')
            if ($null -ne $titleHit -or $null -ne $navHit) { $foundDashboard = $true; break }
            Start-Sleep -Milliseconds 800
        }
        if (-not $foundDashboard) {
            Save-OcrDump -Name '14-launch1-dashboard.txt' -Words $words
            throw 'dashboard not reached after login'
        }
        Save-OcrDump -Name '14-launch1-dashboard.txt' -Words $words
        $ownerParts = @($ownerDisplay -split '\s+')
        $ownerHits = [ordered]@{}
        foreach ($p in $ownerParts) {
            $ownerHits[$p] = @($words | Where-Object { $_.Text -like "*$p*" }).Count
        }
        $result = [ordered]@{
            dashboardTitleFound = $foundDashboard
            ocrDumpFile = '14-launch1-dashboard.txt'
            screenshot = $shot
            ownerDisplayName = $ownerDisplay
            ownerDisplayNamePartHits = $ownerHits
        }
        Save-Json -Name '14-launch1-dashboard.json' -Object $result
        $result
    }

    Invoke-Step -Name 'database' -Fatal {
        # The app keeps its SQLite file open for its whole lifetime, so it must
        # be closed before the DB can be read; close1 below then only verifies
        # the already-exited process.
        $dbClose = Close-WindowGracefully -Handle $script:launch1.handle -Process $script:launch1.proc -TimeoutSec $cfg.launchTimeoutsSec.close
        Start-Sleep -Seconds 2
        $dbExists = Test-Path -LiteralPath $dbPath
        $dbFacts = $null
        if ($dbExists) {
            $bytes = [System.IO.File]::ReadAllBytes($dbPath)
            $header = [System.Text.Encoding]::ASCII.GetString($bytes, 0, [Math]::Min(16, $bytes.Length))
            $isSqlite = ($header -eq 'SQLite format 3' -and $bytes.Length -gt 15 -and $bytes[15] -eq 0)
            $latin = [System.Text.Encoding]::GetEncoding(28591).GetString($bytes)
            $tables = @()
            foreach ($t in @('products','sales','returns','expenses','inventory_count','users','import_batches','invoices','app_settings')) {
                if ($latin.Contains($t)) { $tables += $t }
            }
            $ownerUsernameBytes = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::UTF8.GetBytes($ownerUsername.ToLowerInvariant()))
            $ownerUsernamePresent = $latin.Contains($ownerUsernameBytes)
            $ownerDisplayPresent = $latin.Contains($ownerDisplay)
            $dbFacts = [ordered]@{
                path = $dbPath
                sizeBytes = $bytes.Length
                sha256 = (Get-FileSha256 -Path $dbPath)
                sqliteHeaderValid = $isSqlite
                tablesFound = $tables
                ownerUsernameTextPresent = $ownerUsernamePresent
                ownerDisplayNameTextPresent = $ownerDisplayPresent
                lastWriteTimeUtc = (Get-Item -LiteralPath $dbPath).LastWriteTimeUtc.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            }
        }
        $result = [ordered]@{
            dbPath = $dbPath
            dbExists = $dbExists
            closeBeforeDb = $dbClose
            db = $dbFacts
        }
        Save-Json -Name '15-database.json' -Object $result
        if (-not ($dbExists -and $dbFacts.sqliteHeaderValid -and ($dbFacts.tablesFound -contains 'users'))) {
            throw 'business database not created correctly'
        }
        $result
    }

    Invoke-Step -Name 'dataLocations' {
        $beforeLocal = Get-DirListing -Root $localAppData -IncludeSha
        $beforeAppData = Get-DirListing -Root $appData -IncludeSha
        $afterLocal = Get-DirListing -Root $localAppData -IncludeSha
        $afterAppData = Get-DirListing -Root $appData -IncludeSha
        $programDataMuamanHits = @()
        if (Test-Path -LiteralPath $env:ProgramData) {
            # C:\ProgramData\Microsoft\User Account Pictures\*.dat is an OS-created
            # per-account picture placeholder (its name contains the account name),
            # NOT app-created machine-wide state; exclude it from the scan.
            Get-ChildItem -LiteralPath $env:ProgramData -Recurse -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like '*muaman*' -and $_.FullName -notlike '*\Microsoft\User Account Pictures\*' } |
                ForEach-Object { $programDataMuamanHits += $_.FullName }
        }
        $machineWideChecks = [ordered]@{
            hklmUninstallHits = @()
            hklmSoftwareMuaman = @()
            programDataMuamanHits = $programDataMuamanHits
        }
        Get-ChildItem -LiteralPath 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall' -ErrorAction SilentlyContinue |
            Where-Object { $_.PSChildName -like '*muaman*' } | ForEach-Object { $machineWideChecks.hklmUninstallHits += $_.PSChildName }
        Get-ChildItem -LiteralPath 'HKLM:\Software\Microsoft\Windows\CurrentVersion' -ErrorAction SilentlyContinue |
            Where-Object { $_.PSChildName -like '*muaman*' } | ForEach-Object { $machineWideChecks.hklmSoftwareMuaman += $_.PSChildName }
        $result = [ordered]@{
            localAppDataDelta = (Diff-DirListings -Before $beforeLocal -After $afterLocal)
            appDataDelta = (Diff-DirListings -Before $beforeAppData -After $afterAppData)
            machineWide = $machineWideChecks
            dbWithinUserProfile = ($dbPath.StartsWith($userProfile, [System.StringComparison]::OrdinalIgnoreCase))
            userProfile = $userProfile
            userProfileDirCreatedAtUtc = if (Test-Path -LiteralPath $userProfile) { (Get-Item -LiteralPath $userProfile).CreationTimeUtc.ToString('yyyy-MM-ddTHH:mm:ss.fffZ') } else { $null }
        }
        Save-Json -Name '16-data-locations.json' -Object $result
        $result
    }

    Invoke-Step -Name 'close1' -Fatal {
        $h = $script:launch1.handle
        $proc = $script:launch1.proc
        $closeResult = Close-WindowGracefully -Handle $h -Process $proc -TimeoutSec $cfg.launchTimeoutsSec.close
        Start-Sleep -Seconds 2
        $orphans = @(Get-Process -Name 'muaman_store' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)
        $result = [ordered]@{
            close = $closeResult
            dbStillPresentAfterClose = Test-Path -LiteralPath $dbPath
            orphanProcessIds = $orphans
        }
        Save-Json -Name '17-close1.json' -Object $result
        if (-not $closeResult.exited) { throw 'app did not exit after WM_CLOSE' }
        $result
    }

    # ------------------------------------------------------ second launch
    $launch2 = $null
    Invoke-Step -Name 'launch2' -Fatal {
        $dbShaBefore = Get-FileSha256 -Path $dbPath
        $envMap = New-RestrictedEnvironment -RestrictedPath $restrictedPath
        $start = Get-Date
        $lw = Get-LaunchWindow -Exe $appExe -WorkDir $installDir -Environment $envMap -TimeoutSec $cfg.launchTimeoutsSec.windowSubsequent
        $proc = $lw.proc
        $handle = $lw.handle
        if (-not $lw.windowFound) { throw 'second launch: no main window' }
        $windowFacts = Get-WindowFacts -Handle $handle
        $windowFacts['rect'] = Get-WindowRectOut -Handle $handle
        $shot = Join-Path $ShotsDir '18-launch2-window.png'
        Capture-WindowPng -Handle $handle -File $shot | Out-Null

        # login screen should be shown directly (per-user DB persisted)
        $loginScreenShown = $false
        $wordsLogin = @()
        $shotLogin = $null
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        while ($sw.Elapsed.TotalSeconds -lt $cfg.launchTimeoutsSec.screenTransition) {
            $shotLogin = Join-Path $ShotsDir '18-launch2-login.png'
            $capNote = Capture-AppWindowPng -Handle $handle -File $shotLogin
            $wordsLogin = @(Invoke-OcrFile -Path $shotLogin -LanguageTag 'ar-SA')
            $titleHit = Find-OcrWordByParts -Words $wordsLogin -Parts @($U.login.title -split '\s+')
            $btnHit = Find-OcrWordByParts -Words $wordsLogin -Parts @($U.login.buttonLogin -split '\s+')
            if ($null -ne $titleHit -and $null -ne $btnHit) { $loginScreenShown = $true; break }
            Start-Sleep -Milliseconds 800
        }
        Save-OcrDump -Name '18-launch2-login.txt' -Words $wordsLogin
        if (-not $loginScreenShown) {
            try { $proc.Kill() } catch {}
            throw 'second launch: login screen not shown (data not persisted)'
        }

        $fieldDefs = [ordered]@{
            user = [ordered]@{ label = $U.login.fieldUsername; value = $ownerUsername }
            pass = [ordered]@{ label = $U.login.fieldPassword; value = $ownerPassword; secret = $true }
        }
        $loginMethods = Invoke-OcrFieldFlow -Handle $handle -FieldDefs $fieldDefs -ShotDir $ShotsDir -Tag '18'
        $btnParts = @($U.login.buttonLogin -split '\s+')
        $btn = Click-OcrButtonByParts -Handle $handle -Parts $btnParts -ShotDir $ShotsDir -Tag '18b' -Transient
        if (-not $btn.clicked) { try { $proc.Kill() } catch {}; throw 'second launch: login button not found via OCR' }
        $loginMethods[$U.login.buttonLogin] = "ClickAt+TypeText($($btn.word)) try=$($btn.try)"

        $dashboardReached = $false
        $wordsDash = @()
        $shotDash = $null
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        while ($sw.Elapsed.TotalSeconds -lt $cfg.launchTimeoutsSec.screenTransition) {
            $shotDash = Join-Path $ShotsDir '19-launch2-dashboard.png'
            $capNote = Capture-AppWindowPng -Handle $handle -File $shotDash
            $wordsDash = @(Invoke-OcrFile -Path $shotDash -LanguageTag 'ar-SA')
            $titleHit = Find-OcrWordByParts -Words $wordsDash -Parts @($U.dashboard.title -split '\s+')
            $navHit = Find-OcrWordByParts -Words $wordsDash -Parts @($U.dashboard.navSales -split '\s+')
            if ($null -ne $titleHit -or $null -ne $navHit) { $dashboardReached = $true; break }
            Start-Sleep -Milliseconds 800
        }
        if (-not $dashboardReached) {
            try { $proc.Kill() } catch {}
            throw 'second launch: dashboard not reached after login'
        }
        Save-OcrDump -Name '19-launch2-dashboard.txt' -Words $wordsDash

        $dbAfter = $null
        $result = [ordered]@{
            window = $windowFacts
            windowScreenshot = $shot
            loginScreenShown = $loginScreenShown
            loginMethods = $loginMethods
            loginButton = $btn
            dashboardReached = $dashboardReached
            loginScreenshot = $shotLogin
            dashboardScreenshot = $shotDash
            databaseBeforeSecondLaunch = [ordered]@{ sizeBytes = (Get-Item -LiteralPath $dbPath).Length; sha256 = $dbShaBefore }
        }
        Save-Json -Name '18-launch2.json' -Object $result

        # The relaunched app holds the DB for its whole lifetime, so the
        # after-login DB facts are captured only after the app has closed.
        $closeResult = Close-WindowGracefully -Handle $handle -Process $proc -TimeoutSec $cfg.launchTimeoutsSec.close
        Start-Sleep -Seconds 2
        if (Test-Path -LiteralPath $dbPath) {
            $dbAfter = [ordered]@{
                sizeBytes = (Get-Item -LiteralPath $dbPath).Length
                sha256 = Get-FileSha256 -Path $dbPath
                lastWriteTimeUtc = (Get-Item -LiteralPath $dbPath).LastWriteTimeUtc.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            }
        }
        $orphans = @(Get-Process -Name 'muaman_store' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)
        $result['databaseAfterSecondLogin'] = $dbAfter
        $result['close'] = $closeResult
        $result['dbStillPresentAfterSecondClose'] = Test-Path -LiteralPath $dbPath
        $result['orphanProcessIds'] = $orphans
        Save-Json -Name '18-launch2.json' -Object $result
        $script:launch2 = $result
        $result
    }

    # --------------------------------------- uninstall registration only
    Invoke-Step -Name 'uninstallRegistration' {
        $hkcu = $null
        foreach ($candidateKey in @($uninstallKey, ('HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{' + $cfg.application.appId + '}_is1'))) {
            try { $hkcu = Get-ItemProperty -LiteralPath $candidateKey -ErrorAction Stop } catch {}
            if ($hkcu) { break }
        }
        $props = $null
        if ($hkcu) {
            $props = [ordered]@{}
            $hkcu.PSObject.Properties | ForEach-Object {
                if ($_.Name -notlike 'PS*') { $props[$_.Name] = [string]$_.Value }
            }
        }
        $hklmHits = @()
        foreach ($pattern in @('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
                               'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')) {
            Get-Item -Path $pattern -ErrorAction SilentlyContinue | ForEach-Object {
                $child = $_.PSChildName
                $display = $null
                try { $display = [string](Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue).DisplayName } catch {}
                if ($child -like '*muaman*' -or ($display -like '*muaman*') -or ($display -like '*I-TECH*')) { $hklmHits += $child }
            }
        }
        $result = [ordered]@{
            hkcuUninstallPresent = ($null -ne $hkcu)
            hkcuUninstall = $props
            hklmUninstallHits = $hklmHits
            uninstallNotExecuted_appExeStillPresent = Test-Path -LiteralPath $appExe
            uninstallNotExecuted_dbStillPresent = Test-Path -LiteralPath $dbPath
            uninstallNotExecuted_installDirStillPresent = Test-Path -LiteralPath $installDir
        }
        Save-Json -Name '19-uninstall-registration.json' -Object $result
        $result
    }

    # --------------------------------------------------------- final state
    Invoke-Step -Name 'finalState' {
        $result = [ordered]@{
            installDirListingAfterAll = Get-DirListing -Root $installDir
            appProcessesRunning = @(Get-Process -Name 'muaman_store' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)
            dbStillPresent = Test-Path -LiteralPath $dbPath
            capturedAtUtc = Get-UtcString
        }
        Save-Json -Name '20-final-state.json' -Object $result
        $result
    }

    # ----------------------------------------------------------- summary
    $allPassed = ($allFailed.Count -eq 0)
    $summary = [ordered]@{
        runId = $RunId
        phase = 'MUAMAN-13P'
        startedAtUtc = $capturedAtStart
        finishedAtUtc = Get-UtcString
        workerUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        allStepsPassed = $allPassed
        failedSteps = $allFailed
        steps = $steps
    }
    Save-Json -Name 'worker-done.json' -Object $summary
    Log "RUN END allStepsPassed=$allPassed"
    if ($allPassed) {
        exit 0
    } else {
        exit 1
    }

} catch {
    $summary = [ordered]@{
        runId = $RunId
        phase = 'MUAMAN-13P'
        startedAtUtc = $capturedAtStart
        finishedAtUtc = Get-UtcString
        workerUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        allStepsPassed = $false
        failedSteps = $allFailed
        fatalError = $_.Exception.Message
        steps = $steps
    }
    Save-Json -Name 'worker-done.json' -Object $summary
    Log "RUN FAILED fatal=$($_.Exception.Message)"
    exit 2
} finally {
    Restore-SystemSleep
}
