# fresh_user_worker.ps1 - MUAMAN-13Q worker.
# Runs AS the independent fresh standard user (launched by the orchestrator via
# CreateProcessWithLogonW). Performs the full acceptance lifecycle:
#   identity proof -> clean pre-install state -> FIRST INSTALL (frozen installer)
#   -> installed-state verification -> first launch (first-owner setup -> login
#   -> dashboard) -> clean close -> pre-uninstall snapshot -> official uninstaller
#   discovery -> official uninstall -> post-uninstall validation -> leftover
#   classification -> REINSTALL (same bytes) -> reinstalled-state verification
#   -> second launch (login -> dashboard) -> clean close -> final state.
#
# IMPORTANT: this file is ASCII-only. Arabic UI strings are read from ui_strings.json.
#
# Environment variables set by the orchestrator:
#   M13Q_OWNER_DISPLAYNAME, M13Q_OWNER_USERNAME, M13Q_OWNER_PASSWORD, M13Q_RESTRICTED_PATH

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

function Save-Text {
    param([string]$Name, [string]$Text)
    [System.IO.File]::WriteAllText((Join-Path $JsonDir $Name), $Text, (New-Object System.Text.UTF8Encoding $false))
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
$script:allFailed = @()
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

# Bounded, timestamped polling for expected asynchronous disappearance/appearance.
# Final timeout is a hard FAIL (returns $false); every poll is recorded.
function Wait-Until {
    param(
        [Parameter(Mandatory = $true)][scriptblock]$Condition,
        [Parameter(Mandatory = $true)][string]$What,
        [int]$TimeoutSec = 60,
        [int]$IntervalMs = 500
    )
    $polls = @()
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
        $now = Get-UtcString
        $okNow = $false
        $noteNow = ''
        try {
            $res = & $Condition
            $okNow = [bool]$res
        } catch {
            $noteNow = $_.Exception.Message
        }
        $polls += [ordered]@{ at = $now; ok = $okNow; note = $noteNow }
        if ($okNow) {
            return [ordered]@{ ok = $true; seconds = [math]::Round($sw.Elapsed.TotalSeconds, 1); polls = $polls; what = $What }
        }
        Start-Sleep -Milliseconds $IntervalMs
    }
    return [ordered]@{ ok = $false; seconds = [math]::Round($sw.Elapsed.TotalSeconds, 1); polls = $polls; what = $What }
}

function Get-MuamanProcessIds {
    $ids = @(Get-Process -Name 'muaman_store' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)
    return ,$ids
}

function Get-UninstallerProcessIds {
    $ids = @(Get-Process -Name 'unins000' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)
    return ,$ids
}

# Full installed-payload comparison against the 13K manifest + 13N contract.
function Test-InstalledPayload {
    param(
        [string]$InstallDir,
        [string]$ReferenceDir,
        [string]$RetainedDbRel
    )
    $installed = Get-DirListing -Root $InstallDir -IncludeSha
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
        $instSize = $null
        $instSha = $null
        if ($installedMap.ContainsKey($f.rel)) {
            $instSize = $installedMap[$f.rel].size
            $instSha = $installedMap[$f.rel].sha256
            $match = ($instSize -eq $f.size) -and ($instSha -eq $f.sha256)
        }
        $payload += [ordered]@{ rel = $f.rel; expectedSize = $f.size; expectedSha256 = $f.sha256; installedSize = $instSize; installedSha256 = $instSha; match = $match }
    }
    $innoExtras = @('unins000.exe', 'unins000.dat', 'unins000.msg', 'unins000.shl')
    foreach ($f in $installed) {
        $rel = $f.rel -replace '\\', '/'
        $isPayload = $manifestMap.ContainsKey($rel)
        $isInnoExtra = $innoExtras -contains $rel
        $isRetainedDb = ($RetainedDbRel -and $rel -eq $RetainedDbRel)
        if (-not $isPayload -and -not $isInnoExtra -and -not $isRetainedDb) {
            $unexpected += $rel
        }
    }

    $installedExe = $installedMap[$contract13n.application.mainExecutable]
    $installedExeSize = if ($installedExe) { $installedExe.size } else { $null }
    $installedExeSha = if ($installedExe) { $installedExe.sha256 } else { $null }
    $flutterDll = $installedMap['flutter_windows.dll']
    $flutterDllSha = if ($flutterDll) { $flutterDll.sha256 } else { $null }
    return [ordered]@{
        installDir = $InstallDir
        payloadFileCountExpected = $manifest13k.fileCount
        payloadFileCountInstalled = $payload.Count
        payloadAllMatch = (@($payload | Where-Object { -not $_.match }).Count -eq 0)
        payload = $payload
        innoUninstallerExtrasPresent = @($innoExtras | Where-Object { $installedMap.ContainsKey($_) })
        unexpectedFiles = $unexpected
        mainExecutable = $contract13n.application.mainExecutable
        exeSizeMatch = ($null -ne $installedExe -and $installedExeSize -eq $contractExeSize)
        exeSha256Match = ($null -ne $installedExe -and $installedExeSha -eq $contractExeSha)
        exeInstalledSize = $installedExeSize
        exeInstalledSha256 = $installedExeSha
        flutterWindowsDllSha256 = $flutterDllSha
    }
}

