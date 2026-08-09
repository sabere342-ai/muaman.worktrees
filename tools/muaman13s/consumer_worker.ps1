# consumer_worker.ps1 - MUAMAN-13S worker.
# Runs AS the independent fresh standard user (launched by the orchestrator via
# CreateProcessWithLogonW). Models an actual Windows recipient who received only
# the governed delivery ZIP into their own Downloads folder:
#
#   S0  receive the staged ZIP into the recipient Downloads area
#   S1  verify the received ZIP (sha256 + size)
#   S2  extract the ZIP (Windows-explorer-equivalent unzip)
#   S3  confirm the delivery contains EXACTLY the 3 documented files
#   S4  verify each extracted file identity (installer, README, SHA256SUMS)
#   S5  README content readiness (no dev paths / placeholders / secrets)
#   S6  cross-check SHA256SUMS entries against the extracted files
#   S7  install from the extracted delivery ONLY
#   S8  verify installed payload + registration
#   S9  first launch -> first-owner setup -> login -> dashboard
#  S10  clean close
#  S11  relaunch -> login directly (owner persisted, no re-setup) -> dashboard
#  S12  final persisted state
#
# The worker is deliberately given NO repository path: its parameters reference
# only the consumer workspace, a neutral staging path, the evidence root and the
# (self-contained) config copy. Independence is proven by gate S01 (recorded
# command line + env + config contain no repo sentinel).
#
# Environment variables set by the orchestrator:
#   M13S_OWNER_DISPLAYNAME, M13S_OWNER_USERNAME, M13S_OWNER_PASSWORD, M13S_RESTRICTED_PATH
#
# IMPORTANT: this file is ASCII-only. Arabic UI strings are read from ui_strings.json.

#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$RunId,
    [Parameter(Mandatory = $true)][string]$ExpectedUserName,
    [Parameter(Mandatory = $true)][string]$ConsumerWorkspace,
    [Parameter(Mandatory = $true)][string]$StagedZip,
    [Parameter(Mandatory = $true)][string]$EvidenceRoot,
    [Parameter(Mandatory = $true)][string]$UiStringsPath,
    [Parameter(Mandatory = $true)][string]$ConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# The native window/OCR stack captures at physical pixel resolution when this
# process is DPI-aware; OCR word coordinates are then used 1:1 with the window
# rect (DpiScale=1.0). Must be set before common.ps1 loads M13PWinNative.
$env:M13P_DPI_AWARE = '1'

. (Join-Path $PSScriptRoot 'lib\common.ps1')
. (Join-Path $PSScriptRoot 'delivery_validation.ps1')

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
$script:allFailed = @()

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

function Get-MuamanProcessIds {
    $ids = @(Get-Process -Name 'muaman_store' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)
    return ,$ids
}

# Bounded, timestamped polling.
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

# Full installed-payload comparison against the identities embedded in the
# self-contained acceptance config (no external manifest required).
function Test-InstalledPayloadFromConfig {
    param(
        [string]$InstallDir,
        $AppCfg
    )
    $installed = Get-DirListing -Root $InstallDir -IncludeSha
    $manifestMap = @{}
    foreach ($f in $AppCfg.payload) { $manifestMap[$f.rel] = $f }

    $payload = @()
    $unexpected = @()
    $installedMap = @{}
    foreach ($f in $installed) { $installedMap[$f.rel -replace '\\', '/'] = $f }

    foreach ($f in $AppCfg.payload) {
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
        if (-not $isPayload -and -not $isInnoExtra) {
            $unexpected += $rel
        }
    }

    $installedExe = $installedMap[$AppCfg.mainExecutable]
    $installedExeSize = if ($installedExe) { $installedExe.size } else { $null }
    $installedExeSha = if ($installedExe) { $installedExe.sha256 } else { $null }
    $flutterDll = $installedMap['flutter_windows.dll']
    $flutterDllSha = if ($flutterDll) { $flutterDll.sha256 } else { $null }
    return [ordered]@{
        installDir = $InstallDir
        payloadFileCountExpected = $AppCfg.payload.Count
        payloadFileCountInstalled = $payload.Count
        payloadAllMatch = (@($payload | Where-Object { -not $_.match }).Count -eq 0)
        payload = $payload
        innoUninstallerExtrasPresent = @($innoExtras | Where-Object { $installedMap.ContainsKey($_) })
        unexpectedFiles = $unexpected
        mainExecutable = $AppCfg.mainExecutable
        exeSizeMatch = ($null -ne $installedExe -and $installedExeSize -eq $AppCfg.exeSizeBytes)
        exeSha256Match = ($null -ne $installedExe -and $installedExeSha -eq $AppCfg.exeSha256)
        exeInstalledSize = $installedExeSize
        exeInstalledSha256 = $installedExeSha
        flutterWindowsDllSha256 = $flutterDllSha
    }
}