# Drive the first-owner setup screen through owner creation. After clicking
# create-owner the app transitions to the login screen (the separate
# Drive-LoginToDashboard function then drives login -> dashboard). Mirrors the
# accepted 13P flow. Returns facts (no secrets).
function Drive-SetupToCreateOwner {
    param(
        [IntPtr]$Handle,
        [string]$Tag,
        [hashtable]$Owner
    )
    $h = $Handle

    $shot = Join-Path $ShotsDir "$Tag-setup-initial.png"
    $capNote = Capture-AppWindowPng -Handle $h -File $shot
    $words = @(Invoke-OcrFile -Path $shot -LanguageTag 'ar-SA')
    Save-OcrDump -Name "$Tag-setup-initial.txt" -Words $words
    $titleHit = Find-OcrWordByParts -Words $words -Parts @($U.setup.title -split '\s+')
    $fields = Get-OcrFields -PngPath $shot -FieldLabels ([ordered]@{
        name = $U.setup.fieldName
        user = $U.setup.fieldUsername
        pass = $U.setup.fieldPassword
        confirm = $U.setup.fieldConfirmPassword
    })
    $setupTitleFound = ($null -ne $titleHit)
    $fieldsFound = ($null -ne $fields['name']) -and ($null -ne $fields['user']) -and ($null -ne $fields['pass']) -and ($null -ne $fields['confirm'])
    if (-not ($setupTitleFound -and $fieldsFound)) { throw 'first-owner setup screen not recognized via OCR' }

    $fieldDefs = [ordered]@{
        name = [ordered]@{ label = $U.setup.fieldName; value = $Owner.ownerDisplay }
        user = [ordered]@{ label = $U.setup.fieldUsername; value = $Owner.ownerUsername }
        pass = [ordered]@{ label = $U.setup.fieldPassword; value = $Owner.ownerPassword; secret = $true }
        confirm = [ordered]@{ label = $U.setup.fieldConfirmPassword; value = $Owner.ownerPassword; secret = $true }
    }
    $methods = Invoke-OcrFieldFlow -Handle $h -FieldDefs $fieldDefs -ShotDir $ShotsDir -Tag $Tag
    $btnParts = @($U.setup.buttonCreateOwner -split '\s+')
    $btn = Click-OcrButtonByParts -Handle $h -Parts $btnParts -ShotDir $ShotsDir -Tag ($Tag + '-b') -Transient
    if (-not $btn.clicked) { throw 'create-owner button not found via OCR' }

    return [ordered]@{
        setupTitleFound = $setupTitleFound
        fieldsFound = $fieldsFound
        ownerMethods = $methods
        createButton = $btn
        setupScreenshot = $shot
    }
}

# Drive the login screen to the dashboard. Returns facts (no secrets).
function Drive-LoginToDashboard {
    param(
        [IntPtr]$Handle,
        [string]$Tag,
        [hashtable]$Owner,
        [int]$TransitionTimeoutSec = 60
    )
    $h = $Handle
    $loginTitleFound = $false
    $loginButtonFound = $false
    $words = @()
    $shot = $null
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $TransitionTimeoutSec) {
        $shot = Join-Path $ShotsDir "$Tag-login.png"
        $capNote = Capture-AppWindowPng -Handle $h -File $shot
        $words = @(Invoke-OcrFile -Path $shot -LanguageTag 'ar-SA')
        $titleHit = Find-OcrWordByParts -Words $words -Parts @($U.login.title -split '\s+')
        $btnHit = Find-OcrWordByParts -Words $words -Parts @($U.login.buttonLogin -split '\s+')
        $loginTitleFound = ($null -ne $titleHit)
        $loginButtonFound = ($null -ne $btnHit)
        if ($loginTitleFound -and $loginButtonFound) { break }
        Start-Sleep -Milliseconds 800
    }
    if (-not ($loginTitleFound -and $loginButtonFound)) { throw 'login screen not reached' }
    Save-OcrDump -Name "$Tag-login.txt" -Words $words

    $fieldDefs = [ordered]@{
        user = [ordered]@{ label = $U.login.fieldUsername; value = $Owner.ownerUsername }
        pass = [ordered]@{ label = $U.login.fieldPassword; value = $Owner.ownerPassword; secret = $true }
    }
    $methods = Invoke-OcrFieldFlow -Handle $h -FieldDefs $fieldDefs -ShotDir $ShotsDir -Tag $Tag
    $btnParts = @($U.login.buttonLogin -split '\s+')
    $btn = Click-OcrButtonByParts -Handle $h -Parts $btnParts -ShotDir $ShotsDir -Tag ($Tag + '-b') -Transient
    if (-not $btn.clicked) { throw 'login button not found via OCR' }
    $methods[$U.login.buttonLogin] = "ClickAt+TypeText($($btn.word)) try=$($btn.try)"

    $dashboardReached = $false
    $wordsDash = @()
    $shotDash = $null
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $TransitionTimeoutSec) {
        $shotDash = Join-Path $ShotsDir "$Tag-dashboard.png"
        $capNote = Capture-AppWindowPng -Handle $h -File $shotDash
        $wordsDash = @(Invoke-OcrFile -Path $shotDash -LanguageTag 'ar-SA')
        $titleHit = Find-OcrWordByParts -Words $wordsDash -Parts @($U.dashboard.title -split '\s+')
        $navHit = Find-OcrWordByParts -Words $wordsDash -Parts @($U.dashboard.navSales -split '\s+')
        if ($null -ne $titleHit -or $null -ne $navHit) { $dashboardReached = $true; break }
        Start-Sleep -Milliseconds 800
    }
    if (-not $dashboardReached) { throw 'dashboard not reached after login' }
    Save-OcrDump -Name "$Tag-dashboard.txt" -Words $wordsDash

    return [ordered]@{
        loginTitleFound = $loginTitleFound
        loginButtonFound = $loginButtonFound
        loginMethods = $methods
        loginButton = $btn
        dashboardReached = $dashboardReached
        loginScreenshot = $shot
        dashboardScreenshot = $shotDash
    }
}

# Database facts after the app has closed (SQLite file must not be held open).
function Get-DbFacts {
    param([string]$DbPath, [string]$OwnerUsername)
    if (-not (Test-Path -LiteralPath $DbPath)) {
        return [ordered]@{ path = $DbPath; dbExists = $false }
    }
    $bytes = Read-FileShared -Path $DbPath
    $header = [System.Text.Encoding]::ASCII.GetString($bytes, 0, [Math]::Min(16, $bytes.Length))
    $isSqlite = ($header -eq 'SQLite format 3' -and $bytes.Length -gt 15 -and $bytes[15] -eq 0)
    $latin = [System.Text.Encoding]::GetEncoding(28591).GetString($bytes)
    $tables = @()
    foreach ($t in @('products','sales','returns','expenses','inventory_count','users','import_batches','invoices','app_settings')) {
        if ($latin.Contains($t)) { $tables += $t }
    }
    $ownerUsernamePresent = $latin.Contains($OwnerUsername.ToLowerInvariant())
    return [ordered]@{
        path = $DbPath
        dbExists = $true
        sizeBytes = $bytes.Length
        sha256 = (Get-Sha256HexLower -Bytes $bytes)
        sqliteHeaderValid = $isSqlite
        tablesFound = $tables
        ownerUsernameTextPresent = $ownerUsernamePresent
        lastWriteTimeUtc = (Get-Item -LiteralPath $DbPath).LastWriteTimeUtc.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    }
}

# OS account-picture placeholder path for this account (known false-positive guard).
function Get-AccountPicturePlaceholderPath {
    param([string]$AccountName)
    return Join-Path (Join-Path $env:ProgramData 'Microsoft\User Account Pictures') "$AccountName.dat"
}

try {

    Initialize-WinNative
    [void][M13PWinNative]::SetProcessDPIAware()
    Prevent-SystemSleep

    $cfg = Read-JsonUtf8 -Path $ConfigPath
    $U = Read-JsonUtf8 -Path $UiStringsPath

    $ownerDisplay = $env:M13Q_OWNER_DISPLAYNAME
    $ownerUsername = $env:M13Q_OWNER_USERNAME
    $ownerPassword = $env:M13Q_OWNER_PASSWORD
    $restrictedPath = $env:M13Q_RESTRICTED_PATH
    if (-not $ownerDisplay -or -not $ownerUsername -or -not $ownerPassword -or -not $restrictedPath) {
        throw 'Missing required environment variables (M13Q_OWNER_* / M13Q_RESTRICTED_PATH)'
    }
    $Owner = @{
        ownerDisplay = $ownerDisplay
        ownerUsername = $ownerUsername
        ownerPassword = $ownerPassword
    }

    $localAppData = $env:LOCALAPPDATA
    $appData = $env:APPDATA
    $userProfile = $env:USERPROFILE
    $installDir = Join-Path (Join-Path $localAppData 'Programs') $cfg.application.appDirName
    $appExe = Join-Path $installDir $cfg.application.mainExecutable
    $dbRel = ($cfg.data.ffiDbRelDir -replace '/', '\') + '\' + $cfg.data.dbFileName
    $dbPath = Join-Path $installDir $dbRel
    $uninstallRoot = [string]$cfg.uninstall.registrationRoot
    $uninstallKey = Join-Path $uninstallRoot (('{' + $cfg.application.appId + '}') + $cfg.uninstall.keySuffix)
    $startMenuLink = Join-Path (Join-Path $appData $cfg.shortcut.startMenuDir) $cfg.shortcut.startMenuName
    $accountPicture = Get-AccountPicturePlaceholderPath -AccountName $ExpectedUserName

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
                forbiddenEnabledPresent = $forbiddenPrivs
            }
            groupsText = $groups
        }
        Save-Json -Name '04-user-identity.json' -Object $result
        $result
    }

    # ---------------------------------------------------------- pre-install state
    Invoke-Step -Name 'prestate' -Fatal {
        $os = Get-CimInstance Win32_OperatingSystem
        $arch = $env:PROCESSOR_ARCHITECTURE
        $hkcuMuamanKeys = Get-HkcuUninstallMuamanKeys -Root $uninstallRoot -DisplayName $cfg.uninstall.displayName -Publisher $cfg.uninstall.publisher -KeySuffix $cfg.uninstall.keySuffix
        $result = [ordered]@{
            os = [ordered]@{
                caption = [string]$os.Caption
                version = [string]$os.Version
                build = [string]$os.BuildNumber
                osArchitecture = [string]$os.OSArchitecture
                processArchitecture = $arch
            }
            user = [ordered]@{
                localAppData = $localAppData
                appData = $appData
                userProfile = $userProfile
                userProfileDirExists = Test-Path -LiteralPath $userProfile
            }
            install = [ordered]@{
                installDir = $installDir
                installDirExistsBefore = Test-Path -LiteralPath $installDir
                appExeExistsBefore = Test-Path -LiteralPath $appExe
                hkcuMuamanUninstallKeys = $hkcuMuamanKeys
                uninstallRegistrationAbsent = ($hkcuMuamanKeys.Count -eq 0)
            }
            processes = [ordered]@{
                appProcessIdsBefore = Get-MuamanProcessIds
                uninstallerProcessIdsBefore = Get-UninstallerProcessIds
            }
            osAccountPicturePlaceholder = [ordered]@{
                path = $accountPicture
                exists = Test-Path -LiteralPath $accountPicture
            }
            localAppDataListing = Get-DirListing -Root $localAppData
            appDataListing = Get-DirListing -Root $appData
        }
        Save-Json -Name '05-preinstall-state.json' -Object $result
        $result
    }

    # ------------------------------------------------------------- first install
    Invoke-Step -Name 'install1' -Fatal {
        $installLog = Join-Path (Split-Path -Parent $LogFile) 'install1.log'
        $envMap = New-RestrictedEnvironment -RestrictedPath $restrictedPath
        $args = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /LOG="' + $installLog + '"'
        $commandLine = "`"$InstallerPath`" $args"
        Save-Text -Name '06-first-install-command.txt' -Object ("$commandLine`r`nrestrictedPath=$restrictedPath")
        $start = Get-Date
        $r = Start-ChildProcess -FilePath $InstallerPath -Arguments $args -WorkingDir $installDir -Environment $envMap -TimeoutMs 300000
        $durationSec = [math]::Round(((Get-Date) - $start).TotalSeconds, 1)
        $installedExists = Test-Path -LiteralPath $appExe
        $result = [ordered]@{
            commandLine = $commandLine
            exitCode = $r.exitCode
            timedOut = $r.timedOut
            durationSec = $durationSec
            installLogPath = $installLog
            installLogBytes = if (Test-Path -LiteralPath $installLog) { (Get-Item -LiteralPath $installLog).Length } else { 0 }
            appExeExists = $installedExists
            installDir = $installDir
            installerSha256 = (Get-FileSha256 -Path $InstallerPath)
            installerSize = (Get-Item -LiteralPath $InstallerPath).Length
        }
        Save-Json -Name '07-first-install-result.json' -Object $result
        if ($r.timedOut -or $r.exitCode -ne 0 -or -not $installedExists) {
            throw "first install failed: exit=$($r.exitCode) timedOut=$($r.timedOut) appExeExists=$installedExists"
        }
        $result
    }

    # ------------------------------------------------- installed-state integrity
    Invoke-Step -Name 'installedState' -Fatal {
        $hkcuUninstall = Get-RegKeySnapshot -Path $uninstallKey
        $hkcuMuamanKeys = Get-HkcuUninstallMuamanKeys -Root $uninstallRoot -DisplayName $cfg.uninstall.displayName -Publisher $cfg.uninstall.publisher -KeySuffix $cfg.uninstall.keySuffix
        $machineStartMenuLink = Join-Path (Join-Path $env:ProgramData $cfg.shortcut.machineStartMenuDir) $cfg.shortcut.startMenuName
        $payload = Test-InstalledPayload -InstallDir $installDir -ReferenceDir $ReferenceDir -RetainedDbRel ($dbRel -replace '\\', '/')
        $hklmUninstallHits = @()
        foreach ($pattern in @('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
                               'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')) {
            Get-Item -Path $pattern -ErrorAction SilentlyContinue | ForEach-Object {
                $child = $_.PSChildName
                $display = Get-RegValueSafe -Path $_.PSPath -Property 'DisplayName'
                if ($child -like '*muaman*' -or ($display -like '*muaman*')) { $hklmUninstallHits += $child }
            }
        }
        $result = [ordered]@{
            uninstallKey = $uninstallKey
            hkcuUninstallPresent = ($null -ne $hkcuUninstall)
            hkcuUninstall = $hkcuUninstall
            hkcuMuamanUninstallKeys = $hkcuMuamanKeys
            startMenuLink = $startMenuLink
            startMenuLinkExists = Test-Path -LiteralPath $startMenuLink
            machineStartMenuLinkExists = Test-Path -LiteralPath $machineStartMenuLink
            startMenuShortcutTarget = if (Test-Path -LiteralPath $startMenuLink) {
                $sh = New-Object -ComObject WScript.Shell
                $sh.CreateShortcut($startMenuLink).TargetPath
            } else { $null }
            payload = $payload
            hklmUninstallHits = $hklmUninstallHits
        }
        Save-Json -Name '08-installed-state.json' -Object $result
        if (-not $result.hkcuUninstallPresent) { throw 'uninstall registration missing after first install' }
        if (-not $payload.payloadAllMatch) { throw 'payload mismatch after first install' }
        if ($payload.unexpectedFiles.Count -gt 0) { throw "unexpected files after first install: $($payload.unexpectedFiles -join ', ')" }
        $result
    }

    # -------------------------------------------------------------- first launch
    Invoke-Step -Name 'launch1' -Fatal {
        $envMap = New-RestrictedEnvironment -RestrictedPath $restrictedPath
        $start = Get-Date
        $lw = Get-LaunchWindow -Exe $appExe -WorkDir $installDir -Environment $envMap -TimeoutSec $cfg.launchTimeoutsSec.windowFirst
        $proc = $lw.proc
        $handle = $lw.handle
        if (-not $lw.windowFound) { throw 'first launch: no main window' }
        $windowFacts = Get-WindowFacts -Handle $handle
        $windowFacts['rect'] = Get-WindowRectOut -Handle $handle
        $shot = Join-Path $ShotsDir '09-launch1-window.png'
        Capture-WindowPng -Handle $handle -File $shot | Out-Null
        $windowFacts['screenshot'] = $shot

        # no immediate crash: process alive and window still valid 3s later
        Start-Sleep -Seconds 3
        $stillAlive = $false
        try { $proc.Refresh(); $stillAlive = -not $proc.HasExited } catch {}
        $mainModulePath = $null
        try { $mainModulePath = $proc.MainModule.FileName } catch {}
        $windowStillValid = Test-AppWindowReady -Handle $handle

        $flow = Drive-SetupToCreateOwner -Handle $handle -Tag '09s' -Owner $Owner
        $flow2 = Drive-LoginToDashboard -Handle $handle -Tag '09l' -Owner $Owner -TransitionTimeoutSec $cfg.launchTimeoutsSec.screenTransition
        $db = Get-DbFacts -DbPath $dbPath -OwnerUsername $ownerUsername

        $result = [ordered]@{
            launch = [ordered]@{
                exe = $appExe
                workingDirectory = $installDir
                restrictedPath = $restrictedPath
                processId = $proc.Id
                sessionId = $proc.SessionId
                secondsToWindow = [math]::Round(((Get-Date) - $start).TotalSeconds, 1)
                windowFound = $lw.windowFound
                window = $windowFacts
                processAliveAfter3s = $stillAlive
                mainModulePath = $mainModulePath
                mainModuleMatchesInstalledExe = ($mainModulePath -and $mainModulePath -eq $appExe)
                windowStillValidAfter3s = $windowStillValid
            }
            setupToDashboard = $flow
            loginToDashboard = $flow2
            databaseAfterSetup = $db
        }
        Save-Json -Name '09-first-launch-result.json' -Object $result
        if (-not $stillAlive) { throw 'first launch: process exited within 3s' }
        if (-not $windowStillValid) { throw 'first launch: window invalid after 3s' }
        if (-not $flow2.dashboardReached) { throw 'first launch: usable dashboard state not reached' }
        if (-not ($db.dbExists -and $db.sqliteHeaderValid -and ($db.tablesFound -contains 'users') -and $db.ownerUsernameTextPresent)) {
            throw 'first launch: business database not created correctly'
        }
        $script:launch1 = [ordered]@{ handle = $handle; proc = $proc; result = $result }
        $result
    }

    # -------------------------------------------------------------- close1
    Invoke-Step -Name 'close1' -Fatal {
        $closeResult = Close-WindowGracefully -Handle $script:launch1.handle -Process $script:launch1.proc -TimeoutSec $cfg.launchTimeoutsSec.close
        Start-Sleep -Seconds 2
        $orphans = Get-MuamanProcessIds
        $result = [ordered]@{
            close = $closeResult
            dbStillPresentAfterClose = Test-Path -LiteralPath $dbPath
            orphanProcessIds = $orphans
        }
        Save-Json -Name '09-first-launch-close.json' -Object $result
        if (-not $closeResult.exited) { throw 'first launch: app did not exit after WM_CLOSE' }
        if ($orphans.Count -gt 0) { throw "first launch: orphan processes remain: $($orphans -join ', ')" }
        $result
    }

    # ----------------------------------------------- pre-uninstall snapshot
    Invoke-Step -Name 'preUninstallSnapshot' -Fatal {
        $beforeLocal = Get-DirListing -Root $localAppData
        $beforeAppData = Get-DirListing -Root $appData
        $installRootListing = Get-DirListing -Root $installDir -IncludeSha
        $hkcuUninstall = Get-RegKeySnapshot -Path $uninstallKey
        $result = [ordered]@{
            processIds = Get-MuamanProcessIds
            installRoot = $installRootListing
            uninstallKey = $uninstallKey
            hkcuUninstall = $hkcuUninstall
            db = Get-DbFacts -DbPath $dbPath -OwnerUsername $ownerUsername
            startMenuLinkExists = Test-Path -LiteralPath $startMenuLink
            localAppDataListingBeforeUninstall = $beforeLocal
            appDataListingBeforeUninstall = $beforeAppData
        }
        Save-Json -Name '10-preuninstall-snapshot.json' -Object $result
        $result
    }

    # ----------------------------------------- official uninstaller discovery
    Invoke-Step -Name 'uninstallDiscovery' -Fatal {
        $hkcuUninstall = Get-RegKeySnapshot -Path $uninstallKey
        if ($null -eq $hkcuUninstall) { throw 'uninstall registration missing before uninstall' }
        $uninstallString = $null
        if ($hkcuUninstall.Contains('UninstallString')) { $uninstallString = [string]$hkcuUninstall['UninstallString'] }
        if (-not $uninstallString) { throw 'UninstallString missing from registration' }
        $uninstallerPath = $null
        if ($uninstallString -match '"([^"]+\.exe)"') { $uninstallerPath = $Matches[1] }
        elseif ($uninstallString -match '([A-Za-z]:\\.+\.exe)') { $uninstallerPath = $Matches[1] }
        if (-not $uninstallerPath) { throw "UninstallString not parseable: $uninstallString" }
        $uninstallerExists = Test-Path -LiteralPath $uninstallerPath
        $expectedUninstaller = Join-Path $installDir 'unins000.exe'
        $result = [ordered]@{
            registrationKey = $uninstallKey
            displayName = if ($hkcuUninstall.Contains('DisplayName')) { [string]$hkcuUninstall['DisplayName'] } else { $null }
            publisher = if ($hkcuUninstall.Contains('Publisher')) { [string]$hkcuUninstall['Publisher'] } else { $null }
            displayVersion = if ($hkcuUninstall.Contains('DisplayVersion')) { [string]$hkcuUninstall['DisplayVersion'] } else { $null }
            installLocation = if ($hkcuUninstall.Contains('InstallLocation')) { [string]$hkcuUninstall['InstallLocation'] } else { $null }
            uninstallString = $uninstallString
            uninstallerPath = $uninstallerPath
            uninstallerExists = $uninstallerExists
            expectedUninstaller = $expectedUninstaller
            uninstallerMatchesExpected = ($uninstallerPath -eq $expectedUninstaller)
        }
        Save-Json -Name '11-uninstall-registration.json' -Object $result
        if (-not $uninstallerExists) { throw "official uninstaller missing: $uninstallerPath" }
        if (-not $result.uninstallerMatchesExpected) { throw "uninstaller path not inside install root: $uninstallerPath" }
        $result
    }

    # ------------------------------------------------------- official uninstall
    Invoke-Step -Name 'uninstall' -Fatal {
        $disc = Read-JsonUtf8 -Path (Join-Path $JsonDir '11-uninstall-registration.json')
        $uninstallerPath = [string]$disc.uninstallerPath
        $uninstallLog = Join-Path (Split-Path -Parent $LogFile) 'uninstall.log'
        $args = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /LOG="' + $uninstallLog + '"'
        $commandLine = "`"$uninstallerPath`" $args"
        $envMap = New-RestrictedEnvironment -RestrictedPath $restrictedPath
        $start = Get-Date
        $r = Start-ChildProcess -FilePath $uninstallerPath -Arguments $args -WorkingDir (Split-Path -Parent $uninstallerPath) -Environment $envMap -TimeoutMs 300000
        $durationSec = [math]::Round(((Get-Date) - $start).TotalSeconds, 1)

        $regGone = Wait-Until -Condition {
            (Get-HkcuUninstallMuamanKeys -Root $uninstallRoot -DisplayName $cfg.uninstall.displayName -Publisher $cfg.uninstall.publisher -KeySuffix $cfg.uninstall.keySuffix).Count -eq 0
        } -What 'uninstall-registration-disappears' -TimeoutSec $cfg.launchTimeoutsSec.registrationPoll
        $exeGone = Wait-Until -Condition {
            -not (Test-Path -LiteralPath $appExe)
        } -What 'installed-exe-disappears' -TimeoutSec $cfg.launchTimeoutsSec.filePoll
        $uninsGone = Wait-Until -Condition {
            -not (Test-Path -LiteralPath (Join-Path $installDir 'unins000.exe'))
        } -What 'uninstaller-disappears' -TimeoutSec $cfg.launchTimeoutsSec.filePoll
        $procsGone = Wait-Until -Condition {
            ((Get-MuamanProcessIds).Count -eq 0) -and ((Get-UninstallerProcessIds).Count -eq 0)
        } -What 'processes-gone' -TimeoutSec $cfg.launchTimeoutsSec.processPoll

        $result = [ordered]@{
            commandLine = $commandLine
            uninstallerPath = $uninstallerPath
            exitCode = $r.exitCode
            timedOut = $r.timedOut
            durationSec = $durationSec
            uninstallLogPath = $uninstallLog
            uninstallLogBytes = if (Test-Path -LiteralPath $uninstallLog) { (Get-Item -LiteralPath $uninstallLog).Length } else { 0 }
            registrationRemoved = $regGone
            installedExeRemoved = $exeGone
            uninstallerRemoved = $uninsGone
            processesGone = $procsGone
        }
        Save-Json -Name '12-uninstall-result.json' -Object $result
        if ($r.timedOut) { throw 'uninstaller timed out' }
        if ($r.exitCode -ne 0) { throw "uninstaller exit code: $($r.exitCode)" }
        if (-not $regGone.ok) { throw 'uninstall registration did not disappear' }
        if (-not $exeGone.ok) { throw 'installed executable did not disappear' }
        if (-not $uninsGone.ok) { throw 'uninstaller executable did not disappear' }
        if (-not $procsGone.ok) { throw 'app/uninstaller processes still running after uninstall' }
        $result
    }

    # ------------------------------------------------ post-uninstall validation
    Invoke-Step -Name 'postUninstallState' -Fatal {
        $regKeys = Get-HkcuUninstallMuamanKeys -Root $uninstallRoot -DisplayName $cfg.uninstall.displayName -Publisher $cfg.uninstall.publisher -KeySuffix $cfg.uninstall.keySuffix
        $installRootListing = Get-DirListing -Root $installDir -IncludeSha
        $payloadRels = @(Read-JsonUtf8 -Path (Join-Path $ReferenceDir 'release-manifest.json')).files.rel
        $missingPayload = @()
        foreach ($rel in $payloadRels) {
            $p = Join-Path $installDir ($rel -replace '/', '\')
            if (Test-Path -LiteralPath $p) { $missingPayload += $rel }
        }
        $uninsExtras = @('unins000.exe', 'unins000.dat', 'unins000.msg', 'unins000.shl')
        $uninsStillPresent = @($uninsExtras | Where-Object { Test-Path -LiteralPath (Join-Path $installDir $_) })
        $result = [ordered]@{
            appProcessIds = Get-MuamanProcessIds
            uninstallerProcessIds = Get-UninstallerProcessIds
            hkcuMuamanUninstallKeys = $regKeys
            registrationRemoved = ($regKeys.Count -eq 0)
            installDir = $installDir
            installDirExists = Test-Path -LiteralPath $installDir
            appExeExists = Test-Path -LiteralPath $appExe
            payloadFilesStillPresent = $missingPayload
            uninsExtrasStillPresent = $uninsStillPresent
            startMenuLinkExists = Test-Path -LiteralPath $startMenuLink
            installRootListing = $installRootListing
            db = Get-DbFacts -DbPath $dbPath -OwnerUsername $ownerUsername
            osAccountPicturePlaceholderExists = Test-Path -LiteralPath $accountPicture
        }
        Save-Json -Name '13-postuninstall-state.json' -Object $result
        if ($result.appProcessIds.Count -gt 0) { throw 'post-uninstall: app processes still running' }
        if (-not $result.registrationRemoved) { throw 'post-uninstall: registration not removed' }
        if ($result.appExeExists) { throw 'post-uninstall: installed exe still present' }
        if ($result.payloadFilesStillPresent.Count -gt 0) { throw "post-uninstall: payload files still present: $($result.payloadFilesStillPresent -join ', ')" }
        if ($result.uninsExtrasStillPresent.Count -gt 0) { throw "post-uninstall: uninstaller extras still present: $($result.uninsExtrasStillPresent -join ', ')" }
        if ($result.startMenuLinkExists) { throw 'post-uninstall: start menu shortcut still present' }
        $result
    }

    # -------------------------------------------------- leftover classification
    Invoke-Step -Name 'leftoverClassification' -Fatal {
        $survivors = @()
        $unknown = @()

        # Install root survivors (the retained DB is the only expected item)
        $installRootListing = Get-DirListing -Root $installDir -IncludeSha
        $dbRelNorm = $dbRel -replace '\\', '/'
        foreach ($f in $installRootListing) {
            $rel = $f.rel -replace '\\', '/'
            if ($rel -eq $dbRelNorm) {
                $survivors += [ordered]@{ path = $rel; classification = 'expected-retained-user-data'; detail = 'business SQLite database (installer preserves user data; {app} removed only when empty)' }
            } else {
                $unknown += [ordered]@{ path = $rel; classification = 'unknown-installer-leftover' }
            }
        }

        # ProgramData scan: exclude ONLY the OS account-picture placeholder FILE
        # for each real local account (precise path semantics: exact
        # "<account>.dat" path in the OS account-pictures directory, resolved for
        # every existing local account, not a directory-wide or account-name
        # wildcard). A real leftover there (or a muaman-named file near a
        # placeholder) is still caught.
        $programDataMuaman = @()
        if (Test-Path -LiteralPath $env:ProgramData) {
            $accountPictureDir = Join-Path $env:ProgramData 'Microsoft\User Account Pictures'
            $osPlaceholderPaths = @()
            if (Test-Path -LiteralPath $accountPictureDir) {
                $localAccounts = @()
                try { $localAccounts = @(Get-LocalUser -ErrorAction Stop | Select-Object -ExpandProperty Name) } catch { $localAccounts = @() }
                foreach ($acc in $localAccounts) {
                    $p = [System.IO.Path]::GetFullPath((Join-Path $accountPictureDir "$acc.dat"))
                    if (Test-Path -LiteralPath $p) { $osPlaceholderPaths += $p }
                }
            }
            Get-ChildItem -LiteralPath $env:ProgramData -Recurse -Force -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.Name -like '*muaman*' -and
                    $osPlaceholderPaths -notcontains [System.IO.Path]::GetFullPath($_.FullName)
                } |
                ForEach-Object { $programDataMuaman += $_.FullName }
        }
        foreach ($p in $programDataMuaman) { $unknown += [ordered]@{ path = $p; classification = 'unknown-installer-leftover' } }

        # AppData / LocalAppData deltas vs prestate. Only app-named paths or
        # paths under app-owned locations are treated as installer leftovers;
        # unrelated OS profile churn (temp/cache) is recorded as informational
        # and does not fail the classification.
        $pre = Read-JsonUtf8 -Path (Join-Path $JsonDir '05-preinstall-state.json')
        $beforeLocal = @($pre.localAppDataListing)
        $beforeAppData = @($pre.appDataListing)
        $afterLocal = Get-DirListing -Root $localAppData
        $afterAppData = Get-DirListing -Root $appData
        $localDelta = Diff-DirListings -Before $beforeLocal -After $afterLocal
        $appDelta = Diff-DirListings -Before $beforeAppData -After $afterAppData
        $deltaUnknown = @()
        $deltaChurn = @()
        $appOwnedPrefixes = @(
            (Join-Path (Join-Path $localAppData 'Programs') $cfg.application.appDirName)
        )
        foreach ($rel in @($localDelta.added) + @($localDelta.changed)) {
            $full = Join-Path $localAppData ($rel -replace '/', '\')
            # retained DB is covered by the install-root classification
            if ($full -eq $dbPath) { continue }
            $isAppOwned = @($appOwnedPrefixes | Where-Object { $full.StartsWith($_, [System.StringComparison]::OrdinalIgnoreCase) }).Count -gt 0
            $isAppNamed = ($rel -match 'muaman')
            if ($isAppOwned -or $isAppNamed) { $deltaUnknown += $rel } else { $deltaChurn += $rel }
        }
        foreach ($rel in @($appDelta.added) + @($appDelta.changed)) {
            if ($rel -match 'muaman') { $deltaUnknown += $rel } else { $deltaChurn += $rel }
        }
        foreach ($rel in $deltaUnknown) { $unknown += [ordered]@{ path = $rel; classification = 'unknown-installer-leftover' } }

        # Machine-wide registration scan
        $hklmMuaman = @()
        foreach ($pattern in @('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
                               'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
                               'HKLM:\Software\Microsoft\Windows\CurrentVersion\*')) {
            Get-Item -Path $pattern -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_.PSChildName -like '*muaman*') { $hklmMuaman += $_.PSChildName }
            }
        }
        foreach ($k in $hklmMuaman) { $unknown += [ordered]@{ path = "HKLM:$k"; classification = 'unknown-installer-leftover' } }

        $result = [ordered]@{
            expectedRetainedUserData = @($survivors | Where-Object { $_.classification -eq 'expected-retained-user-data' })
            osAccountPicturePlaceholder = [ordered]@{
                path = $accountPicture
                exists = Test-Path -LiteralPath $accountPicture
                classifiedAs = 'os-account-picture-placeholder'
            }
            unknownInstallerLeftovers = $unknown
            localAppDataDelta = $localDelta
            appDataDelta = $appDelta
            deltaChurnInformational = $deltaChurn
            hklmMuamanHits = $hklmMuaman
            programDataMuamanHitsExcludingAccountPictures = $programDataMuaman
            classificationComplete = $true
        }
        Save-Json -Name '14-leftover-classification.json' -Object $result
        if ($unknown.Count -gt 0) {
            throw "unknown installer leftovers after uninstall: $($unknown | ForEach-Object { $_.path } | Sort-Object | Select-Object -First 20)"
        }
        $result
    }

    # --------------------------------------------------------------- reinstall
    Invoke-Step -Name 'reinstall' -Fatal {
        $installLog = Join-Path (Split-Path -Parent $LogFile) 'install2.log'
        $envMap = New-RestrictedEnvironment -RestrictedPath $restrictedPath
        $args = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /LOG="' + $installLog + '"'
        $commandLine = "`"$InstallerPath`" $args"
        $start = Get-Date
        $r = Start-ChildProcess -FilePath $InstallerPath -Arguments $args -WorkingDir $installDir -Environment $envMap -TimeoutMs 300000
        $durationSec = [math]::Round(((Get-Date) - $start).TotalSeconds, 1)
        $installedExists = Test-Path -LiteralPath $appExe
        $result = [ordered]@{
            commandLine = $commandLine
            exitCode = $r.exitCode
            timedOut = $r.timedOut
            durationSec = $durationSec
            installLogPath = $installLog
            installLogBytes = if (Test-Path -LiteralPath $installLog) { (Get-Item -LiteralPath $installLog).Length } else { 0 }
            appExeExists = $installedExists
            installDir = $installDir
            installerSha256 = (Get-FileSha256 -Path $InstallerPath)
            installerSize = (Get-Item -LiteralPath $InstallerPath).Length
        }
        Save-Json -Name '15-reinstall-result.json' -Object $result
        if ($r.timedOut -or $r.exitCode -ne 0 -or -not $installedExists) {
            throw "reinstall failed: exit=$($r.exitCode) timedOut=$($r.timedOut) appExeExists=$installedExists"
        }
        $result
    }

    # ---------------------------------------------- reinstalled-state integrity
    Invoke-Step -Name 'reinstalledState' -Fatal {
        $hkcuUninstall = Get-RegKeySnapshot -Path $uninstallKey
        $hkcuMuamanKeys = Get-HkcuUninstallMuamanKeys -Root $uninstallRoot -DisplayName $cfg.uninstall.displayName -Publisher $cfg.uninstall.publisher -KeySuffix $cfg.uninstall.keySuffix
        $machineStartMenuLink = Join-Path (Join-Path $env:ProgramData $cfg.shortcut.machineStartMenuDir) $cfg.shortcut.startMenuName
        $payload = Test-InstalledPayload -InstallDir $installDir -ReferenceDir $ReferenceDir -RetainedDbRel ($dbRel -replace '\\', '/')
        # duplicate uninstall registrations / roots / shortcuts
        $installRootParents = @()
        Get-ChildItem -LiteralPath (Join-Path $localAppData 'Programs') -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -eq $cfg.application.appDirName } | ForEach-Object { $installRootParents += $_.FullName }
        $startMenuHits = @()
        if (Test-Path -LiteralPath (Split-Path -Parent $startMenuLink)) {
            Get-ChildItem -LiteralPath (Split-Path -Parent $startMenuLink) -Filter $cfg.shortcut.startMenuName -ErrorAction SilentlyContinue |
                ForEach-Object { $startMenuHits += $_.FullName }
        }
        $result = [ordered]@{
            uninstallKey = $uninstallKey
            hkcuUninstallPresent = ($null -ne $hkcuUninstall)
            hkcuUninstall = $hkcuUninstall
            hkcuMuamanUninstallKeys = $hkcuMuamanKeys
            duplicateUninstallRegistrations = @($hkcuMuamanKeys | Where-Object { $_ -ne $cfg.uninstall.registryKeyName })
            installRoots = $installRootParents
            duplicateInstallRoots = @($installRootParents | Where-Object { $_ -ne $installDir })
            startMenuLink = $startMenuLink
            startMenuLinkExists = Test-Path -LiteralPath $startMenuLink
            machineStartMenuLinkExists = Test-Path -LiteralPath $machineStartMenuLink
            startMenuShortcutTarget = if (Test-Path -LiteralPath $startMenuLink) {
                $sh = New-Object -ComObject WScript.Shell
                $sh.CreateShortcut($startMenuLink).TargetPath
            } else { $null }
            startMenuHits = $startMenuHits
            payload = $payload
            dbRetainedAfterReinstall = Test-Path -LiteralPath $dbPath
        }
        Save-Json -Name '16-reinstalled-state.json' -Object $result
        if (-not $result.hkcuUninstallPresent) { throw 'uninstall registration missing after reinstall' }
        if ($hkcuMuamanKeys.Count -ne 1) { throw "duplicate uninstall registrations after reinstall: $($hkcuMuamanKeys -join ', ')" }
        if (-not $payload.payloadAllMatch) { throw 'payload mismatch after reinstall' }
        if ($payload.unexpectedFiles.Count -gt 0) { throw "unexpected files after reinstall: $($payload.unexpectedFiles -join ', ')" }
        if ($result.duplicateInstallRoots.Count -gt 0) { throw 'duplicate install roots after reinstall' }
        if (-not $result.dbRetainedAfterReinstall) { throw 'retained DB missing after reinstall' }
        $result
    }

    # ------------------------------------------------------------ second launch
    Invoke-Step -Name 'launch2' -Fatal {
        $envMap = New-RestrictedEnvironment -RestrictedPath $restrictedPath
        $start = Get-Date
        $lw = Get-LaunchWindow -Exe $appExe -WorkDir $installDir -Environment $envMap -TimeoutSec $cfg.launchTimeoutsSec.windowSubsequent
        $proc = $lw.proc
        $handle = $lw.handle
        if (-not $lw.windowFound) { throw 'second launch: no main window' }
        $windowFacts = Get-WindowFacts -Handle $handle
        $windowFacts['rect'] = Get-WindowRectOut -Handle $handle
        $shot = Join-Path $ShotsDir '17-launch2-window.png'
        Capture-WindowPng -Handle $handle -File $shot | Out-Null
        $windowFacts['screenshot'] = $shot

        Start-Sleep -Seconds 3
        $stillAlive = $false
        try { $proc.Refresh(); $stillAlive = -not $proc.HasExited } catch {}
        $mainModulePath = $null
        try { $mainModulePath = $proc.MainModule.FileName } catch {}
        $windowStillValid = Test-AppWindowReady -Handle $handle

        $flow = Drive-LoginToDashboard -Handle $handle -Tag '17' -Owner $Owner -TransitionTimeoutSec $cfg.launchTimeoutsSec.screenTransition
        $dbAfterLogin = Get-DbFacts -DbPath $dbPath -OwnerUsername $ownerUsername

        $result = [ordered]@{
            launch = [ordered]@{
                exe = $appExe
                workingDirectory = $installDir
                restrictedPath = $restrictedPath
                processId = $proc.Id
                sessionId = $proc.SessionId
                secondsToWindow = [math]::Round(((Get-Date) - $start).TotalSeconds, 1)
                windowFound = $lw.windowFound
                window = $windowFacts
                processAliveAfter3s = $stillAlive
                mainModulePath = $mainModulePath
                mainModuleMatchesInstalledExe = ($mainModulePath -and $mainModulePath -eq $appExe)
                windowStillValidAfter3s = $windowStillValid
            }
            loginToDashboard = $flow
            databaseAfterLogin = $dbAfterLogin
        }
        Save-Json -Name '17-second-launch-result.json' -Object $result
        if (-not $stillAlive) { throw 'second launch: process exited within 3s' }
        if (-not $windowStillValid) { throw 'second launch: window invalid after 3s' }
        if (-not $flow.dashboardReached) { throw 'second launch: dashboard not reached after reinstall' }
        $script:launch2 = [ordered]@{ handle = $handle; proc = $proc; result = $result }
        $result
    }

    # --------------------------------------------------------------- close2
    Invoke-Step -Name 'close2' -Fatal {
        $closeResult = Close-WindowGracefully -Handle $script:launch2.handle -Process $script:launch2.proc -TimeoutSec $cfg.launchTimeoutsSec.close
        Start-Sleep -Seconds 2
        $orphans = Get-MuamanProcessIds
        $result = [ordered]@{
            close = $closeResult
            dbStillPresentAfterSecondClose = Test-Path -LiteralPath $dbPath
            orphanProcessIds = $orphans
        }
        Save-Json -Name '17-second-launch-close.json' -Object $result
        if (-not $closeResult.exited) { throw 'second launch: app did not exit after WM_CLOSE' }
        if ($orphans.Count -gt 0) { throw "second launch: orphan processes remain: $($orphans -join ', ')" }
        $result
    }

    # ----------------------------------------------------------- final state
    Invoke-Step -Name 'finalState' {
        $result = [ordered]@{
            appProcessIds = Get-MuamanProcessIds
            uninstallerProcessIds = Get-UninstallerProcessIds
            installDirExists = Test-Path -LiteralPath $installDir
            appExeExists = Test-Path -LiteralPath $appExe
            dbStillPresent = Test-Path -LiteralPath $dbPath
            hkcuMuamanUninstallKeys = Get-HkcuUninstallMuamanKeys -Root $uninstallRoot -DisplayName $cfg.uninstall.displayName -Publisher $cfg.uninstall.publisher -KeySuffix $cfg.uninstall.keySuffix
            installRootListing = Get-DirListing -Root $installDir
            capturedAtUtc = Get-UtcString
        }
        Save-Json -Name '20-final-state.json' -Object $result
        $result
    }

    # ----------------------------------------------------------- summary
    $allPassed = ($script:allFailed.Count -eq 0)
    $summary = [ordered]@{
        runId = $RunId
        phase = 'MUAMAN-13Q'
        startedAtUtc = $capturedAtStart
        finishedAtUtc = Get-UtcString
        workerUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        allStepsPassed = $allPassed
        failedSteps = $script:allFailed
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
        phase = 'MUAMAN-13Q'
        startedAtUtc = $capturedAtStart
        finishedAtUtc = Get-UtcString
        workerUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        allStepsPassed = $false
        failedSteps = $script:allFailed
        fatalError = $_.Exception.Message
        steps = $steps
    }
    Save-Json -Name 'worker-done.json' -Object $summary
    Log "RUN FAILED fatal=$($_.Exception.Message)"
    exit 2
} finally {
    Restore-SystemSleep
}