# Drive the first-owner setup screen through owner creation (accepted 13P flow).
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

# Drive the login screen to the dashboard.
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

# Relaunch must reach LOGIN directly (owner persisted): assert the first-owner
# setup screen never appears within a bounded window, then login -> dashboard.
function Drive-RelaunchToDashboard {
    param(
        [IntPtr]$Handle,
        [string]$Tag,
        [hashtable]$Owner,
        [int]$TransitionTimeoutSec = 60
    )
    $h = $Handle
    $setupNeverSeen = $true
    $loginReached = $false
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $TransitionTimeoutSec) {
        $shot = Join-Path $ShotsDir "$Tag-relaunch.png"
        $capNote = Capture-AppWindowPng -Handle $h -File $shot
        $words = @(Invoke-OcrFile -Path $shot -LanguageTag 'ar-SA')
        $setupHit = Find-OcrWordByParts -Words $words -Parts @($U.setup.title -split '\s+')
        $loginTitleHit = Find-OcrWordByParts -Words $words -Parts @($U.login.title -split '\s+')
        $btnHit = Find-OcrWordByParts -Words $words -Parts @($U.login.buttonLogin -split '\s+')
        if ($null -ne $setupHit) { $setupNeverSeen = $false; break }
        if ($null -ne $loginTitleHit -and $null -ne $btnHit) { $loginReached = $true; break }
        Start-Sleep -Milliseconds 800
    }
    if (-not $setupNeverSeen -or -not $loginReached) { throw 'relaunch: setup screen reappeared OR login not reached' }
    Save-OcrDump -Name "$Tag-relaunch-login.txt" -Words $words

    $fieldDefs = [ordered]@{
        user = [ordered]@{ label = $U.login.fieldUsername; value = $Owner.ownerUsername }
        pass = [ordered]@{ label = $U.login.fieldPassword; value = $Owner.ownerPassword; secret = $true }
    }
    $methods = Invoke-OcrFieldFlow -Handle $h -FieldDefs $fieldDefs -ShotDir $ShotsDir -Tag $Tag
    $btnParts = @($U.login.buttonLogin -split '\s+')
    $btn = Click-OcrButtonByParts -Handle $h -Parts $btnParts -ShotDir $ShotsDir -Tag ($Tag + '-b') -Transient
    if (-not $btn.clicked) { throw 'relaunch: login button not found via OCR' }

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
    if (-not $dashboardReached) { throw 'relaunch: dashboard not reached after login' }
    Save-OcrDump -Name "$Tag-dashboard.txt" -Words $wordsDash

    return [ordered]@{
        setupNeverSeen = $setupNeverSeen
        loginReached = $loginReached
        loginMethods = $methods
        loginButton = $btn
        dashboardReached = $dashboardReached
        relaunchScreenshot = $shot
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

try {

    Initialize-WinNative
    [void][M13PWinNative]::SetProcessDPIAware()
    Prevent-SystemSleep

    $cfg = Read-JsonUtf8 -Path $ConfigPath
    $U = Read-JsonUtf8 -Path $UiStringsPath

    $ownerDisplay = $env:M13S_OWNER_DISPLAYNAME
    $ownerUsername = $env:M13S_OWNER_USERNAME
    $ownerPassword = $env:M13S_OWNER_PASSWORD
    $restrictedPath = $env:M13S_RESTRICTED_PATH
    if (-not $ownerDisplay -or -not $ownerUsername -or -not $ownerPassword -or -not $restrictedPath) {
        throw 'Missing required environment variables (M13S_OWNER_* / M13S_RESTRICTED_PATH)'
    }
    $Owner = @{
        ownerDisplay = $ownerDisplay
        ownerUsername = $ownerUsername
        ownerPassword = $ownerPassword
    }

    $localAppData = $env:LOCALAPPDATA
    $appData = $env:APPDATA
    $installDir = Join-Path (Join-Path $localAppData 'Programs') $cfg.application.appDirName
    $appExe = Join-Path $installDir $cfg.application.mainExecutable
    $dbRel = ($cfg.data.ffiDbRelDir -replace '/', '\') + '\' + $cfg.data.dbFileName
    $dbPath = Join-Path $installDir $dbRel
    $uninstallKey = $cfg.uninstallKey
    $startMenuLink = Join-Path (Join-Path $appData 'Microsoft\Windows\Start Menu\Programs') ($cfg.application.appDirName + '.lnk')

    # Consumer workspace layout (the recipient's own Downloads area).
    $receivedDir = Join-Path $ConsumerWorkspace 'received'
    $extractRoot = Join-Path $ConsumerWorkspace 'extracted'
    $zipCopy = Join-Path $receivedDir $cfg.consumer.zipFilename

    # Repo sentinels that must never appear anywhere the worker can see.
    $repoSentinels = @('muaman-13s-independent-real-user', '\muaman\', 'C:\dev', 'OneDrive\Desktop\')

    $runMetadata = [ordered]@{
        runId = $RunId
        phase = 'MUAMAN-13S'
        startedAtUtc = Get-UtcString
        consumerWorkspace = $ConsumerWorkspace
        receivedZip = $zipCopy
        extractRoot = $extractRoot
        installDir = $installDir
        dbPath = $dbPath
        commandLine = [Environment]::CommandLine
    }

    # Fresh-consumer reset: everything under these paths is owned by this user
    # (their own profile), so each run starts clean with no leftovers from an
    # earlier run (e.g. a persisted business DB inside the install dir).
    $resetDetails = [ordered]@{}
    foreach ($target in @(
        @{ name = 'installDir'; path = $installDir },
        @{ name = 'consumerWorkspace'; path = $ConsumerWorkspace }
    )) {
        if (Test-Path -LiteralPath $target.path) {
            Remove-Item -LiteralPath $target.path -Recurse -Force
            $resetDetails[$target.name] = 'removed'
        } else {
            $resetDetails[$target.name] = 'absent'
        }
    }
    $runMetadata['priorStateReset'] = $resetDetails
    Save-Json -Name '01-run-metadata.json' -Object $runMetadata

    Log "RUN BEGIN runId=$RunId user=$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"

    # ----------------------------------------------------- S0 receive the ZIP
    Invoke-Step -Name 'receive' -Fatal {
        if (-not (Test-Path -LiteralPath $StagedZip -PathType Leaf)) { throw "staged zip missing: $StagedZip" }
        New-Item -ItemType Directory -Path $receivedDir -Force | Out-Null
        $stagedHashBefore = Get-FileSha256Hex -Path $StagedZip
        Copy-Item -LiteralPath $StagedZip -Destination $zipCopy -Force
        $receivedHash = Get-FileSha256Hex -Path $zipCopy
        $result = [ordered]@{
            step = 'S0-receive-zip'
            stagedZip = $StagedZip
            receivedZip = $zipCopy
            stagedSha256 = $stagedHashBefore
            receivedSha256 = $receivedHash
            copyPreservedBytes = ($stagedHashBefore -eq $receivedHash)
            receivedDirExists = Test-Path -LiteralPath $receivedDir
        }
        Save-Json -Name '02-receive.json' -Object $result
        if (-not $result.copyPreservedBytes) { throw 'received ZIP copy does not match staged ZIP (byte-identical copy required)' }
        $result
    }

    # ------------------------------------------------------------------ identity
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
        $cmdLine = [Environment]::CommandLine
        $configText = [System.IO.File]::ReadAllText($ConfigPath)
        $repoSentinelHits = @()
        foreach ($s in $repoSentinels) {
            if ($cmdLine.IndexOf($s, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) { $repoSentinelHits += "cmdline:$s" }
            if ($configText.IndexOf($s, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) { $repoSentinelHits += "config:$s" }
        }
        $envRepo = $env:MUAMAN_REPO -or $env:REPO_ROOT -or $env:WORKTREE -or $env:M13S_REPO
        if ($envRepo) { $repoSentinelHits += "env:repo-path-var" }
        $result = [ordered]@{
            whoamiUser = (& whoami) -join ''
            tokenName = $id.name
            tokenSid = $id.sid
            expectedUserName = $ExpectedUserName
            tokenNameMatchesExpected = ($id.name -like "*\$ExpectedUserName")
            localUserExists = ($null -ne $localUser)
            localUserSid = if ($localUser) { $localUser.SID.Value } else { $null }
            groupMembership = $membership
            inAdministrators = ($membership -contains 'Administrators')
            integrity = $integrity
            elevation = $elev
            session = $session
            isInteractive = $id.isInteractive
            forbiddenEnabledPrivilegesPresent = $forbiddenPrivs
            restrictedPath = $restrictedPath
            repoSentinelHits = $repoSentinelHits
            repoPathIsolated = ($repoSentinelHits.Count -eq 0)
        }
        Save-Json -Name '03-identity.json' -Object $result
        if (-not $result.repoPathIsolated) { throw "repo sentinels visible to worker: $($repoSentinelHits -join ', ')" }
        if ($result.inAdministrators) { throw 'worker is in Administrators' }
        $result
    }

    # ------------------------------------------------------- S1 verify received
    Invoke-Step -Name 'verifyDelivery' -Fatal {
        $verify = Test-DeliveryZipIdentity -ZipPath $zipCopy -ExpectedSha256 $cfg.delivery.zipSha256 -ExpectedSize $cfg.delivery.zipSizeBytes
        $result = [ordered]@{
            step = 'S1-verify-received-zip'
            zipPath = $zipCopy
            zipCopyExists = Test-Path -LiteralPath $zipCopy -PathType Leaf
            verify = $verify
        }
        Save-Json -Name '04-delivery-verify.json' -Object $result
        if (-not $verify.pass) { throw "received ZIP identity mismatch: $($verify.reason)" }
        $result
    }

    # ----------------------------------------------- S2 extract + S3 exact-3 + S4..S6
    Invoke-Step -Name 'extractAndVerify' -Fatal {
        if (Test-Path -LiteralPath $extractRoot) { Remove-Item -LiteralPath $extractRoot -Recurse -Force }
        New-Item -ItemType Directory -Path $extractRoot -Force | Out-Null
        $expand = Expand-DeliveryArchive -ZipPath $zipCopy -DestRoot $extractRoot -ExpectedExtractDirName $cfg.consumer.extractDirName
        if (-not $expand.pass) { throw "extraction failed: $($expand.reason)" }
        $extractDir = $expand.extractDir

        $exactSet = Test-ExactFileSet -ExtractRoot $extractDir -ExpectedFiles $cfg.consumer.expectedExtractFiles
        if (-not $exactSet.pass) { throw "exact file set mismatch: $($exactSet.reason)" }

        $validation = Invoke-DeliveryPackageValidation -ExtractRoot $extractDir -Identities $cfg `
            -ReadmeForbidden $cfg.readmeChecks.forbiddenSubstrings -ReadmeMustContain $cfg.readmeChecks.mustContain
        if (-not $validation.pass) { throw "delivery package validation failed at $($validation.failedStep): $($validation.reason)" }

        $result = [ordered]@{
            stepS2 = 'S2-extract'
            stepS3 = 'S3-exact-three-files'
            stepS4 = 'S4-file-identities'
            stepS5 = 'S5-readme-content'
            stepS6 = 'S6-manifest-crosscheck'
            zipCopy = $zipCopy
            expand = $expand
            exactFileSet = $exactSet
            packageValidation = $validation
            extractDir = $extractDir
            extractedInstaller = Join-Path $extractDir $cfg.installer.filename
        }
        Save-Json -Name '05-extract-verify.json' -Object $result
        $result
    }

    # ------------------------------------------------------- pre-install state
    Invoke-Step -Name 'preInstallState' -Fatal {
        $hkcuMuamanKeys = Get-HkcuUninstallMuamanKeys -Root 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall' -DisplayName 'muaman_store' -Publisher 'muaman_store' -KeySuffix ('{' + $cfg.application.appId + '}_is1')
        $result = [ordered]@{
            installDir = $installDir
            installDirExistsBefore = Test-Path -LiteralPath $installDir
            appExeExistsBefore = Test-Path -LiteralPath $appExe
            hkcuMuamanUninstallKeys = $hkcuMuamanKeys
            uninstallRegistrationAbsent = ($hkcuMuamanKeys.Count -eq 0)
            appProcessIdsBefore = Get-MuamanProcessIds
        }
        Save-Json -Name '06-preinstall-state.json' -Object $result
        $result
    }

    # ------------------------------------------------- S7 install from delivery
    Invoke-Step -Name 'install' -Fatal {
        $extractInfo = Read-JsonUtf8 -Path (Join-Path $JsonDir '05-extract-verify.json')
        $extractedInstaller = [string]$extractInfo.extractedInstaller
        $extractDir = [string]$extractInfo.extractDir
        if (-not (Test-Path -LiteralPath $extractedInstaller -PathType Leaf)) { throw 'extracted installer missing' }
        $installerSha = Get-FileSha256 -Path $extractedInstaller
        if ($installerSha -ne $cfg.installer.sha256) { throw 'extracted installer hash mismatch before install' }
        $installLog = Join-Path (Split-Path -Parent $LogFile) 'install.log'
        $envMap = New-RestrictedEnvironment -RestrictedPath $restrictedPath
        $args = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /LOG="' + $installLog + '"'
        $commandLine = "`"$extractedInstaller`" $args"
        $start = Get-Date
        $r = Start-ChildProcess -FilePath $extractedInstaller -Arguments $args -WorkingDir $installDir -Environment $envMap -TimeoutMs 300000
        $durationSec = [math]::Round(((Get-Date) - $start).TotalSeconds, 1)
        $installedExists = Test-Path -LiteralPath $appExe
        $result = [ordered]@{
            step = 'S7-install-from-delivery'
            commandLine = $commandLine
            installerPath = $extractedInstaller
            installerWithinExtractedDelivery = $extractedInstaller.StartsWith($extractDir, [System.StringComparison]::OrdinalIgnoreCase)
            installerSha256 = $installerSha
            exitCode = $r.exitCode
            timedOut = $r.timedOut
            durationSec = $durationSec
            installLogPath = $installLog
            installLogBytes = if (Test-Path -LiteralPath $installLog) { (Get-Item -LiteralPath $installLog).Length } else { 0 }
            appExeExists = $installedExists
            installDir = $installDir
        }
        Save-Json -Name '07-install.json' -Object $result
        if ($r.timedOut) { throw "installer timed out (exit=$($r.exitCode))" }
        if ($r.exitCode -ne 0) { throw "installer exit code $($r.exitCode)" }
        if (-not $installedExists) { throw 'installed exe not found after install' }
        if (-not $result.installerWithinExtractedDelivery) { throw 'installer path not within extracted delivery' }
        $result
    }

    # ----------------------------------------------------- S8 installed payload
    Invoke-Step -Name 'installedState' -Fatal {
        $hkcuUninstall = Get-RegKeySnapshot -Path $uninstallKey
        $payload = Test-InstalledPayloadFromConfig -InstallDir $installDir -AppCfg $cfg.application
        $machineStartMenuLink = Join-Path (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs') ($cfg.application.appDirName + '.lnk')
        $result = [ordered]@{
            step = 'S8-installed-payload'
            uninstallKey = $uninstallKey
            hkcuUninstallPresent = ($null -ne $hkcuUninstall)
            hkcuUninstall = $hkcuUninstall
            startMenuLink = $startMenuLink
            startMenuLinkExists = Test-Path -LiteralPath $startMenuLink
            machineStartMenuLinkExists = Test-Path -LiteralPath $machineStartMenuLink
            payload = $payload
        }
        Save-Json -Name '08-installed-state.json' -Object $result
        if (-not $result.hkcuUninstallPresent) { throw 'uninstall registration missing after install' }
        if (-not $payload.payloadAllMatch) { throw 'payload mismatch after install' }
        if ($payload.unexpectedFiles.Count -gt 0) { throw "unexpected files after install: $($payload.unexpectedFiles -join ', ')" }
        if (-not $payload.exeSha256Match) { throw 'main executable hash mismatch after install' }
        if ($payload.flutterWindowsDllSha256 -ne $cfg.application.flutterWindowsDllSha256) { throw 'flutter_windows.dll hash mismatch after install' }
        $result
    }

    # ------------------------------------------- S9 first launch -> setup -> dashboard
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
            step = 'S9-first-launch'
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
            setupToLogin = $flow
            loginToDashboard = $flow2
            databaseAfterSetup = $db
        }
        Save-Json -Name '09-first-launch.json' -Object $result
        if (-not $stillAlive) { throw 'first launch: process exited within 3s' }
        if (-not $windowStillValid) { throw 'first launch: window invalid after 3s' }
        if (-not $flow.setupTitleFound) { throw 'first launch: setup screen not reached' }
        if (-not $flow2.dashboardReached) { throw 'first launch: usable dashboard state not reached' }
        if (-not ($db.dbExists -and $db.sqliteHeaderValid -and ($db.tablesFound -contains 'users') -and $db.ownerUsernameTextPresent)) {
            throw 'first launch: business database not created correctly'
        }
        $script:launch1 = [ordered]@{ handle = $handle; proc = $proc; result = $result }
        $result
    }

    # --------------------------------------------------------- S10 clean close
    Invoke-Step -Name 'close1' -Fatal {
        $closeResult = Close-WindowGracefully -Handle $script:launch1.handle -Process $script:launch1.proc -TimeoutSec $cfg.launchTimeoutsSec.close
        Start-Sleep -Seconds 2
        $orphans = Get-MuamanProcessIds
        $result = [ordered]@{
            step = 'S10-clean-close'
            close = $closeResult
            dbStillPresentAfterClose = Test-Path -LiteralPath $dbPath
            orphanProcessIds = $orphans
        }
        Save-Json -Name '10-close.json' -Object $result
        if (-not $closeResult.exited) { throw 'close: app did not exit after WM_CLOSE' }
        if ($orphans.Count -gt 0) { throw "close: orphan processes remain: $($orphans -join ', ')" }
        $result
    }

    # ------------------------------- S11 relaunch (login directly) + S12 persist
    Invoke-Step -Name 'launch2' -Fatal {
        $envMap = New-RestrictedEnvironment -RestrictedPath $restrictedPath
        $start = Get-Date
        $lw = Get-LaunchWindow -Exe $appExe -WorkDir $installDir -Environment $envMap -TimeoutSec $cfg.launchTimeoutsSec.windowSubsequent
        $proc = $lw.proc
        $handle = $lw.handle
        if (-not $lw.windowFound) { throw 'relaunch: no main window' }
        $windowFacts = Get-WindowFacts -Handle $handle
        $windowFacts['rect'] = Get-WindowRectOut -Handle $handle
        $shot = Join-Path $ShotsDir '11-launch2-window.png'
        Capture-WindowPng -Handle $handle -File $shot | Out-Null
        $windowFacts['screenshot'] = $shot

        Start-Sleep -Seconds 3
        $stillAlive = $false
        try { $proc.Refresh(); $stillAlive = -not $proc.HasExited } catch {}
        $mainModulePath = $null
        try { $mainModulePath = $proc.MainModule.FileName } catch {}
        $windowStillValid = Test-AppWindowReady -Handle $handle

        $flow = Drive-RelaunchToDashboard -Handle $handle -Tag '11r' -Owner $Owner -TransitionTimeoutSec $cfg.launchTimeoutsSec.screenTransition
        $db = Get-DbFacts -DbPath $dbPath -OwnerUsername $ownerUsername

        $result = [ordered]@{
            step = 'S11-relaunch-persisted'
            relaunch = [ordered]@{
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
            relaunchToDashboard = $flow
            databaseAfterRelaunch = $db
        }
        Save-Json -Name '11-relaunch.json' -Object $result
        if (-not $stillAlive) { throw 'relaunch: process exited within 3s' }
        if (-not $windowStillValid) { throw 'relaunch: window invalid after 3s' }
        if (-not $flow.setupNeverSeen) { throw 'relaunch: setup screen reappeared (owner NOT persisted)' }
        if (-not $flow.loginReached) { throw 'relaunch: login not reached' }
        if (-not $flow.dashboardReached) { throw 'relaunch: dashboard not reached after login' }
        if (-not ($db.dbExists -and $db.sqliteHeaderValid -and ($db.tablesFound -contains 'users') -and $db.ownerUsernameTextPresent)) {
            throw 'relaunch: business database not intact'
        }
        $script:launch2 = [ordered]@{ handle = $handle; proc = $proc; result = $result }
        $result
    }

    # ------------------------------------------------------- S12 final state
    Invoke-Step -Name 'close2' -Fatal {
        $closeResult = Close-WindowGracefully -Handle $script:launch2.handle -Process $script:launch2.proc -TimeoutSec $cfg.launchTimeoutsSec.close
        Start-Sleep -Seconds 2
        $orphans = Get-MuamanProcessIds
        $result = [ordered]@{
            step = 'close2'
            close = $closeResult
            orphanProcessIds = $orphans
            dbStillPresentAfterFinalClose = Test-Path -LiteralPath $dbPath
        }
        Save-Json -Name '12-final-state.json' -Object $result
        if (-not $closeResult.exited) { throw 'final close: app did not exit' }
        if ($orphans.Count -gt 0) { throw "final close: orphan processes remain: $($orphans -join ', ')" }
        $result
    }

} catch {
    Log "FATAL: $($_.Exception.ToString())"
    throw
} finally {
    Restore-SystemSleep
}

$allPassed = (@($steps.Keys | Where-Object { -not $steps[$_].ok }).Count -eq 0)
$failedSteps = @($steps.Keys | Where-Object { -not $steps[$_].ok })

Save-Json -Name 'worker-done.json' -Object ([ordered]@{
    runId = $RunId
    finishedAtUtc = Get-UtcString
    allStepsPassed = $allPassed
    failedSteps = $failedSteps
    steps = $steps
})

Log "RUN END allPassed=$allPassed failedSteps=$($failedSteps -join ',')"
if (-not $allPassed) {
    Write-Output "WORKER FAILED STEPS: $($failedSteps -join ', ')"
    exit 1
}
Write-Output 'WORKER COMPLETE: all steps passed.'
exit 0
