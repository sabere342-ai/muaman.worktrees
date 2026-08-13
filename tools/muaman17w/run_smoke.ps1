# run_smoke.ps1 - MUAMAN-17W interactive Windows smoke acceptance worker.
# IMPORTANT: this file is ASCII-only. Arabic UI strings come from ui_strings.json.
# Drives the GOVERNED Release build (muaman_store.exe) through:
#   first-owner setup -> login -> dashboard -> add product -> create sale ->
#   auto invoice preview -> native Save PDF dialog -> native Open PDF viewer ->
#   native Print dialog (cancel) -> sales history receipt path -> add a
#   sales-only user -> cashier login (history denied) -> logout -> close.
# All interactions use real UI automation (Win32 + WinRT OCR + UIA).

#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$RunId,
    [Parameter(Mandatory = $true)][string]$ReleaseDir,
    [Parameter(Mandatory = $true)][string]$EvidenceRoot,
    [Parameter(Mandatory = $true)]    [string]$UiStringsPath,
    [switch]$ProbeNavMap,
    [switch]$ProbeNavSales,
    [switch]$ProbePriceField,
    [switch]$ProbeAppBar,
    [switch]$ProbeRole
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Native window/OCR stack captures at physical pixels when DPI-aware; OCR word
# coordinates are then used 1:1 with the window rect (DpiScale=1.0). Must be set
# before common.ps1 loads M13PWinNative.
$env:M13P_DPI_AWARE = '1'

. (Join-Path $PSScriptRoot '..\muaman13s\lib\common.ps1')

$LogFile = Join-Path $EvidenceRoot 'logs\worker.log'
$ShotsDir = Join-Path $EvidenceRoot 'shots'
$UiaDir = Join-Path $EvidenceRoot 'uia'
$JsonDir = Join-Path $EvidenceRoot 'json'
$PdfDir = Join-Path $EvidenceRoot 'pdf'
foreach ($d in @($ShotsDir, $UiaDir, $JsonDir, $PdfDir, (Split-Path -Parent $LogFile))) {
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# Script-wide state
$script:SecretTyped = $false
$script:Results = [ordered]@{}
$script:Abort = $false
$script:AppProc = $null
$script:AppHandle = [IntPtr]::Zero

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

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [scriptblock]$Body
    )
    Log "STEP $Name start"
    try {
        $result = & $Body
        if ($null -eq $result) { $result = @{} }
        $script:Results[$Name] = [ordered]@{ ok = $true; at = Get-UtcString; result = $result }
        Log "STEP $Name PASS"
        return $result
    } catch {
        $msg = "$($_.Exception.Message)"
        Log "STEP $Name FAIL: $msg"
        $script:Results[$Name] = [ordered]@{ ok = $false; at = Get-UtcString; error = $msg }
        $script:Abort = $true
        return $null
    }
}

# ---------------- native helpers ----------------

$script:WheelLoaded = $false
function Initialize-WheelNative {
    if ($script:WheelLoaded) { return }
    Add-Type -ReferencedAssemblies @(([System.Drawing.Image].Assembly.Location), ([System.Windows.Forms.Application].Assembly.Location)) -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class W17WheelNative {
    [StructLayout(LayoutKind.Sequential)] public struct INPUT { public uint type; public INPUTUNION u; }
    [StructLayout(LayoutKind.Explicit)] public struct INPUTUNION { [FieldOffset(0)] public MOUSEINPUT mi; }
    [StructLayout(LayoutKind.Sequential)] public struct MOUSEINPUT { public int dx; public int dy; public uint mouseData; public uint dwFlags; public uint time; public UIntPtr dwExtraInfo; }
    [DllImport("user32.dll")] public static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);
    public static void Wheel(int delta) {
        INPUT i = new INPUT();
        i.type = 0;
        i.u.mi.mouseData = (uint)delta;
        i.u.mi.dwFlags = 0x0800;
        i.u.mi.time = 0;
        i.u.mi.dwExtraInfo = UIntPtr.Zero;
        INPUT[] arr = new INPUT[] { i };
        SendInput((uint)arr.Length, arr, Marshal.SizeOf(typeof(INPUT)));
    }
}
'@
    $script:WheelLoaded = $true
}

function Send-WheelDown {
    param([int]$Notches = 2, [int]$DelayMs = 350)
    Initialize-WheelNative
    [W17WheelNative]::Wheel([int](-120 * $Notches))
    Start-Sleep -Milliseconds $DelayMs
}

function Wait-WindowOfPid {
    param(
        [Parameter(Mandatory = $true)][int]$ProcessId,
        [Parameter(Mandatory = $true)][string]$ClassName,
        [int]$TimeoutSec = 30,
        [int]$IntervalMs = 400
    )
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
        $h = Get-WindowByPidClass -ProcessId $ProcessId -ClassName $ClassName
        if ($h -ne [IntPtr]::Zero) { return $h }
        Start-Sleep -Milliseconds $IntervalMs
    }
    return [IntPtr]::Zero
}

function Wait-NoWindowOfPid {
    param(
        [Parameter(Mandatory = $true)][int]$ProcessId,
        [Parameter(Mandatory = $true)][string]$ClassName,
        [int]$TimeoutSec = 30,
        [int]$IntervalMs = 400
    )
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
        $h = Get-WindowByPidClass -ProcessId $ProcessId -ClassName $ClassName
        if ($h -eq [IntPtr]::Zero) { return $true }
        Start-Sleep -Milliseconds $IntervalMs
    }
    return $false
}

# Exact match after Arabic normalization (no edit-distance tolerance). Used for
# click targets where a fuzzy match can pick the wrong sibling label (bottom nav
# items like المبيعات/المرتجعات differ by only a few letters).
function Test-OcrWordExact {
    param([Parameter(Mandatory = $true)][string]$Expected, [Parameter(Mandatory = $true)][string]$OcrWord)
    $a = ConvertTo-OcrNormalized $Expected
    $b = ConvertTo-OcrNormalized $OcrWord
    if ($a.Length -eq 0) { return $false }
    return ($a -ceq $b)
}

# Find OCR words matching any part with the given comparer (default: fuzzy).
function Find-WordsByParts {
    param($Words, [Parameter(Mandatory = $true)][string[]]$Parts, [switch]$Exact)
    $hits = @()
    foreach ($w in $Words) {
        foreach ($p in $Parts) {
            if ([string]::IsNullOrWhiteSpace($p)) { continue }
            $m = if ($Exact) { Test-OcrWordExact $p $w.Text } else { Test-OcrWordSimilar $p $w.Text }
            if ($m) { $hits += $w; break }
        }
    }
    return $hits
}

# Click a bottom-nav tile by its position in the 6-tile RTL bar (0 = rightmost
# dashboard, 1 = inventory, 2 = sales, 3 = returns, 4 = expenses, 5 = stocktake).
# Robust to OCR label noise and to similar labels (المبيعات vs المرتجعات):
# every word that fuzzy-matches ANY nav label is mapped to the tile whose X
# region it falls in; the tile of the requested rank is then clicked.
function Click-NavTileByRank {
    param(
        [Parameter(Mandatory = $true)][IntPtr]$Handle,
        [Parameter(Mandatory = $true)][string[]]$Labels,
        [Parameter(Mandatory = $true)][int]$Rank,
        [Parameter(Mandatory = $true)][string]$ShotDir,
        [Parameter(Mandatory = $true)][string]$Tag,
        [int]$Retries = 5,
        [switch]$Transient
    )
    $Labels = @($Labels | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $wanted = [ordered]@{ clicked = $false; try = 0; rank = $Rank }
    for ($try = 1; $try -le $Retries; $try++) {
        $png = Join-Path $ShotDir "$Tag-cr-t$try.png"
        $null = Capture-AppWindowPng -Handle $Handle -File $png
        $crop = Join-Path $ShotDir "$Tag-cr$try-crop.png"
        $dim = ConvertTo-CroppedPng -Source $png -Dest $crop -X0 0 -Y0 0.86 -X1 1 -Y1 1.0 -Scale 3
        $cw = @(Invoke-OcrFile -Path $crop -LanguageTag 'ar-SA' -DpiScale 1.0)
        $mapped = @()
        foreach ($w in $cw) {
            $mapped += [pscustomobject]@{
                Text = [string]$w.Text
                X = [int]($dim.x0 + $w.X / $dim.scale)
                Y = [int]($dim.y0 + $w.Y / $dim.scale)
                W = [int]($w.W / $dim.scale)
                H = [int]($w.H / $dim.scale)
            }
        }
        $rect = Get-WindowRectOut -Handle $Handle
        $tile = $null
        foreach ($w in $mapped) {
            $m = $false
            foreach ($lb in $Labels) { if (Test-OcrWordSimilar $lb $w.Text) { $m = $true; break } }
            if (-not $m) { continue }
            $cx = $w.X + $w.W / 2
            $r = [int][math]::Floor(($rect.Width - $cx) / 250.0)
            if ($r -eq $Rank) { $tile = $w; break }
        }
        if ($tile) {
            $sx = $rect.Left + [int]($tile.X + $tile.W / 2)
            $sy = $rect.Top + [int]($tile.Y + $tile.H / 2)
            $null = Log "Click-NavTileByRank $Tag rank=$Rank try=$try word='$($tile.Text)' screen=($sx,$sy)"
            [void](Force-ForegroundWindow -Handle $Handle)
            Start-Sleep -Milliseconds 350
            [M13PWinNative]::ClickAt($sx, $sy)
            Start-Sleep -Milliseconds 700
            $wanted.clicked = $true
            $wanted.try = $try
            $wanted.screenX = $sx
            $wanted.screenY = $sy
            $wanted.word = $tile.Text
            if ($Transient) {
                Remove-OcrTempFile -Path $png
                Remove-OcrTempFile -Path $crop
            }
            return $wanted
        }
        if ($Transient) {
            Remove-OcrTempFile -Path $png
            Remove-OcrTempFile -Path $crop
        }
        Start-Sleep -Milliseconds 700
    }
    Save-OcrDump -Name "$Tag-strip-ocrdump.txt" -Words $mapped
    $null = Log "Click-NavTileByRank FAIL $Tag rank=$Rank (strip OCR dumped, $($mapped.Count) words)"
    return $wanted
}

function Capture-Around {
    param(
        [Parameter(Mandatory = $true)][IntPtr]$Handle,
        [Parameter(Mandatory = $true)][string]$File,
        [switch]$Transient
    )
    $cap = Capture-AppWindowPng -Handle $Handle -File $File
    if ($Transient) { Remove-OcrTempFile -Path $File }
    return $cap
}

# Crop a PNG region (relative coords) and upscale it. Returns the source-pixel
# origin and scale so OCR coords can be mapped back to the original image space.
function ConvertTo-CroppedPng {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Dest,
        [double]$X0 = 0, [double]$Y0 = 0, [double]$X1 = 1, [double]$Y1 = 1,
        [int]$Scale = 3
    )
    Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
    $src = [System.Drawing.Image]::FromFile($Source)
    $w0 = $src.Width; $h0 = $src.Height
    $rx0 = [int][math]::Floor($w0 * $X0); $ry0 = [int][math]::Floor($h0 * $Y0)
    $rx1 = [int][math]::Ceiling($w0 * $X1); $ry1 = [int][math]::Ceiling($h0 * $Y1)
    $cw = $rx1 - $rx0; $ch = $ry1 - $ry0
    $bw = $cw * $Scale; $bh = $ch * $Scale
    $bmp = New-Object System.Drawing.Bitmap($bw, $bh)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($src, (New-Object System.Drawing.Rectangle(0, 0, $bw, $bh)), (New-Object System.Drawing.Rectangle($rx0, $ry0, $cw, $ch)), [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose(); $src.Dispose()
    $bmp.Save($Dest, [System.Drawing.Imaging.ImageFormat]::Png)
    $dim = [ordered]@{ w = $bw; h = $bh; x0 = $rx0; y0 = $ry0; scale = $Scale }
    $bmp.Dispose()
    return $dim
}

# Click an OCR word inside a cropped+upscaled region (bottom nav bars and other
# low-contrast strips that full-window OCR cannot read). Coordinates are mapped
# back to the original window image space before clicking.
function Click-OcrCropped {
    param(
        [Parameter(Mandatory = $true)][IntPtr]$Handle,
        [Parameter(Mandatory = $true)][string[]]$Parts,
        [Parameter(Mandatory = $true)][string]$ShotDir,
        [Parameter(Mandatory = $true)][string]$Tag,
        [double]$X0 = 0, [double]$Y0 = 0, [double]$X1 = 1, [double]$Y1 = 1,
        [int]$Scale = 3,
        [int]$Retries = 5,
        [switch]$Transient,
        [switch]$Exact
    )
    $Parts = @(Expand-OcrParts -Parts $Parts)
    for ($try = 1; $try -le $Retries; $try++) {
        $png = Join-Path $ShotDir "$Tag-cr-t$try.png"
        $null = Capture-AppWindowPng -Handle $Handle -File $png
        $crop = Join-Path $ShotDir "$Tag-cr$try-crop.png"
        $dim = ConvertTo-CroppedPng -Source $png -Dest $crop -X0 $X0 -Y0 $Y0 -X1 $X1 -Y1 $Y1 -Scale $Scale
        $cw = @(Invoke-OcrFile -Path $crop -LanguageTag 'ar-SA' -DpiScale 1.0)
        $mapped = @()
        foreach ($w in $cw) {
            $mapped += [pscustomobject]@{
                Text = [string]$w.Text
                X = [int]($dim.x0 + $w.X / $dim.scale)
                Y = [int]($dim.y0 + $w.Y / $dim.scale)
                W = [int]($w.W / $dim.scale)
                H = [int]($w.H / $dim.scale)
            }
        }
        $hits = @(Find-WordsByParts -Words $mapped -Parts $Parts -Exact:$Exact)
        if ($hits.Count -gt 0) {
            $w = @($hits | Sort-Object Y -Descending)[0]
            $rect = Get-WindowRectOut -Handle $Handle
            $sx = $rect.Left + [int]($w.X + $w.W / 2)
            $sy = $rect.Top + [int]($w.Y + $w.H / 2)
            $null = Log "Click-OcrCropped $Tag try=$try hit='$($w.Text)' imgX=$([int]($w.X + $w.W/2)) imgY=$([int]($w.Y + $w.H/2)) screen=($sx,$sy) exact=$Exact"
            [void](Force-ForegroundWindow -Handle $Handle)
            Start-Sleep -Milliseconds 350
            [M13PWinNative]::ClickAt($sx, $sy)
            Start-Sleep -Milliseconds 700
            if ($Transient) {
                Remove-OcrTempFile -Path $png
                Remove-OcrTempFile -Path $crop
            }
            return [ordered]@{ clicked = $true; try = $try; screenX = $sx; screenY = $sy; word = $w.Text }
        }
        if ($Transient) {
            Remove-OcrTempFile -Path $png
            Remove-OcrTempFile -Path $crop
        }
        Start-Sleep -Milliseconds 700
    }
    $null = Log "Click-OcrCropped FAIL $Tag (last strip OCR $($mapped.Count) words)"
    return [ordered]@{ clicked = $false; try = $Retries }
}

# Expand a parts array into its whitespace-separated tokens. Callers sometimes
# pass a whole button phrase ("إنشاء حساب المالك") as a single element; OCR
# yields individual words, so phrase-level matching can never hit.
function Expand-OcrParts {
    param([Parameter(Mandatory = $true)][string[]]$Parts)
    $out = @()
    foreach ($p in $Parts) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        $out += @($p -split '\s+')
    }
    return $out
}

# Click the bottom-most OCR word similar to any part, optionally limited to the
# top part of the window (dialogs sit center; FABs/nav sit at the bottom).
function Click-OcrSimilar {
    param(
        [Parameter(Mandatory = $true)][IntPtr]$Handle,
        [Parameter(Mandatory = $true)][string[]]$Parts,
        [Parameter(Mandatory = $true)][string]$ShotDir,
        [Parameter(Mandatory = $true)][string]$Tag,
        [double]$MaxYFrac = 1.0,
        [int]$MaxY = 0,
        [int]$Retries = 5,
        [switch]$Transient
    )
    $Parts = @(Expand-OcrParts -Parts $Parts)
    for ($try = 1; $try -le $Retries; $try++) {
        $png = Join-Path $ShotDir "$Tag-sim-t$try.png"
        $null = Capture-AppWindowPng -Handle $Handle -File $png
        $words = @(Invoke-OcrFile -Path $png -LanguageTag 'ar-SA' -DpiScale 1.0)
        $hits = @(Find-WordsByParts $words $Parts)
        $rect = Get-WindowRectOut -Handle $Handle
        if ($MaxYFrac -lt 1.0) {
            $maxY = [int]($rect.Height * $MaxYFrac)
            $hits = @($hits | Where-Object { $_.Y -le $maxY })
        }
        if ($MaxY -gt 0) { $hits = @($hits | Where-Object { $_.Y -le $MaxY }) }
        if ($hits.Count -gt 0) {
            $w = @($hits | Sort-Object Y -Descending)[0]
            $sx = $rect.Left + [int]($w.X + $w.W / 2)
            $sy = $rect.Top + [int]($w.Y + $w.H / 2)
            [void](Force-ForegroundWindow -Handle $Handle)
            Start-Sleep -Milliseconds 350
            [M13PWinNative]::ClickAt($sx, $sy)
            Start-Sleep -Milliseconds 700
            if ($Transient) { Remove-OcrTempFile -Path $png }
            return [ordered]@{ clicked = $true; try = $try; screenX = $sx; screenY = $sy; word = $w.Text }
        }
        if ($Transient) { Remove-OcrTempFile -Path $png }
        Start-Sleep -Milliseconds 700
    }
    Save-OcrDump -Name "$Tag-sim-ocrdump.txt" -Words $words
    $null = Log "Click-OcrSimilar FAIL $Tag (last frame OCR dumped, $($words.Count) words)"
    return [ordered]@{ clicked = $false; try = $Retries }
}

# Click the bottom-most OCR word EXACTLY equal to a part (button labels).
function Click-OcrExact {
    param(
        [Parameter(Mandatory = $true)][IntPtr]$Handle,
        [Parameter(Mandatory = $true)][string[]]$Parts,
        [Parameter(Mandatory = $true)][string]$ShotDir,
        [Parameter(Mandatory = $true)][string]$Tag,
        [double]$MaxYFrac = 1.0,
        [int]$Retries = 5,
        [switch]$Transient
    )
    $Parts = @(Expand-OcrParts -Parts $Parts)
    for ($try = 1; $try -le $Retries; $try++) {
        $png = Join-Path $ShotDir "$Tag-ex-t$try.png"
        $null = Capture-AppWindowPng -Handle $Handle -File $png
        $words = @(Invoke-OcrFile -Path $png -LanguageTag 'ar-SA' -DpiScale 1.0)
        $btn = $null
        $matchLog = @()
        foreach ($p in $Parts) {
            if ([string]::IsNullOrWhiteSpace($p)) { continue }
            $hits = @($words | Where-Object { $_.Text -eq $p } | Sort-Object Y -Descending)
            $matchLog += ("part=[{0}] hits={1}" -f $p, $hits.Count)
            if ($hits.Count -gt 0) { $btn = $hits[0]; break }
        }
        $null = Log ("Click-OcrExact $Tag try=$try words=$($words.Count) btn=$($null -ne $btn) {$($matchLog -join '; ')}")
        $rect = Get-WindowRectOut -Handle $Handle
        if ($btn -and $MaxYFrac -lt 1.0) {
            if ($btn.Y -gt [int]($rect.Height * $MaxYFrac)) { $btn = $null }
        }
        if ($btn) {
            $sx = $rect.Left + [int]($btn.X + $btn.W / 2)
            $sy = $rect.Top + [int]($btn.Y + $btn.H / 2)
            [void](Force-ForegroundWindow -Handle $Handle)
            Start-Sleep -Milliseconds 350
            [M13PWinNative]::ClickAt($sx, $sy)
            Start-Sleep -Milliseconds 700
            if ($Transient) { Remove-OcrTempFile -Path $png }
            return [ordered]@{ clicked = $true; try = $try; screenX = $sx; screenY = $sy; word = $btn.Text }
        }
        if ($Transient) { Remove-OcrTempFile -Path $png }
        Start-Sleep -Milliseconds 700
    }
    Save-OcrDump -Name "$Tag-ex-ocrdump.txt" -Words $words
    $null = Log "Click-OcrExact FAIL $Tag (last frame OCR dumped, $($words.Count) words)"
    return [ordered]@{ clicked = $false; try = $Retries }
}

# Click an exact word, scrolling down once if not found (ListView overflow).
function Click-ExactWithScroll {
    param(
        [Parameter(Mandatory = $true)][IntPtr]$Handle,
        [Parameter(Mandatory = $true)][string[]]$Parts,
        [Parameter(Mandatory = $true)][string]$ShotDir,
        [Parameter(Mandatory = $true)][string]$Tag,
        [switch]$Transient
    )
    $r = Click-OcrExact -Handle $Handle -Parts $Parts -ShotDir $ShotDir -Tag $Tag -Transient:$Transient
    if ($r.clicked) { return $r }
    $rect = Get-WindowRectOut -Handle $Handle
    [void][M13PWinNative]::SetCursorPos(($rect.Left + [int]($rect.Width / 2)), ($rect.Top + [int]($rect.Height / 2)))
    Start-Sleep -Milliseconds 250
    Send-WheelDown -Notches 3
    $r2 = Click-OcrExact -Handle $Handle -Parts $Parts -ShotDir $ShotDir -Tag ($Tag + 's') -Transient:$Transient
    return $r2
}

# Return $true when none of the parts appear in the cropped OCR region (used to
# detect that a centered dialog has closed; the surrounding screen FAB labels
# must not be visible inside the crop).
function Test-OcrDialogClosed {
    param(
        [Parameter(Mandatory = $true)][IntPtr]$Handle,
        [Parameter(Mandatory = $true)][string[]]$Parts,
        [Parameter(Mandatory = $true)][string]$ShotDir,
        [Parameter(Mandatory = $true)][string]$Tag,
        [double]$X0 = 0, [double]$Y0 = 0, [double]$X1 = 1, [double]$Y1 = 1,
        [int]$Scale = 3
    )
    $png = Join-Path $ShotDir "$Tag-chk.png"
    $null = Capture-AppWindowPng -Handle $Handle -File $png
    $crop = Join-Path $ShotDir "$Tag-chk-crop.png"
    $null = ConvertTo-CroppedPng -Source $png -Dest $crop -X0 $X0 -Y0 $Y0 -X1 $X1 -Y1 $Y1 -Scale $Scale
    $words = @(Invoke-OcrFile -Path $crop -LanguageTag 'ar-SA' -DpiScale 1.0)
    foreach ($w in $words) {
        foreach ($p in $Parts) {
            if ([string]::IsNullOrWhiteSpace($p)) { continue }
            if (Test-OcrWordSimilar $p $w.Text) { return $false }
        }
    }
    return $true
}

# True while the create-user dialog title is visible. The title 'إنشاء مستخدم
# جديد' sits in a centered band (y~150-210); the users FAB text 'مستخدم جديد'
# at y~790 shares the same words and must not count as an open dialog.
function Test-OcrDialogTitleOpen {
    param([Parameter(Mandatory = $true)]$Words, [Parameter(Mandatory = $true)][string[]]$TitleParts)
    $first = @(Expand-OcrParts -Parts $TitleParts)[0]
    foreach ($w in $Words) {
        if ($w.Y -lt 100 -or $w.Y -gt 300) { continue }
        if (Test-OcrWordSimilar $first $w.Text) { return $true }
    }
    return $false
}

# Verify the invoice PREVIEW screen is open. The new-invoice screen also shows
# the word 'الفاتورة' (سلة الفاتورة / إجمالي الفاتورة / حفظ الفاتورة), so the
# preview title 'عرض الفاتورة' alone can false-positive after a misdirected
# click (e.g. a receipt-icon scan that landed on the FAB). Accept only the
# print button 'طباعة' (unique to the preview) or the title pair 'عرض' +
# 'الفاتورة' sharing one row.
function Test-OcrPreviewOpen {
    param([Parameter(Mandatory = $true)]$Words, [Parameter(Mandatory = $true)][string[]]$TitleParts, [Parameter(Mandatory = $true)][string]$PrintWord)
    foreach ($p in @(Expand-OcrParts -Parts @($PrintWord))) {
        if ($null -ne (Find-OcrWordByParts -Words $Words -Parts @($p))) { return $true }
    }
    $parts = @(Expand-OcrParts -Parts $TitleParts)
    if ($parts.Count -ge 2) {
        foreach ($a in @($Words | Where-Object { Test-OcrWordSimilar $parts[0] $_.Text })) {
            foreach ($b in @($Words | Where-Object { Test-OcrWordSimilar $parts[-1] $_.Text })) {
                if ([Math]::Abs($a.Y - $b.Y) -le 14) { return $true }
            }
        }
    }
    return $false
}

# Click the RTL AppBar back arrow (leading, top-right of the client area).
function Click-Back {
    param([Parameter(Mandatory = $true)][IntPtr]$Handle)
    $rect = Get-WindowRectOut -Handle $Handle
    $sx = $rect.Left + $rect.Width - 26
    $sy = $rect.Top + 58
    [void](Force-ForegroundWindow -Handle $Handle)
    Start-Sleep -Milliseconds 350
    [M13PWinNative]::ClickAt($sx, $sy)
    Start-Sleep -Milliseconds 900
    return [ordered]@{ screenX = $sx; screenY = $sy }
}

# Fill a label-above-input form field found by OCR; verifies the typed value's
# trailing probe in the band below the label (or masked state for secrets).
function Fill-Field {
    param(
        [Parameter(Mandatory = $true)][IntPtr]$Handle,
        [Parameter(Mandatory = $true)][string]$Label,
        [string]$Value,
        [Parameter(Mandatory = $true)][string]$ShotDir,
        [Parameter(Mandatory = $true)][string]$Tag,
        [switch]$Secret,
        [switch]$ClickOnly,
        [int]$Retries = 3,
        [int]$BandHeight = 130,
        [int]$XMax = 0,
        [double]$CropX0 = 0, [double]$CropY0 = 0, [double]$CropX1 = 1, [double]$CropY1 = 1,
        [int]$CropScale = 0
    )
    if (-not $ClickOnly -and [string]::IsNullOrWhiteSpace($Value)) { throw "Fill-Field ${Tag}: empty value without -ClickOnly" }
    $parts = @($Label -split '\s+')
    $rect = Get-WindowRectOut -Handle $Handle
    $methods = [ordered]@{ label = $Label; clicked = $false }
    for ($try = 1; $try -le $Retries; $try++) {
        $png = Join-Path $ShotDir "$Tag-field-b$try.png"
        $null = Capture-AppWindowPng -Handle $Handle -File $png
        # Low-contrast dialog regions: crop+upscale so label OCR can read them,
        # then map the OCR words back to window-image coordinates.
        if ($CropScale -gt 0) {
            $crop = Join-Path $ShotDir "$Tag-field$try-crop.png"
            $dim = ConvertTo-CroppedPng -Source $png -Dest $crop -X0 $CropX0 -Y0 $CropY0 -X1 $CropX1 -Y1 $CropY1 -Scale $CropScale
            $raw = @(Invoke-OcrFile -Path $crop -LanguageTag 'ar-SA' -DpiScale 1.0)
            $words = @()
            foreach ($w in $raw) {
                $words += [pscustomobject]@{
                    Text = [string]$w.Text
                    X = [int]($dim.x0 + $w.X / $dim.scale)
                    Y = [int]($dim.y0 + $w.Y / $dim.scale)
                    W = [int]($w.W / $dim.scale)
                    H = [int]($w.H / $dim.scale)
                }
            }
        } else {
            $words = @(Invoke-OcrFile -Path $png -LanguageTag 'ar-SA' -DpiScale 1.0)
        }
        # Centered dialogs: exclude the page content left/right of the dialog so
        # background words at the same Y cannot contaminate label rows.
        if ($XMax -gt 0) { $words = @($words | Where-Object { ($_.X + $_.W) -le $XMax }) }
        # Field labels sit in the right-hand column of the form; centered
        # header/subtitle/button rows must not be candidates (a subtitle word
        # like "الأول" can fuzzy-match the name label "الاسم" after alef
        # normalization). Fall back to any row only when no column row exists,
        # which is the centered-dialog layout.
        $maxRight = [int](@($words | ForEach-Object { $_.X + $_.W } | Measure-Object -Maximum).Maximum)
        $colMinX = [int]($maxRight * 0.7)
        $row = $null
        for ($k = $parts.Count; $k -ge 1 -and $null -eq $row; $k--) {
            $sub = @($parts[0..($k - 1)])
            $rows = @(Find-OcrLabelRows -Words $words -Parts $sub)
            if ($rows.Count -eq 0) { continue }
            $colRows = @($rows | Where-Object { $_.left -ge $colMinX })
            if ($colRows.Count -gt 0) { $row = $colRows[0] }
            elseif ($rows.Count -gt 0) { $row = $rows[0] }
        }
        if ($null -eq $row) {
            if ($Secret) { Remove-OcrTempFile -Path $png }
            Start-Sleep -Milliseconds 700
            continue
        }
        $null = Log "Fill-Field $Tag try=$try row=left:$($row.left) right:$($row.right) top:$($row.top) bottom:$($row.bottom)"
        $cx = [int](($row.left + $row.right) / 2)
        $cy = [int]($row.bottom + 14)
        $sx = $rect.Left + $cx
        $sy = $rect.Top + $cy
        [void](Force-ForegroundWindow -Handle $Handle)
        Start-Sleep -Milliseconds 300
        [M13PWinNative]::ClickAt($sx, $sy)
        Start-Sleep -Milliseconds 500
        [void](Force-ForegroundWindow -Handle $Handle)
        Start-Sleep -Milliseconds 250
        [System.Windows.Forms.SendKeys]::SendWait('^a')
        Start-Sleep -Milliseconds 120
        [System.Windows.Forms.SendKeys]::SendWait('{BACKSPACE}')
        Start-Sleep -Milliseconds 120
        if (-not $ClickOnly) {
            [System.Windows.Forms.SendKeys]::SendWait('{DELETE}')
            Start-Sleep -Milliseconds 150
            [M13PWinNative]::TypeText($Value)
            Start-Sleep -Milliseconds 600
        }

        if ($ClickOnly) {
            $methods.clicked = $true
            $methods.method = "click x=$sx y=$sy (click-only)"
            return $methods
        }

        if ($Secret) {
            $vPng = Join-Path $ShotDir "$Tag-field-secret$try.png"
            $null = Capture-AppWindowPng -Handle $Handle -File $vPng
            $vWords = @(Invoke-OcrFile -Path $vPng -LanguageTag 'ar-SA' -DpiScale 1.0)
            $bandTop = [int]($row.top - 4)
            $bandBot = [int]($row.top + $BandHeight)
            $leak = @($vWords | Where-Object {
                $_.Y -ge $bandTop -and $_.Y -lt $bandBot -and $_.Text -match '[A-Za-z0-9]'
            })
            $leakAny = @($vWords | Where-Object {
                $_.Text.IndexOf((Get-OcrValueProbe -Value $Value), [System.StringComparison]::Ordinal) -ge 0
            })
            Remove-OcrTempFile -Path $vPng
            $script:SecretTyped = $true
            if ($leak.Count -gt 0 -or $leakAny.Count -gt 0) {
                $methods.masked = $false
                Start-Sleep -Milliseconds 700
                continue
            }
            $methods.clicked = $true
            $methods.masked = $true
            $methods.method = "click x=$sx y=$sy masked-verified"
            return $methods
        } else {
            $probe = Get-OcrValueProbe -Value $Value
            $bandOk = $false
            $postPng = Join-Path $ShotDir "$Tag-field-post$try.png"
            for ($v = 1; $v -le 2 -and -not $bandOk; $v++) {
                Start-Sleep -Milliseconds 400
                $null = Capture-AppWindowPng -Handle $Handle -File $postPng
                $postWords = @(Invoke-OcrFile -Path $postPng -LanguageTag 'ar-SA' -DpiScale 1.0)
                $bandTop = [int]($row.top - 4)
                $bandBot = [int]($row.top + $BandHeight)
                $found = @($postWords | Where-Object {
                    $_.Y -ge $bandTop -and $_.Y -lt $bandBot -and
                    $_.Text.IndexOf($probe, [System.StringComparison]::Ordinal) -ge 0
                })
                if ($found.Count -gt 0) { $bandOk = $true }
                elseif ($v -lt 2) {
                    [void](Force-ForegroundWindow -Handle $Handle)
                    Start-Sleep -Milliseconds 250
                    [System.Windows.Forms.SendKeys]::SendWait('^a')
                    Start-Sleep -Milliseconds 120
                    [System.Windows.Forms.SendKeys]::SendWait('{BACKSPACE}')
                    Start-Sleep -Milliseconds 120
                    [System.Windows.Forms.SendKeys]::SendWait('{DELETE}')
                    Start-Sleep -Milliseconds 150
                    [M13PWinNative]::TypeText($Value)
                    Start-Sleep -Milliseconds 500
                }
            }
            if ($Secret) { Remove-OcrTempFile -Path $postPng }
            if (-not $bandOk) {
                $methods.verify = 'probe-not-found'
                $null = Log "Fill-Field $Tag try=$try probe=$probe NOT in band [$bandTop,$bandBot) postWords=$($postWords.Count)"
                Start-Sleep -Milliseconds 700
                continue
            }
            $methods.clicked = $true
            $methods.verify = "band-verified probe=$probe"
            $methods.method = "click x=$sx y=$sy"
            return $methods
        }
    }
    $methods.verify = 'give-up'
    Save-OcrDump -Name "$Tag-field-giveup.txt" -Words $words
    $null = Log "Fill-Field GIVE-UP $Tag (last label OCR dumped, $($words.Count) words)"
    return $methods
}

# Fill the setup/login style forms where labels sit at the top of full-width
# boxes (setup screen and login screen).
function Fill-SimpleFields {
    param(
        [Parameter(Mandatory = $true)][IntPtr]$Handle,
        [Parameter(Mandatory = $true)][System.Collections.IDictionary]$FieldDefs,
        [Parameter(Mandatory = $true)][string]$ShotDir,
        [Parameter(Mandatory = $true)][string]$Tag,
        [int]$XMax = 0,
        [double]$CropX0 = 0, [double]$CropY0 = 0, [double]$CropX1 = 1, [double]$CropY1 = 1,
        [int]$CropScale = 0
    )
    $methods = [ordered]@{}
    foreach ($key in $FieldDefs.Keys) {
        $def = $FieldDefs[$key]
        $isSecret = ((Test-FieldDefHasKey $def 'secret') -and [bool]$def.secret)
        $m = Fill-Field -Handle $Handle -Label ([string]$def.label) -Value ([string]$def.value) -ShotDir $ShotDir -Tag "$Tag-$key" -Secret:$isSecret -XMax $XMax -CropX0 $CropX0 -CropY0 $CropY0 -CropX1 $CropX1 -CropY1 $CropY1 -CropScale $CropScale
        if (-not $m.clicked) { throw "field not filled: $($def.label)" }
        $methods[$key] = $m
    }
    return $methods
}

# Fill a Material TextField whose labelText renders inside the field (hint when
# empty, floating to the top border when focused/filled) - e.g. the invoice
# creation form. Find-OcrLabelRows is not used: sibling labels on the same
# visual row (e.g. 'الكمية:' next to 'سعر البيع') would widen the row and push
# the click X into the gap between fields. Instead the click X is the center of
# the label words themselves and the click Y sits inside the field below the
# label top. Retries step the Y down a few px to absorb OCR drift.
function Fill-FloatingLabelField {
    param(
        [Parameter(Mandatory = $true)][IntPtr]$Handle,
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][string]$Value,
        [Parameter(Mandatory = $true)][string]$ShotDir,
        [Parameter(Mandatory = $true)]        [string]$Tag,
        [int]$Band = 60,
        [int]$XMax = 950
    )
    $parts = @($Label -split '\s+')
    $rect = Get-WindowRectOut -Handle $Handle
    $methods = [ordered]@{ label = $Label; clicked = $false }
    for ($try = 1; $try -le 3; $try++) {
        $png = Join-Path $ShotDir "$Tag-f-b$try.png"
        $null = Capture-AppWindowPng -Handle $Handle -File $png
        $words = @(Invoke-OcrFile -Path $png -LanguageTag 'ar-SA' -DpiScale 1.0)
        $lw = @($words | Where-Object {
            $hit = $false
            foreach ($p in $parts) { if (Test-OcrWordExact $p $_.Text) { $hit = $true; break } }
            $hit
        } | Sort-Object Y)
        if ($lw.Count -lt [math]::Min(2, $parts.Count)) { Start-Sleep -Milliseconds 700; continue }
        $lTop = [int]($lw | ForEach-Object { $_.Y } | Measure-Object -Minimum).Minimum
        $lLeft = [int]($lw | ForEach-Object { $_.X } | Measure-Object -Minimum).Minimum
        $lRight = [int]($lw | ForEach-Object { $_.X + $_.W } | Measure-Object -Maximum).Maximum
        $cx = [int](($lLeft + $lRight) / 2)
        $clickY = [int]($lTop + 16 + ($try - 1) * 4)
        $sx = $rect.Left + $cx
        $sy = $rect.Top + $clickY
        [void](Force-ForegroundWindow -Handle $Handle)
        Start-Sleep -Milliseconds 300
        [M13PWinNative]::ClickAt($sx, $sy)
        Start-Sleep -Milliseconds 500
        [System.Windows.Forms.SendKeys]::SendWait('^a')
        Start-Sleep -Milliseconds 120
        [System.Windows.Forms.SendKeys]::SendWait('{BACKSPACE}')
        Start-Sleep -Milliseconds 120
        [System.Windows.Forms.SendKeys]::SendWait('{DELETE}')
        Start-Sleep -Milliseconds 150
        [M13PWinNative]::TypeText($Value)
        Start-Sleep -Milliseconds 600

        $postPng = Join-Path $ShotDir "$Tag-post$try.png"
        $null = Capture-AppWindowPng -Handle $Handle -File $postPng
        $postWords = @(Invoke-OcrFile -Path $postPng -LanguageTag 'ar-SA' -DpiScale 1.0)
        $probe = Get-OcrValueProbe -Value $Value
        $bandTop = [int]($lTop - 15)
        $bandBot = [int]($lTop + $Band)
        $found = @($postWords | Where-Object {
            ($_.X + $_.W) -le $XMax -and
            $_.Y -ge $bandTop -and $_.Y -lt $bandBot -and
            $_.Text.IndexOf($probe, [System.StringComparison]::Ordinal) -ge 0
        })
        if ($found.Count -gt 0) {
            $methods.clicked = $true
            $methods.verify = "band-verified probe=$probe"
            $methods.method = "click x=$sx y=$sy labelTop=$lTop"
            return $methods
        }
        $null = Log "Fill-FloatingLabelField $Tag try=$try probe=$probe NOT in band [$bandTop,$bandBot)"
        Start-Sleep -Milliseconds 700
    }
    $methods.verify = 'give-up'
    return $methods
}

# Click an element by UIA accessible name (tooltips become names). Falls back to
# an OCR similar-match click when UIA cannot find it.
function Click-UiaByName {
    param(
        [Parameter(Mandatory = $true)][IntPtr]$Handle,
        [Parameter(Mandatory = $true)][string]$Name,
        [int]$TimeoutSec = 20,
        [string]$ShotDir,
        [string]$Tag
    )
    Initialize-Uia
    $root = Get-UiaRootFromHandle -Handle $Handle
    $el = $null
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec -and $null -eq $el) {
        try {
            $el = Find-UiaDescendant -Root $root -Name $Name -Contains
            if ($null -ne $el -and -not $el.Current.IsEnabled) { $el = $null }
        } catch { $el = $null }
        if ($null -eq $el) { Start-Sleep -Milliseconds 500 }
    }
    if ($null -ne $el) {
        try {
            Invoke-UiaElement -Element $el
            Start-Sleep -Milliseconds 900
            return [ordered]@{ via = 'uia-invoke'; name = $Name; found = $true }
        } catch {
            $r = $el.Current.BoundingRectangle
            $sx = [int]($r.X + $r.Width / 2)
            $sy = [int]($r.Y + $r.Height / 2)
            [void](Force-ForegroundWindow -Handle $Handle)
            Start-Sleep -Milliseconds 300
            [M13PWinNative]::ClickAt($sx, $sy)
            Start-Sleep -Milliseconds 900
            return [ordered]@{ via = 'uia-rect'; name = $Name; found = $true; screenX = $sx; screenY = $sy }
        }
    }
    return [ordered]@{ via = 'none'; name = $Name; found = $false }
}

# AppBar icon buttons (users/settings/logout) have tooltips but no OCR text, and
# the Flutter tree exposes no UIA children (only the top-level FLUTTERVIEW pane),
# so click targets are computed from the OCR-visible display-name band in the
# shell AppBar. The actions row is left-anchored in RTL: [logout] [name] [settings]
# [users] on FullAppShell and [logout] [name] on SalesOnlyShell. Each IconButton is
# 48px, so logout sits 24px left of the name, settings 24px right, users 72px
# right. VerifyParts confirms the target screen opened via OCR; between retries a
# mis-clicked offset is backed out so no stray route lingers.
function Click-AppBarIcon {
    param(
        [Parameter(Mandatory = $true)][IntPtr]$Handle,
        [Parameter(Mandatory = $true)][ValidateSet('users', 'settings', 'logout')][string]$Target,
        [Parameter(Mandatory = $true)][string]$ShotDir,
        [Parameter(Mandatory = $true)][string]$Tag,
        [string[]]$VerifyParts = @(),
        [int]$TimeoutSec = 12,
        [int[]]$OffsetDx = @(0, 16, -16, 32),
        # Verify against OCR words only in the AppBar title band and with the
        # leading ال article stripped (for the settings screen, whose title
        # إعدادات التطبيق OCRs without ال and whose bottom إعدادات tile must not
        # count as a match).
        [switch]$VerifyTopBandStripAl
    )
    $rect = Get-WindowRectOut -Handle $Handle
    $words = @()
    $band = @()
    for ($try = 1; $try -le 3; $try++) {
        $png = Join-Path $ShotDir "$Tag-pos-$try.png"
        $null = Capture-AppWindowPng -Handle $Handle -File $png
        $words = @(Invoke-OcrFile -Path $png -LanguageTag 'ar-SA' -DpiScale 1.0)
        $band = @($words | Where-Object { $_.Y -ge 40 -and $_.Y -le 115 -and $_.X -lt 350 })
        if ($band.Count -ge 2) { break }
        Start-Sleep -Milliseconds 700
    }
    if ($band.Count -lt 2) {
        Save-OcrDump -Name "$Tag-pos-ocrdump.txt" -Words $words
        return [ordered]@{ clicked = $false; target = $Target; reason = 'appbar name band not found' }
    }
    $minX = [int](($band | ForEach-Object { $_.X } | Measure-Object -Minimum).Minimum)
    $maxX = [int](($band | ForEach-Object { $_.X + $_.W } | Measure-Object -Maximum).Maximum)
    $nameY = [int](($band | ForEach-Object { $_.Y + $_.H / 2 } | Measure-Object -Average).Average)
    $baseCx = switch ($Target) {
        'users'    { [int]$maxX + 72 }
        'settings' { [int]$maxX + 24 }
        'logout'   { [int]$minX - 24 }
    }
    foreach ($dx in $OffsetDx) {
        $sx = $rect.Left + $baseCx + $dx
        $sy = $rect.Top + $nameY
        $null = Log "Click-AppBarIcon $Target dx=$dx name=[$minX..$maxX]@y=$nameY screen=($sx,$sy)"
        [void](Force-ForegroundWindow -Handle $Handle)
        Start-Sleep -Milliseconds 350
        [M13PWinNative]::ClickAt($sx, $sy)
        Start-Sleep -Milliseconds 1000
        if ($VerifyParts.Count -gt 0) {
            $verified = $false
            $need = [math]::Max(1, [int][math]::Ceiling($VerifyParts.Count / 2))
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
                $chk = Join-Path $ShotDir "$Tag-verify-$dx.png"
                $null = Capture-AppWindowPng -Handle $Handle -File $chk
                $cw = @(Invoke-OcrFile -Path $chk -LanguageTag 'ar-SA' -DpiScale 1.0)
                $hitCount = 0
                foreach ($p in $VerifyParts) {
                    if ([string]::IsNullOrWhiteSpace($p)) { continue }
                    if ($VerifyTopBandStripAl) {
                        $cand = @($cw | Where-Object { $_.Y -ge 30 -and $_.Y -le 95 -and $_.X -ge 500 })
                        if ($cand | Where-Object { Test-OcrStripAl $p $_.Text }) { $hitCount++ }
                    } else {
                        $pn = ConvertTo-OcrNormalized $p
                        $normTexts = @($cw | ForEach-Object { ConvertTo-OcrNormalized $_.Text })
                        if ($normTexts -contains $pn) { $hitCount++ }
                    }
                }
                if ($hitCount -ge $need) { $verified = $true; break }
                Start-Sleep -Milliseconds 600
            }
            if ($verified) {
                return [ordered]@{ clicked = $true; target = $Target; dx = $dx; screenX = $sx; screenY = $sy; nameBand = "$minX..$maxX" }
            }
            [void](Click-Back -Handle $Handle)
            Start-Sleep -Milliseconds 900
        } else {
            return [ordered]@{ clicked = $true; target = $Target; dx = $dx; screenX = $sx; screenY = $sy; nameBand = "$minX..$maxX" }
        }
    }
    return [ordered]@{ clicked = $false; target = $Target; reason = 'no verified target screen' }
}

# Sale-card receipt icons (Icons.receipt_long, Color(0xFF0D47A1)) carry no OCR
# text and are invisible to the flat Flutter UIA tree, so locate them by colour
# in the card list region via a LockBits byte scan. Returns cluster centroids in
# image coordinates sorted by Y (topmost first = newest sale card).
function Find-ColorIconCenters {
    param(
        [Parameter(Mandatory = $true)][string]$PngPath,
        [Parameter(Mandatory = $true)][string]$Hex,
        [int]$Tol = 40,
        [int]$Step = 2,
        [double]$X0 = 0, [double]$Y0 = 0, [double]$X1 = 1, [double]$Y1 = 1,
        [int]$ClusterGap = 26
    )
    Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
    $bmp = [System.Drawing.Bitmap]::FromFile($PngPath)
    $rx0 = [int]($bmp.Width * $X0); $ry0 = [int]($bmp.Height * $Y0)
    $rx1 = [int]($bmp.Width * $X1); $ry1 = [int]($bmp.Height * $Y1)
    $tr = [Convert]::ToInt32($Hex.Substring(0, 2), 16)
    $tg = [Convert]::ToInt32($Hex.Substring(2, 2), 16)
    $tb = [Convert]::ToInt32($Hex.Substring(4, 2), 16)
    $pf = $bmp.PixelFormat
    $bpp = if ($pf -in @([System.Drawing.Imaging.PixelFormat]::Format32bppArgb, [System.Drawing.Imaging.PixelFormat]::Format32bppRgb)) { 4 } else { 3 }
    $data = $bmp.LockBits((New-Object System.Drawing.Rectangle(0, 0, $bmp.Width, $bmp.Height)), [System.Drawing.Imaging.ImageLockMode]::ReadOnly, $pf)
    $stride = $data.Stride
    $bytes = New-Object byte[] ($stride * $bmp.Height)
    [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
    $bmp.UnlockBits($data)
    $bmp.Dispose()
    $clusters = New-Object System.Collections.ArrayList
    for ($y = $ry0; $y -lt $ry1; $y += $Step) {
        $row = $y * $stride
        for ($x = $rx0; $x -lt $rx1; $x += $Step) {
            $i = $row + $x * $bpp
            $b = $bytes[$i]; $g = $bytes[$i + 1]; $r = $bytes[$i + 2]
            if ([Math]::Abs($r - $tr) -gt $Tol -or [Math]::Abs($g - $tg) -gt $Tol -or [Math]::Abs($b - $tb) -gt $Tol) { continue }
            $merged = $null
            foreach ($c in $clusters) {
                $ccx = [int]($c.SX / $c.N); $ccy = [int]($c.SY / $c.N)
                if ([Math]::Abs($ccx - $x) + [Math]::Abs($ccy - $y) -le $ClusterGap) { $merged = $c; break }
            }
            if ($null -eq $merged) {
                [void]$clusters.Add([pscustomobject]@{ N = 1; SX = [int]$x; SY = [int]$y })
            } else {
                $merged.SX += $x; $merged.SY += $y; $merged.N++
            }
        }
    }
    $out = @()
    foreach ($c in $clusters) {
        if ($c.N -ge 6) {
            # pscustomobject (NOT [ordered]@{}): Sort-Object Y on an OrderedDictionary
            # resolves no property and silently returns scan/creation order, so the
            # "topmost first" contract that callers rely on would be broken.
            $out += [pscustomobject]@{ X = [int]($c.SX / $c.N); Y = [int]($c.SY / $c.N); N = $c.N }
        }
    }
    return @($out | Sort-Object Y)
}

function Dump-Uia {
    param([IntPtr]$Handle, [string]$Name)
    Initialize-Uia
    $root = Get-UiaRootFromHandle -Handle $Handle
    $text = Get-UiaDumpText -Root $root
    Save-Uia -Name $Name -Text $text
    return $text
}

# ---------------- workflow steps ----------------

function Step-Launch {
    param($Cfg, $U)
    $exe = Join-Path $Cfg.releaseDir 'muaman_store.exe'
    if (-not (Test-Path -LiteralPath $exe)) { throw "release exe not found: $exe" }

    # Stale instances of OUR release must not linger.
    Get-Process -Name 'muaman_store' -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            if ($_.Path -eq $exe) {
                Log "killing stale release process $($_.Id)"
                Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            }
        } catch {}
    }
    Start-Sleep -Milliseconds 800

    # Fresh, isolated database under the Release CWD (build output is gitignored;
    # existing user data outside the Release dir is untouched).
    $dbRoot = Join-Path $Cfg.releaseDir '.dart_tool'
    if (Test-Path -LiteralPath $dbRoot) { Remove-Item -LiteralPath $dbRoot -Recurse -Force }
    if (Test-Path -LiteralPath $Cfg.tempDir) { Remove-Item -LiteralPath $Cfg.tempDir -Recurse -Force }
    New-Item -ItemType Directory -Path (Join-Path $Cfg.tempDir 'pdf') -Force | Out-Null

    $launch = Get-LaunchWindow -Exe $exe -WorkDir $Cfg.releaseDir -TimeoutSec 120
    if (-not $launch.windowFound) { throw 'app main window did not appear' }
    $script:AppProc = $launch.proc
    $script:AppHandle = $launch.handle
    Start-Sleep -Milliseconds 2500

    $shot = Join-Path $ShotsDir '04-app-launch.png'
    $cap = Capture-AppWindowPng -Handle $launch.handle -File $shot
    $words = @(Invoke-OcrFile -Path $shot -LanguageTag 'ar-SA' -DpiScale 1.0)
    Save-OcrDump -Name '04-app-launch.txt' -Words $words

    $titleHit = Find-OcrWordByParts -Words $words -Parts @($U.setup.title -split '\s+')
    $ready = $null -ne $titleHit
    return [ordered]@{
        exe = $exe
        processId = $launch.proc.Id
        handle = ('0x{0:X}' -f $launch.handle.ToInt64())
        windowFound = $launch.windowFound
        setupScreenRecognized = $ready
        screenshot = $shot
        captureNote = $cap
    }
}

function Step-SetupOwner {
    param($Cfg, $U)
    $h = $script:AppHandle
    $fieldDefs = [ordered]@{
        name = [ordered]@{ label = [string]$U.setup.fieldName; value = [string]$U.owner.displayName }
        user = [ordered]@{ label = [string]$U.setup.fieldUsername; value = [string]$U.owner.username }
        pass = [ordered]@{ label = [string]$U.setup.fieldPassword; value = [string]$U.owner.password; secret = $true }
        confirm = [ordered]@{ label = [string]$U.setup.fieldConfirmPassword; value = [string]$U.owner.password; secret = $true }
    }
    $methods = Fill-SimpleFields -Handle $h -FieldDefs $fieldDefs -ShotDir $ShotsDir -Tag 'setup'
    $btn = Click-OcrExact -Handle $h -Parts @($U.setup.buttonCreateOwner) -ShotDir $ShotsDir -Tag 'setup-b' -Transient
    if (-not $btn.clicked) { throw 'create-owner button not found via OCR' }

    # Owner creation leads to the login screen.
    $loginReached = $false
    $words = @()
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt 60) {
        $shot = Join-Path $ShotsDir '04b-login.png'
        $null = Capture-AppWindowPng -Handle $h -File $shot
        $words = @(Invoke-OcrFile -Path $shot -LanguageTag 'ar-SA' -DpiScale 1.0)
        $t = Find-OcrWordByParts -Words $words -Parts @($U.login.title -split '\s+')
        $b = Find-OcrWordByParts -Words $words -Parts @($U.login.buttonLogin -split '\s+')
        if ($null -ne $t -and $null -ne $b) { $loginReached = $true; break }
        Start-Sleep -Milliseconds 800
    }
    if (-not $loginReached) { throw 'login screen not reached after owner creation' }
    Save-OcrDump -Name '04b-login.txt' -Words $words
    return [ordered]@{ ownerCreated = $true; loginReached = $loginReached; loginScreenshot = $shot; createButton = $btn; methods = $methods }
}

function Step-LoginOwner {
    param($Cfg, $U)
    $h = $script:AppHandle
    $fieldDefs = [ordered]@{
        user = [ordered]@{ label = [string]$U.login.fieldUsername; value = [string]$U.owner.username }
        pass = [ordered]@{ label = [string]$U.login.fieldPassword; value = [string]$U.owner.password; secret = $true }
    }
    $methods = Fill-SimpleFields -Handle $h -FieldDefs $fieldDefs -ShotDir $ShotsDir -Tag 'login'
    $btn = Click-OcrExact -Handle $h -Parts @($U.login.buttonLogin) -ShotDir $ShotsDir -Tag 'login-b' -Transient
    if (-not $btn.clicked) { throw 'login button not found via OCR' }

    $dashReached = $false
    $words = @()
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt 60) {
        $shot = Join-Path $ShotsDir '05-dashboard.png'
        $null = Capture-AppWindowPng -Handle $h -File $shot
        $words = @(Invoke-OcrFile -Path $shot -LanguageTag 'ar-SA' -DpiScale 1.0)
        $t = Find-OcrWordByParts -Words $words -Parts @($U.dashboard.title -split '\s+')
        $n = Find-OcrWordByParts -Words $words -Parts @($U.dashboard.navSales -split '\s+')
        if ($null -ne $t -or $null -ne $n) { $dashReached = $true; break }
        Start-Sleep -Milliseconds 800
    }
    if (-not $dashReached) { throw 'dashboard not reached after login' }
    Save-OcrDump -Name '05-dashboard.txt' -Words $words
    $uia = Dump-Uia -Handle $h -Name '05-dashboard-uia.txt'
    return [ordered]@{ loginMethods = $methods; loginButton = $btn; dashboardReached = $dashReached; dashboardScreenshot = $shot }
}

function Step-AddProduct {
    param($Cfg, $U)
    $h = $script:AppHandle
    # Navigate to inventory tab (position-based: 2nd tile from the right).
    $navLabels = @($U.dashboard.title, $U.dashboard.navInventory, $U.dashboard.navSales, $U.dashboard.navReturns, $U.dashboard.navExpenses, $U.dashboard.navStocktake)
    $nav = Click-NavTileByRank -Handle $h -Labels $navLabels -Rank 1 -ShotDir $ShotsDir -Tag 'nav-inv'
    if (-not $nav.clicked) { throw 'inventory nav not found' }
    Start-Sleep -Milliseconds 1200
    $fab = Click-OcrSimilar -Handle $h -Parts @($U.inventory.fabAddProduct -split '\s+') -ShotDir $ShotsDir -Tag 'fab-add'
    if (-not $fab.clicked) { throw 'add-product FAB not found' }
    Start-Sleep -Milliseconds 1200

    # Dialog is centered; labels sit at the top of each full-width box.
    $shotDlg = Join-Path $ShotsDir '06b-addproduct-dialog.png'
    $null = Capture-AppWindowPng -Handle $h -File $shotDlg
    $dlgWords = @(Invoke-OcrFile -Path $shotDlg -LanguageTag 'ar-SA' -DpiScale 1.0)
    Save-OcrDump -Name '06b-addproduct-dialog.txt' -Words $dlgWords
    $titleHit = Find-OcrWordByParts -Words $dlgWords -Parts @($U.inventory.dialogTitleAdd -split '\s+')
    if ($null -eq $titleHit) { throw 'add-product dialog not recognized via OCR' }

    $fieldDefs = [ordered]@{
        name = [ordered]@{ label = [string]$U.inventory.fieldName; value = [string]$U.product.name }
        cost = [ordered]@{ label = [string]$U.inventory.fieldCost; value = [string]$U.product.cost }
        qty = [ordered]@{ label = [string]$U.inventory.fieldQty; value = [string]$U.product.qty }
    }
    $methods = Fill-SimpleFields -Handle $h -FieldDefs $fieldDefs -ShotDir $ShotsDir -Tag 'prod' -XMax 950 -CropX0 0.40 -CropY0 0.28 -CropX1 0.62 -CropY1 0.74 -CropScale 3

    # Submit: Enter on the last field (qty) triggers saveProduct().
    [void](Force-ForegroundWindow -Handle $h)
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
    $closed = $false
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt 15) {
        if (Test-OcrDialogClosed -Handle $h -Parts @($U.inventory.dialogTitleAdd -split '\s+') -ShotDir $ShotsDir -Tag 'prod-cls' -X0 0.40 -Y0 0.28 -X1 0.62 -Y1 0.74 -Scale 3) { $closed = $true; break }
        Start-Sleep -Milliseconds 700
    }
    if (-not $closed) {
        # Fallback: click the dialog Add button (dialog region only, so the
        # screen FAB label "إضافة صنف" cannot shadow the dialog button).
        $btn = Click-OcrCropped -Handle $h -Parts @($U.inventory.buttonAdd) -ShotDir $ShotsDir -Tag 'prod-b' -X0 0.40 -Y0 0.28 -X1 0.62 -Y1 0.74 -Scale 3
        if ($btn.clicked) {
            $sw.Restart()
            while ($sw.Elapsed.TotalSeconds -lt 15) {
                if (Test-OcrDialogClosed -Handle $h -Parts @($U.inventory.dialogTitleAdd -split '\s+') -ShotDir $ShotsDir -Tag 'prod-cls2' -X0 0.40 -Y0 0.28 -X1 0.62 -Y1 0.74 -Scale 3) { $closed = $true; break }
                Start-Sleep -Milliseconds 700
            }
        }
    }
    if (-not $closed) { throw 'add-product dialog did not close after submit' }
    Start-Sleep -Milliseconds 1200

    $shotInv = Join-Path $ShotsDir '06-inventory.png'
    $null = Capture-AppWindowPng -Handle $h -File $shotInv
    $invWords = @(Invoke-OcrFile -Path $shotInv -LanguageTag 'ar-SA' -DpiScale 1.0)
    Save-OcrDump -Name '06-inventory.txt' -Words $invWords
    # Scope to the content area (below the app bar) so the owner name word
    # "l17W" in the top bar cannot count as the added product.
    $prodHit = Find-OcrWordByParts -Words @($invWords | Where-Object { $_.Y -ge 130 }) -Parts @('17W')
    return [ordered]@{ dialogRecognized = $true; methods = $methods; dialogClosed = $closed; productVisible = ($null -ne $prodHit); inventoryScreenshot = $shotInv }
}

function Step-CreateSale {
    param($Cfg, $U)
    $h = $script:AppHandle
    $navLabels = @($U.dashboard.title, $U.dashboard.navInventory, $U.dashboard.navSales, $U.dashboard.navReturns, $U.dashboard.navExpenses, $U.dashboard.navStocktake)
    $nav = Click-NavTileByRank -Handle $h -Labels $navLabels -Rank 2 -ShotDir $ShotsDir -Tag 'nav-sales'
    if (-not $nav.clicked) { throw 'sales nav not found' }
    # Verify the Sales screen is actually shown (fuzzy OCR previously clicked the
    # similar المرتجعات label); the app bar title must read المبيعات.
    $salesShown = $false
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt 15) {
        $chk = Join-Path $ShotsDir 'sales-title-chk.png'
        $null = Capture-AppWindowPng -Handle $h -File $chk
        $tw = @(Invoke-OcrFile -Path $chk -LanguageTag 'ar-SA' -DpiScale 1.0)
        $bar = @($tw | Where-Object { $_.Y -ge 40 -and $_.Y -le 110 } | Where-Object { Test-OcrWordExact ([string]$U.dashboard.navSales) $_.Text })
        if ($bar.Count -gt 0) { $salesShown = $true; break }
        Start-Sleep -Milliseconds 600
    }
    if (-not $salesShown) { throw 'sales screen not shown after nav click' }
    Start-Sleep -Milliseconds 500
    # The new-invoice extended FAB sits above the nav bar (bottom edge); OCR it
    # from a cropped+upscaled strip with exact matching. Try bottom-left (RTL
    # endFloat) then bottom-right.
    $fab = $null
    foreach ($region in @(@{ x0 = 0; x1 = 0.4 }, @{ x0 = 0.6; x1 = 1.0 })) {
        $fab = Click-OcrCropped -Handle $h -Parts @($U.sales.fabNewInvoice -split '\s+') -ShotDir $ShotsDir -Tag 'fab-inv' `
            -X0 $region.x0 -Y0 0.72 -X1 $region.x1 -Y1 1.0 -Scale 3 -Exact
        if ($fab.clicked) { break }
    }
    if (-not $fab.clicked) { throw 'new-invoice FAB not found' }
    Start-Sleep -Milliseconds 1500

    # Wait for the product grid (products load async). The newest product is
    # appended at the bottom of the seeded list, so scroll the grid down until
    # the '17W' card is visible.
    $gridReady = $false
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt 45) {
        $chk = Join-Path $ShotsDir 'inv-chk.png'
        $null = Capture-AppWindowPng -Handle $h -File $chk
        $cw = @(Invoke-OcrFile -Path $chk -LanguageTag 'ar-SA' -DpiScale 1.0)
        if ($null -ne (Find-OcrWordByParts -Words $cw -Parts @($U.invoice.labelCart -split '\s+')) -and
            $null -ne (Find-OcrWordByParts -Words $cw -Parts @('17W'))) { $gridReady = $true; break }
        if ($sw.Elapsed.TotalSeconds -gt 5) {
            $rect = Get-WindowRectOut -Handle $h
            [void][M13PWinNative]::SetCursorPos(($rect.Left + 1200), ($rect.Top + 500))
            Start-Sleep -Milliseconds 250
            Send-WheelDown -Notches 10
            Start-Sleep -Milliseconds 600
        }
        Start-Sleep -Milliseconds 700
    }
    if (-not $gridReady) { throw 'invoice screen product grid not ready' }

    # Add the product to the cart: click the product card (topmost 17W word).
    $chk = Join-Path $ShotsDir 'inv-chk2.png'
    $null = Capture-AppWindowPng -Handle $h -File $chk
    $cw = @(Invoke-OcrFile -Path $chk -LanguageTag 'ar-SA' -DpiScale 1.0)
    $pw = @($cw | Where-Object { $_.Text -eq '17W' } | Sort-Object Y)[0]
    if ($null -eq $pw) {
        $pw = @(Find-WordsByParts -Words $cw -Parts @('17W') | Sort-Object Y)[0]
    }
    if ($null -eq $pw) { throw 'product card word not found in grid' }
    $rect = Get-WindowRectOut -Handle $h
    $sx = $rect.Left + [int]($pw.X + $pw.W / 2)
    $sy = $rect.Top + [int]($pw.Y + $pw.H / 2)
    [void](Force-ForegroundWindow -Handle $h)
    Start-Sleep -Milliseconds 350
    [M13PWinNative]::ClickAt($sx, $sy)
    Start-Sleep -Milliseconds 900

    $fieldDefs = [ordered]@{
        price = [ordered]@{ label = [string]$U.invoice.fieldPrice; value = [string]$U.product.price }
        customer = [ordered]@{ label = [string]$U.invoice.fieldCustomer; value = [string]$U.product.customer }
    }
    $methods = [ordered]@{}
    foreach ($key in @($fieldDefs.Keys)) {
        $def = $fieldDefs[$key]
        $m = Fill-FloatingLabelField -Handle $h -Label ([string]$def.label) -Value ([string]$def.value) -ShotDir $ShotsDir -Tag "sale-$key"
        if (-not $m.clicked) { throw "field not filled: $($def.label)" }
        $methods[$key] = $m
    }

    $shot = Join-Path $ShotsDir '07a-invoice-ready.png'
    $null = Capture-AppWindowPng -Handle $h -File $shot
    $words = @(Invoke-OcrFile -Path $shot -LanguageTag 'ar-SA' -DpiScale 1.0)
    Save-OcrDump -Name '07a-invoice-ready.txt' -Words $words
    $totalHit = Find-OcrWordByParts -Words $words -Parts @($U.invoice.labelTotal -split '\s+')
    if ($null -eq $totalHit) { throw 'invoice total label not visible' }

    # Save the invoice; owner can view history so the preview auto-pushes.
    $btn = Click-OcrExact -Handle $h -Parts @($U.invoice.buttonSave) -ShotDir $ShotsDir -Tag 'save-inv'
    if (-not $btn.clicked) { throw 'save-invoice button not found' }

    $previewReached = $false
    $previewShot = Join-Path $ShotsDir '07-invoice-preview.png'
    $previewWords = @()
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt 45) {
        $null = Capture-AppWindowPng -Handle $h -File $previewShot
        $previewWords = @(Invoke-OcrFile -Path $previewShot -LanguageTag 'ar-SA' -DpiScale 1.0)
        $t = Find-OcrWordByParts -Words $previewWords -Parts @($U.preview.title -split '\s+')
        if ($null -ne $t) { $previewReached = $true; break }
        Start-Sleep -Milliseconds 800
    }
    if (-not $previewReached) { throw 'invoice preview did not open after save' }
    Save-OcrDump -Name '07-invoice-preview.txt' -Words $previewWords
    $uia = Dump-Uia -Handle $h -Name '07-invoice-preview-uia.txt'
    $invNoWord = @($previewWords | Where-Object { $_.Text -match '^INV' }) | Select-Object -First 1
    $invNo = if ($invNoWord) { $invNoWord.Text } else { $null }
    return [ordered]@{ methods = $methods; saveButton = $btn; previewReached = $previewReached; previewScreenshot = $previewShot; invoiceNumber = $invNo }
}

function Step-SavePdf {
    param($Cfg, $U)
    $h = $script:AppHandle
    $btn = Click-ExactWithScroll -Handle $h -Parts @($U.preview.buttonSavePdf) -ShotDir $ShotsDir -Tag 'save-pdf'
    if (-not $btn.clicked) { throw 'save-PDF button not found' }

    $dlg = Wait-WindowOfPid -ProcessId $script:AppProc.Id -ClassName '#32770' -TimeoutSec 30
    if ($dlg -eq [IntPtr]::Zero) { throw 'native save dialog did not appear' }
    $dlgFacts = Get-WindowFacts -Handle $dlg
    Start-Sleep -Milliseconds 1200
    $shotDlg = Join-Path $ShotsDir '08-save-dialog.png'
    $cap = Capture-WindowPng -Handle $dlg -File $shotDlg
    if ($cap -ne 'ok') { $cap2 = Capture-DesktopPng -File $shotDlg; $cap = "desktop-fallback $cap2" }
    $dlgWords = @(Invoke-OcrFile -Path $shotDlg -LanguageTag 'en-US' -DpiScale 1.0)
    Save-OcrDump -Name '08-save-dialog.txt' -Words $dlgWords

    # Locate the File-name edit (the bottom-most Edit in the dialog) via UIA.
    $dlgRoot = Get-UiaRootFromHandle -Handle $dlg
    $editEl = $null
    $editRect = $null
    try {
        $condEdit = New-Object System.Windows.Automation.PropertyCondition(
            [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
            [System.Windows.Automation.ControlType]::Edit)
        $editCands = $dlgRoot.FindAll([System.Windows.Automation.TreeScope]::Descendants, $condEdit)
        foreach ($e in $editCands) {
            $r = $e.Current.BoundingRectangle
            if ($r.Width -gt 40 -and $r.Height -gt 15) {
                if ($null -eq $editRect -or $r.Top -gt $editRect.Top) { $editEl = $e; $editRect = $r }
            }
        }
    } catch { $editEl = $null }
    if ($null -eq $editEl) { Log 'save dialog: no edit control found via UIA (will use OCR-anchored file-name entry)' }

    # Navigate the dialog to the target folder first, then set only the file name.
    # The classic dialog rejects full paths (backslashes/colons) typed into the
    # File-name box, so split folder navigation (address bar) from file-name entry.
    $dest = Join-Path $Cfg.tempPdfDir $Cfg.destPdfName
    $name = $Cfg.destPdfName
    $navVia = 'address-bar'
    [void](Force-ForegroundWindow -Handle $dlg)
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait('^l')
    Start-Sleep -Milliseconds 700
    [M13PWinNative]::TypeText($Cfg.tempPdfDir)
    Start-Sleep -Milliseconds 200
    [M13PWinNative]::SendEnter()
    Start-Sleep -Milliseconds 1500

    # Evidence: dialog state after folder navigation.
    $shotNav = Join-Path $ShotsDir '08a-save-dialog-after-nav.png'
    $capNav = Capture-WindowPng -Handle $dlg -File $shotNav
    if ($capNav -ne 'ok') { $capNav = Capture-DesktopPng -File $shotNav }
    $navWords = @(Invoke-OcrFile -Path $shotNav -LanguageTag 'en-US' -DpiScale 1.0)
    Save-OcrDump -Name '08a-save-dialog-after-nav.txt' -Words $navWords

    # Dump the dialog UIA tree for diagnostics.
    $uiaDlg = Dump-Uia -Handle $dlg -Name '08c-save-dialog-uia.txt'

    # OCR-anchored file-name entry. The bottom-most Edit found via UIA can
    # resolve to the Search box (the classic dialog exposes its search field as
    # an Edit too), so locate the File-name row from the OCR 'File name:' label
    # and click/type into that exact cell, verifying the result with OCR.
    $dlgRect = Get-WindowRectOut -Handle $dlg
    $fnLabel = @($navWords | Where-Object { $_.Y -gt 380 -and $_.X -lt 220 -and $_.Text -match '^(?i)file$' } | Sort-Object Y) | Select-Object -First 1
    if ($null -eq $fnLabel) { $fnLabel = @($navWords | Where-Object { $_.Y -gt 380 -and $_.X -lt 220 -and $_.Text -match '^(?i)name' } | Sort-Object Y) | Select-Object -First 1 }
    if ($null -eq $fnLabel) { throw 'file name row not found in save dialog after navigation' }
    $fnRowY = [int]$fnLabel.Y
    $fnValX = @($navWords | Where-Object { [math]::Abs($_.Y - $fnRowY) -lt 10 -and $_.X -gt 140 } | Sort-Object X | Select-Object -First 1)
    $fnCx = if ($fnValX) { [int]$fnValX.X + 250 } else { [int]$fnLabel.X + 200 }
    $fnCy = $fnRowY + 7

    $setVia = 'click-type'
    $nameOk = $false
    for ($try = 1; $try -le 3; $try++) {
        [void](Force-ForegroundWindow -Handle $dlg)
        Start-Sleep -Milliseconds 300
        [M13PWinNative]::ClickAt($dlgRect.Left + $fnCx, $dlgRect.Top + $fnCy)
        Start-Sleep -Milliseconds 400
        # The File-name control is a Pane (not an UIA Edit), so Ctrl+A does not
        # select its text; clear deterministically with END + repeated Backspace.
        [System.Windows.Forms.SendKeys]::SendWait('{END}')
        Start-Sleep -Milliseconds 100
        [System.Windows.Forms.SendKeys]::SendWait('{BS 60}')
        Start-Sleep -Milliseconds 300
        [M13PWinNative]::TypeText($name)
        Start-Sleep -Milliseconds 400
        $shotSet = Join-Path $ShotsDir '08b-save-dialog-name-set.png'
        $capSet = Capture-WindowPng -Handle $dlg -File $shotSet
        if ($capSet -ne 'ok') { $capSet = Capture-DesktopPng -File $shotSet }
        $setWords = @(Invoke-OcrFile -Path $shotSet -LanguageTag 'en-US' -DpiScale 1.0)
        Save-OcrDump -Name '08b-save-dialog-name-set.txt' -Words $setWords
        $nameOk = @($setWords | Where-Object { [math]::Abs($_.Y - $fnRowY) -lt 12 -and $_.Text -match '(?i)invoice.{0,2}17w' -and $_.Text -notmatch '(?i)muaman-17w' })
        if ($nameOk) { break }
    }
    if (-not $nameOk) { throw 'file name field did not accept the file name (OCR verification failed after 3 attempts)' }

    # Trigger Save via the Save button. UIA tree may take a moment to build, so
    # retry; then fall back to the OCR 'Save' word position, then Enter.
    $saveVia = $null
    $saveEl = $null
    $swBtn = [System.Diagnostics.Stopwatch]::StartNew()
    while ($swBtn.Elapsed.TotalSeconds -lt 10 -and $null -eq $saveEl) {
        try {
            $condBtn = New-Object System.Windows.Automation.PropertyCondition(
                [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
                [System.Windows.Automation.ControlType]::Button)
            $btnCands = $dlgRoot.FindAll([System.Windows.Automation.TreeScope]::Descendants, $condBtn)
            foreach ($b in $btnCands) {
                $n = [string]$b.Current.Name
                if ($n -and $n.IndexOf('save', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -and
                    $n.IndexOf('type', [System.StringComparison]::OrdinalIgnoreCase) -lt 0) { $saveEl = $b; break }
            }
        } catch { $saveEl = $null }
        if ($null -eq $saveEl) { Start-Sleep -Milliseconds 600 }
    }
    if ($null -ne $saveEl) {
        try { Invoke-UiaElement -Element $saveEl; $saveVia = 'uia-invoke' }
        catch {
            $r = $saveEl.Current.BoundingRectangle
            [void](Force-ForegroundWindow -Handle $dlg)
            Start-Sleep -Milliseconds 300
            [M13PWinNative]::ClickAt([int]($r.X + $r.Width / 2), [int]($r.Y + $r.Height / 2))
            $saveVia = 'uia-rect'
        }
    } else {
        $dlgRect = Get-WindowRectOut -Handle $dlg
        $saveWord = @($dlgWords | Where-Object { $_.Text -match '(?i)^save$' } | Sort-Object Y) | Select-Object -Last 1
        if ($null -ne $saveWord) {
            $sx = $dlgRect.Left + [int]($saveWord.X + $saveWord.W / 2)
            $sy = $dlgRect.Top + [int]($saveWord.Y + $saveWord.H / 2)
            [void](Force-ForegroundWindow -Handle $dlg)
            Start-Sleep -Milliseconds 300
            [M13PWinNative]::ClickAt($sx, $sy)
            $saveVia = 'ocr-rect'
        } else {
            [void](Force-ForegroundWindow -Handle $dlg)
            Start-Sleep -Milliseconds 300
            [M13PWinNative]::SendEnter()
            $saveVia = 'enter'
        }
    }
    if ($null -eq $saveVia) { throw 'save button not found in save dialog' }

    $closed = Wait-NoWindowOfPid -ProcessId $script:AppProc.Id -ClassName '#32770' -TimeoutSec 30
    $saved = $false
    $sha = $null
    $size = 0
    $header = ''
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt 20) {
        if (Test-Path -LiteralPath $dest) {
            $saved = $true
            $size = (Get-Item -LiteralPath $dest).Length
            $bytes = [System.IO.File]::ReadAllBytes($dest)
            if ($bytes.Length -gt 5) {
                $header = [System.Text.Encoding]::ASCII.GetString($bytes[0..4])
            }
            $sha = (Get-FileSha256 -Path $dest -Retries 0)
            break
        }
        Start-Sleep -Milliseconds 400
    }
    if (-not $saved) {
        # Evidence: capture the dialog state after the save attempt.
        $shotPost = Join-Path $ShotsDir '08b-save-dialog-post.png'
        $capPost = Capture-WindowPng -Handle $dlg -File $shotPost
        if ($capPost -ne 'ok') { $capPost = Capture-DesktopPng -File $shotPost }
        $postWords = @(Invoke-OcrFile -Path $shotPost -LanguageTag 'en-US' -DpiScale 1.0)
        Save-OcrDump -Name '08b-save-dialog-post.txt' -Words $postWords
        throw "PDF not written after save dialog (dialog did not close or path rejected; nav=$navVia set=$setVia save=$saveVia)"
    }
    if ($saved) {
        Copy-Item -LiteralPath $dest -Destination (Join-Path $PdfDir $Cfg.destPdfName) -Force
    }
    return [ordered]@{
        button = $btn
        dialogAppeared = ($dlg -ne [IntPtr]::Zero)
        dialogTitle = $dlgFacts.title
        dialogClass = $dlgFacts.className
        dialogScreenshot = $shotDlg
        editRect = $editRect
        navVia = $navVia
        setVia = $setVia
        saveVia = $saveVia
        dialogClosed = $closed
        saved = $saved
        destination = $dest
        sizeBytes = $size
        pdfHeader = $header
        sha256 = $sha
    }
}

function Step-OpenPdf {
    param($Cfg, $U)
    $h = $script:AppHandle
    # The preview shows two PDF-labelled buttons (فتح PDF open, حفظ PDF save) at
    # the same Y; Click-OcrExact's bottom-most rule can pick the save button and
    # reopen the save dialog. Target the open button = the leftmost PDF word in
    # the bottom action band.
    $rect = Get-WindowRectOut -Handle $h
    $btn = [ordered]@{ clicked = $false }
    $png = Join-Path $ShotsDir 'open-pdf-ex-t1.png'
    $null = Capture-AppWindowPng -Handle $h -File $png
    $words = @(Invoke-OcrFile -Path $png -LanguageTag 'ar-SA' -DpiScale 1.0)
    $pdfWords = @($words | Where-Object { $_.Y -gt [int]($rect.Height * 0.78) -and $_.Text -match '(?i)^pdf$' })
    if ($pdfWords.Count -gt 0) {
        $open = @($pdfWords | Sort-Object X)[0]
        $btn = [ordered]@{
            clicked = $true; try = 1
            screenX = $rect.Left + [int]($open.X + $open.W / 2)
            screenY = $rect.Top + [int]($open.Y + $open.H / 2)
            word = $open.Text
        }
        [void](Force-ForegroundWindow -Handle $h)
        Start-Sleep -Milliseconds 350
        [M13PWinNative]::ClickAt($btn.screenX, $btn.screenY)
        Start-Sleep -Milliseconds 700
    }
    if (-not $btn.clicked) { throw 'open-PDF button not found' }

    # The plugin writes %TEMP%\invoice_INV-*.pdf then ShellExecuteEx "open".
    $tempPdf = $null
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt 20) {
        $cand = @(Get-ChildItem -LiteralPath $env:TEMP -Filter 'invoice_INV-*.pdf' -ErrorAction SilentlyContinue)
        if ($cand.Count -gt 0) { $tempPdf = $cand | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1; break }
        Start-Sleep -Milliseconds 400
    }
    if ($null -eq $tempPdf) { throw 'temporary invoice PDF not written to %TEMP%' }

    # Default PDF viewer is Chrome (ChromePDF). Find the Chrome window whose
    # title carries the pdf file name.
    $chromeHwnd = [IntPtr]::Zero
    $chromeTitle = $null
    $sw.Restart()
    while ($sw.Elapsed.TotalSeconds -lt 30) {
        foreach ($p in @(Get-Process -Name 'chrome' -ErrorAction SilentlyContinue)) {
            try {
                $t = $p.MainWindowTitle
                if ($t -and $t.IndexOf($tempPdf.Name, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    $chromeHwnd = $p.MainWindowHandle
                    $chromeTitle = $t
                    break
                }
            } catch {}
        }
        if ($chromeHwnd -ne [IntPtr]::Zero) { break }
        Start-Sleep -Milliseconds 600
    }
    $shotViewer = Join-Path $ShotsDir '09-pdf-open.png'
    $viewerCapture = $null
    if ($chromeHwnd -ne [IntPtr]::Zero) {
        $viewerCapture = Capture-WindowPng -Handle $chromeHwnd -File $shotViewer
        if ($viewerCapture -ne 'ok') { $viewerCapture = Capture-DesktopPng -File $shotViewer }
    } else {
        $viewerCapture = Capture-DesktopPng -File $shotViewer
    }
    Copy-Item -LiteralPath $tempPdf.FullName -Destination (Join-Path $PdfDir 'open-copy.pdf') -Force
    $openSha = Get-FileSha256 -Path $tempPdf.FullName -Retries 0

    # Close our Chrome tab (Ctrl+W) if we identified the PDF-tab window.
    $tabClosed = $false
    if ($chromeHwnd -ne [IntPtr]::Zero) {
        [void](Force-ForegroundWindow -Handle $chromeHwnd)
        Start-Sleep -Milliseconds 500
        [System.Windows.Forms.SendKeys]::SendWait('^w')
        Start-Sleep -Milliseconds 1200
        $tabClosed = $true
    }
    return [ordered]@{
        button = $btn
        tempPdf = $tempPdf.FullName
        tempSizeBytes = $tempPdf.Length
        tempSha256 = $openSha
        defaultViewerChrome = ($chromeHwnd -ne [IntPtr]::Zero)
        chromeTitle = $chromeTitle
        viewerScreenshot = $shotViewer
        viewerCaptureNote = $viewerCapture
        tabClosed = $tabClosed
    }
}

function Step-PrintDialog {
    param($Cfg, $U)
    $h = $script:AppHandle
    $btn = Click-ExactWithScroll -Handle $h -Parts @($U.preview.buttonPrint) -ShotDir $ShotsDir -Tag 'print'
    if (-not $btn.clicked) { throw 'print button not found' }

    $dlg = Wait-WindowOfPid -ProcessId $script:AppProc.Id -ClassName '#32770' -TimeoutSec 30
    if ($dlg -eq [IntPtr]::Zero) { throw 'native print dialog did not appear' }
    $dlgFacts = Get-WindowFacts -Handle $dlg
    $shotDlg = Join-Path $ShotsDir '10-print-dialog.png'
    $cap = Capture-WindowPng -Handle $dlg -File $shotDlg
    if ($cap -ne 'ok') { $cap = Capture-DesktopPng -File $shotDlg }
    $dlgWords = @(Invoke-OcrFile -Path $shotDlg -LanguageTag 'en-US' -DpiScale 1.0)
    Save-OcrDump -Name '10-print-dialog.txt' -Words $dlgWords

    # Cancel: Escape (IDCANCEL) on the dialog.
    [void](Force-ForegroundWindow -Handle $dlg)
    Start-Sleep -Milliseconds 400
    [System.Windows.Forms.SendKeys]::SendWait('{ESC}')
    $closed = Wait-NoWindowOfPid -ProcessId $script:AppProc.Id -ClassName '#32770' -TimeoutSec 30

    # The app must be back on the preview, alive and responsive.
    Start-Sleep -Milliseconds 1200
    $shotBack = Join-Path $ShotsDir '11-print-cancel.png'
    $null = Capture-AppWindowPng -Handle $h -File $shotBack
    $words = @(Invoke-OcrFile -Path $shotBack -LanguageTag 'ar-SA' -DpiScale 1.0)
    Save-OcrDump -Name '11-print-cancel.txt' -Words $words
    $previewStill = $null -ne (Find-OcrWordByParts -Words $words -Parts @($U.preview.title -split '\s+'))
    return [ordered]@{
        button = $btn
        dialogAppeared = ($dlg -ne [IntPtr]::Zero)
        dialogTitle = $dlgFacts.title
        dialogClass = $dlgFacts.className
        dialogScreenshot = $shotDlg
        canceled = $closed
        appBackOnPreview = $previewStill
        postCancelScreenshot = $shotBack
    }
}

function Step-SalesHistory {
    param($Cfg, $U)
    $h = $script:AppHandle
    # Back from preview -> invoice screen -> back -> sales screen.
    [void](Click-Back -Handle $h)
    Start-Sleep -Milliseconds 900
    [void](Click-Back -Handle $h)

    $historyReached = $false
    $words = @()
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt 30) {
        $shot = Join-Path $ShotsDir '12-sales-history.png'
        $null = Capture-AppWindowPng -Handle $h -File $shot
        $words = @(Invoke-OcrFile -Path $shot -LanguageTag 'ar-SA' -DpiScale 1.0)
        $c = Find-OcrWordByParts -Words $words -Parts @($U.sales.labelCount -split '\s+')
        if ($null -ne $c) { $historyReached = $true; break }
        Start-Sleep -Milliseconds 700
    }
    if (-not $historyReached) { throw 'sales history screen not reached' }
    Save-OcrDump -Name '12-sales-history.txt' -Words $words
    $saleCard = $null -ne (Find-OcrWordByParts -Words $words -Parts @('17W'))
    $uia = Dump-Uia -Handle $h -Name '12-sales-history-uia.txt'

    # Open the invoice from the sale card receipt icon. The receipt icon
    # (Icons.receipt_long in Color(0xFF0D47A1)) is invisible to UIA (the Flutter
    # tree exposes only FLUTTERVIEW) and to OCR (icon only), so locate it by
    # colour and click the topmost match (the S05 sale). The sales cards are
    # full-width; in RTL the ListTile trailing column (green total + receipt +
    # delete icons) sits at the far LEFT edge (x~50-115, ~0.03-0.08 of width),
    # NOT on the right where the card title/avatar text lives. The S05 sale is
    # the only card with invoiceId set, so only its receipt icon renders (the
    # other cards' invoiceId is NULL and shows no receipt icon). The FAB
    # (0D47A1, bottom-left, y~678-750) forms another cluster and sorts after the
    # receipt icon (Y~303 < Y~694), so the topmost match is the receipt icon.
    $click = [ordered]@{ via = 'color-scan'; name = [string]$U.sales.tooltipReceipt; found = $false }
    $receiptPreview = $false
    $previewShot = $null
    if ($saleCard) {
        $shotList = Join-Path $ShotsDir '12-sales-list.png'
        $null = Capture-AppWindowPng -Handle $h -File $shotList
        $iconCenters = @(Find-ColorIconCenters -PngPath $shotList -Hex '0D47A1' -X0 0.0 -Y0 0.30 -X1 0.12 -Y1 0.96)
        if ($iconCenters.Count -gt 0) {
            $ic = $iconCenters[0]
            $rect = Get-WindowRectOut -Handle $h
            $sx = $rect.Left + [int]$ic.X
            $sy = $rect.Top + [int]$ic.Y
            $click.found = $true
            $click.screenX = $sx
            $click.screenY = $sy
            $click.iconCenter = $ic
            $click.iconClusterCount = $iconCenters.Count
            $null = Log "receipt icon color-scan clusters=$($iconCenters.Count) top=(X=$($ic.X) Y=$($ic.Y) N=$($ic.N))"
            [void](Force-ForegroundWindow -Handle $h)
            Start-Sleep -Milliseconds 350
            [M13PWinNative]::ClickAt($sx, $sy)
            Start-Sleep -Milliseconds 900
            $sw.Restart()
            while ($sw.Elapsed.TotalSeconds -lt 20) {
                $previewShot = Join-Path $ShotsDir '12b-receipt-preview.png'
                $null = Capture-AppWindowPng -Handle $h -File $previewShot
                $pw = @(Invoke-OcrFile -Path $previewShot -LanguageTag 'ar-SA' -DpiScale 1.0)
                if (Test-OcrPreviewOpen -Words $pw -TitleParts @($U.preview.title -split '\s+') -PrintWord $U.preview.buttonPrint) { $receiptPreview = $true; break }
                Start-Sleep -Milliseconds 700
            }
            if ($receiptPreview) { [void](Click-Back -Handle $h) }
            else { throw 'receipt preview did not open after clicking the receipt icon' }
        }
    }
    return [ordered]@{
        historyReached = $historyReached
        saleCardVisible = $saleCard
        saleCardProductProbe = '17W'
        receiptClick = $click
        receiptPreviewOpened = $receiptPreview
        receiptPreviewScreenshot = $previewShot
        salesScreenshot = $shot
    }
}

function Step-AddCashierUser {
    param($Cfg, $U)
    $h = $script:AppHandle
    # The users AppBar icon (Icons.people, tooltip only) is invisible to UIA/OCR,
    # so click it by position and verify the user-management screen (new-user FAB).
    # If the users icon cannot be hit, fall back to the settings entry tile.
    $click = Click-AppBarIcon -Handle $h -Target 'users' -ShotDir $ShotsDir -Tag 'users-nav' -VerifyParts @($U.users.fabNewUser -split '\s+')
    if (-not $click.clicked) {
        $click = Click-AppBarIcon -Handle $h -Target 'settings' -ShotDir $ShotsDir -Tag 'settings-nav' -VerifyParts @([string]$U.dashboard.settings) -VerifyTopBandStripAl
        if (-not $click.clicked) { throw 'user-management navigation failed (users/settings AppBar icon)' }
        $tile = Click-OcrSimilar -Handle $h -Parts @($U.dashboard.userManagement -split '\s+') -ShotDir $ShotsDir -Tag 'um-tile'
        if (-not $tile.clicked) { throw 'user-management entry not found on settings screen' }
        Start-Sleep -Milliseconds 1200
    }

    $fab = Click-OcrSimilar -Handle $h -Parts @($U.users.fabNewUser -split '\s+') -ShotDir $ShotsDir -Tag 'fab-user'
    if (-not $fab.clicked) { throw 'new-user FAB not found' }
    Start-Sleep -Milliseconds 1200

    $fieldDefs = [ordered]@{
        name = [ordered]@{ label = [string]$U.users.fieldName; value = [string]$U.cashier.displayName }
        user = [ordered]@{ label = [string]$U.users.fieldUsername; value = [string]$U.cashier.username }
        pass = [ordered]@{ label = [string]$U.users.fieldPassword; value = [string]$U.cashier.password; secret = $true }
        confirm = [ordered]@{ label = [string]$U.users.fieldConfirm; value = [string]$U.cashier.password; secret = $true }
    }
    $methods = Fill-SimpleFields -Handle $h -FieldDefs $fieldDefs -ShotDir $ShotsDir -Tag 'newuser'

    # Role dropdown: click the field value 'موظف' to open the menu (the field
    # label 'الدور' fuzzy-matches other rows and has missed before), then click
    # the sales-only menu row 'مبيعات', which only exists while the menu is open.
    $role = Click-OcrSimilar -Handle $h -Parts @([string]$U.users.itemEmployee) -ShotDir $ShotsDir -Tag 'role-open' -Transient
    if (-not $role.clicked) { throw 'role dropdown not opened' }
    Start-Sleep -Milliseconds 900
    $salesOnlyWord = [string]($U.users.itemSalesOnly -split '\s+')[1]
    $item = Click-OcrSimilar -Handle $h -Parts @($salesOnlyWord) -ShotDir $ShotsDir -Tag 'role-item' -Transient
    if (-not $item.clicked) { throw 'sales-only role item not found' }
    Start-Sleep -Milliseconds 800

    # Submit with the create button. The dropdown field holds focus after the
    # selection, so Enter would reopen the menu; the button click is the reliable
    # path. The bottom-most 'إنشاء' is the button (the dialog title word sits
    # above it), so MaxYFrac must stay at 1.0 - 0.8*height excludes the button
    # at y~694 and has silently nulled the click before.
    $closed = $false
    for ($attempt = 1; $attempt -le 3 -and -not $closed; $attempt++) {
        $btn = Click-OcrExact -Handle $h -Parts @($U.users.buttonCreate) -ShotDir $ShotsDir -Tag "create-user-$attempt" -Transient
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        while ($sw.Elapsed.TotalSeconds -lt 12 -and -not $closed) {
            $chk = Join-Path $ShotsDir "user-chk-$attempt.png"
            $null = Capture-AppWindowPng -Handle $h -File $chk
            $cw = @(Invoke-OcrFile -Path $chk -LanguageTag 'ar-SA' -DpiScale 1.0)
            if (-not (Test-OcrDialogTitleOpen -Words $cw -TitleParts @($U.users.dialogTitle -split '\s+'))) { $closed = $true; break }
            Start-Sleep -Milliseconds 700
        }
    }
    if (-not $closed) { throw 'create-user dialog did not close' }
    Start-Sleep -Milliseconds 1000

    $shotUsers = Join-Path $ShotsDir '13-users.png'
    $null = Capture-AppWindowPng -Handle $h -File $shotUsers
    $words = @(Invoke-OcrFile -Path $shotUsers -LanguageTag 'ar-SA' -DpiScale 1.0)
    Save-OcrDump -Name '13-users.txt' -Words $words
    $cashierWord = [string]([string]$U.cashier.displayName -split '\s+' | Select-Object -First 1)
    $cashierVisible = $null -ne (Find-OcrWordByParts -Words $words -Parts @($cashierWord))

    [void](Click-Back -Handle $h)
    return [ordered]@{ navClick = $click; methods = $methods; roleClick = $role; roleItem = $item; dialogClosed = $closed; cashierVisible = $cashierVisible; usersScreenshot = $shotUsers }
}

function Step-LoginCashierDenied {
    param($Cfg, $U)
    $h = $script:AppHandle
    # The logout AppBar icon (Icons.logout, tooltip only) is invisible to UIA/OCR
    # (the Flutter tree exposes only FLUTTERVIEW), so click it by position and
    # verify the login screen appeared.
    $click = Click-AppBarIcon -Handle $h -Target 'logout' -ShotDir $ShotsDir -Tag 'logout-owner' -VerifyParts @($U.login.buttonLogin -split '\s+')
    if (-not $click.clicked) { throw 'logout icon not found (OCR position scan)' }

    # Login screen appears.
    $loginReached = $false
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt 30) {
        $chk = Join-Path $ShotsDir 'lo-chk.png'
        $null = Capture-AppWindowPng -Handle $h -File $chk
        $cw = @(Invoke-OcrFile -Path $chk -LanguageTag 'ar-SA' -DpiScale 1.0)
        if ($null -ne (Find-OcrWordByParts -Words $cw -Parts @($U.login.buttonLogin -split '\s+'))) { $loginReached = $true; break }
        Start-Sleep -Milliseconds 700
    }
    if (-not $loginReached) { throw 'login screen not reached after logout' }

    $fieldDefs = [ordered]@{
        user = [ordered]@{ label = [string]$U.login.fieldUsername; value = [string]$U.cashier.username }
        pass = [ordered]@{ label = [string]$U.login.fieldPassword; value = [string]$U.cashier.password; secret = $true }
    }
    $methods = Fill-SimpleFields -Handle $h -FieldDefs $fieldDefs -ShotDir $ShotsDir -Tag 'cashier-login'
    $btn = Click-OcrExact -Handle $h -Parts @($U.login.buttonLogin) -ShotDir $ShotsDir -Tag 'cashier-login-b' -Transient
    if (-not $btn.clicked) { throw 'login button not found for cashier' }

    # SalesOnlyShell: sales screen without history.
    $deniedReached = $false
    $words = @()
    $sw.Restart()
    while ($sw.Elapsed.TotalSeconds -lt 45) {
        $shot = Join-Path $ShotsDir '14-salesonly.png'
        $null = Capture-AppWindowPng -Handle $h -File $shot
        $words = @(Invoke-OcrFile -Path $shot -LanguageTag 'ar-SA' -DpiScale 1.0)
        $d = Find-OcrWordByParts -Words $words -Parts @($U.sales.historyDenied -split '\s+')
        if ($null -ne $d) { $deniedReached = $true; break }
        Start-Sleep -Milliseconds 800
    }
    if (-not $deniedReached) { throw 'sales-only denied screen not reached' }
    Save-OcrDump -Name '14-salesonly.txt' -Words $words
    $uia = Dump-Uia -Handle $h -Name '14-salesonly-uia.txt'

    # No history content must leak: no count line, no product probe, no receipt.
    # Match only the first word of the count label ('عدد'); the fuzzy matcher
    # would otherwise match 'العمليات' against the screen title 'المبيعات'. The
    # product probe is restricted to the content region (below the appbar) since
    # '17W' appears in the cashier display name 'كاشير 17W' shown in the appbar.
    $countWord = @(Expand-OcrParts -Parts @([string]$U.sales.labelCount))[0]
    $leakCount = $null -ne (Find-OcrWordByParts -Words $words -Parts @($countWord))
    $leakProduct = $null -ne (Find-OcrWordByParts -Words @($words | Where-Object { $_.Y -ge 130 }) -Parts @('17W'))
    $uiaDump = Get-Content -LiteralPath (Join-Path $UiaDir '14-salesonly-uia.txt') -Raw
    $leakReceiptUia = $uiaDump.IndexOf([string]$U.sales.tooltipReceipt, [System.StringComparison]::OrdinalIgnoreCase) -ge 0

    # Sales-only user can still open the create-sale entry.
    $createEntry = $null -ne (Find-OcrWordByParts -Words $words -Parts @($U.sales.createSale -split '\s+'))

    return [ordered]@{
        logoutClick = $click
        loginMethods = $methods
        loginButton = $btn
        salesOnlyReached = $deniedReached
        historyDeniedMessageVisible = $deniedReached
        leakCountLine = $leakCount
        leakProductName = $leakProduct
        leakReceiptUia = $leakReceiptUia
        createSaleEntryVisible = $createEntry
        salesOnlyScreenshot = $shot
    }
}

function Step-LogoutAndClose {
    param($Cfg, $U)
    $h = $script:AppHandle
    # Same position-based logout as S11 (the SalesOnlyShell AppBar is [name][logout]).
    $click = Click-AppBarIcon -Handle $h -Target 'logout' -ShotDir $ShotsDir -Tag 'logout-cashier' -VerifyParts @($U.login.buttonLogin -split '\s+')
    $loginBack = $false
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt 30) {
        $shot = Join-Path $ShotsDir '15-login-final.png'
        $null = Capture-AppWindowPng -Handle $h -File $shot
        $cw = @(Invoke-OcrFile -Path $shot -LanguageTag 'ar-SA' -DpiScale 1.0)
        if ($null -ne (Find-OcrWordByParts -Words $cw -Parts @($U.login.buttonLogin -split '\s+'))) { $loginBack = $true; break }
        Start-Sleep -Milliseconds 700
    }
    if ($loginBack) { Save-OcrDump -Name '15-login-final.txt' -Words $cw }

    $close = Close-WindowGracefully -Handle $h -Process $script:AppProc -TimeoutSec 30
    Start-Sleep -Milliseconds 800
    $exited = $false
    try { $script:AppProc.Refresh(); $exited = $script:AppProc.HasExited } catch { $exited = $true }
    return [ordered]@{ logoutClick = $click; loginScreenBack = $loginBack; loginScreenshot = $shot; close = $close; exited = $exited }
}

function Step-FinalEvidence {
    param($Cfg, $U)
    $dbFile = Join-Path $Cfg.releaseDir '.dart_tool\sqflite_common_ffi\databases\muaman_store.db'
    $shots = @(Get-ChildItem -LiteralPath $ShotsDir -Filter '*.png' | Select-Object -ExpandProperty Name)
    $files = @(Get-ChildItem -LiteralPath $PdfDir -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
    return [ordered]@{
        runId = $Cfg.runId
        releaseDir = $Cfg.releaseDir
        dbFile = $dbFile
        dbExists = (Test-Path -LiteralPath $dbFile)
        dbSizeBytes = if (Test-Path -LiteralPath $dbFile) { (Get-Item -LiteralPath $dbFile).Length } else { 0 }
        evidenceScreenshots = $shots
        evidencePdfFiles = $files
        screenshotCount = $shots.Count
    }
}

# Probe mode: reproduce the create-user dialog role dropdown interaction and dump
# the OCR state after each action (open menu -> click sales-only item -> ENTER ->
# click create), to diagnose why the menu may not close on item selection.
function Step-ProbeRole {
    param($Cfg, $U)
    $h = $script:AppHandle
    Start-Sleep -Milliseconds 1200

    $nav = Click-AppBarIcon -Handle $h -Target 'users' -ShotDir $ShotsDir -Tag 'probe-role-users' -VerifyParts @($U.users.fabNewUser -split '\s+')
    Log "PROBE-ROLE users-nav clicked=$($nav.clicked) reason=$($(if ($nav.PSObject.Properties.Name -contains 'reason') { $nav.reason } else { 'n/a' }))"
    if (-not $nav.clicked) { throw 'users nav failed in probe' }

    $fab = Click-OcrSimilar -Handle $h -Parts @($U.users.fabNewUser -split '\s+') -ShotDir $ShotsDir -Tag 'probe-role-fab'
    if (-not $fab.clicked) { throw 'new-user FAB not found in probe' }
    Start-Sleep -Milliseconds 1200

    $fieldDefs = [ordered]@{
        name = [ordered]@{ label = [string]$U.users.fieldName; value = [string]$U.cashier.displayName }
        user = [ordered]@{ label = [string]$U.users.fieldUsername; value = [string]$U.cashier.username }
        pass = [ordered]@{ label = [string]$U.users.fieldPassword; value = [string]$U.cashier.password; secret = $true }
        confirm = [ordered]@{ label = [string]$U.users.fieldConfirm; value = [string]$U.cashier.password; secret = $true }
    }
    $methods = Fill-SimpleFields -Handle $h -FieldDefs $fieldDefs -ShotDir $ShotsDir -Tag 'probe-role-fill'

    $salesOnlyItem = [string]$U.users.itemSalesOnly
    $salesWord = [string]($salesOnlyItem -split '\s+')[1]

    $roleOpen = Click-OcrSimilar -Handle $h -Parts @([string]$U.users.itemEmployee) -ShotDir $ShotsDir -Tag 'probe-role-open' -Transient
    Start-Sleep -Milliseconds 900
    $openPng = Join-Path $ShotsDir 'probe-role-open.png'
    $null = Capture-AppWindowPng -Handle $h -File $openPng
    $openWords = @(Invoke-OcrFile -Path $openPng -LanguageTag 'ar-SA' -DpiScale 1.0)
    Save-OcrDump -Name 'probe-role-open.txt' -Words $openWords

    $item = Click-OcrSimilar -Handle $h -Parts @($salesWord) -ShotDir $ShotsDir -Tag 'probe-role-item' -Transient
    Start-Sleep -Milliseconds 900
    $afterItemPng = Join-Path $ShotsDir 'probe-role-after-item.png'
    $null = Capture-AppWindowPng -Handle $h -File $afterItemPng
    $afterItemWords = @(Invoke-OcrFile -Path $afterItemPng -LanguageTag 'ar-SA' -DpiScale 1.0)
    Save-OcrDump -Name 'probe-role-after-item.txt' -Words $afterItemWords

    # The menu is open when the top menu row 'مالك' appears in its own band
    # (y~430-530). The closed field never shows it, and the AppBar owner-name
    # band (y~145) is excluded. The field value 'موظف مبيعات فقط' (y~539) must
    # not be mistaken for an open menu.
    $ownerWord = [string]($U.owner.displayName -split '\s+')[0]
    $menuOpenAfterItem = (@($afterItemWords | Where-Object { $_.Y -ge 430 -and $_.Y -lt 530 -and (Test-OcrWordSimilar $ownerWord $_.Text) }).Count -gt 0)

    $btn = Click-OcrExact -Handle $h -Parts @($U.users.buttonCreate) -ShotDir $ShotsDir -Tag 'probe-role-create' -Transient
    $closed = $false
    $cw = @()
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt 15) {
        $chk = Join-Path $ShotsDir 'probe-role-after-create.png'
        $null = Capture-AppWindowPng -Handle $h -File $chk
        $cw = @(Invoke-OcrFile -Path $chk -LanguageTag 'ar-SA' -DpiScale 1.0)
        if (-not (Test-OcrDialogTitleOpen -Words $cw -TitleParts @($U.users.dialogTitle -split '\s+'))) { $closed = $true; break }
        Start-Sleep -Milliseconds 700
    }
    Save-OcrDump -Name 'probe-role-after-create.txt' -Words $cw

    $cashierWord = [string]([string]$U.cashier.displayName -split '\s+' | Select-Object -First 1)
    $cashierVisible = $null -ne (Find-OcrWordByParts -Words $cw -Parts @($cashierWord))
    Log "PROBE-ROLE roleOpen=$($roleOpen.clicked) item=$($item.clicked) word=$($item.word) screen=($($item.screenX),$($item.screenY)) menuOpenAfterItem=$menuOpenAfterItem createClicked=$($btn.clicked) dialogClosed=$closed cashierVisible=$cashierVisible"
    Save-Json -Name 'probe-role.json' -Object @{ nav = $nav; fab = $fab; methods = $methods; roleOpen = $roleOpen; item = $item; createClick = $btn; menuOpenAfterItem = $menuOpenAfterItem; dialogClosed = $closed; cashierVisible = $cashierVisible }
    return [ordered]@{ nav = $nav; item = $item; menuOpenAfterItem = $menuOpenAfterItem; dialogClosed = $closed; cashierVisible = $cashierVisible }
}

# Probe mode: after login, click a grid of X positions along the bottom nav
# bar and record the resulting app-bar title, to map image X -> selected index.
function Step-ProbeNavMap {
    param($Cfg, $U)
    $h = $script:AppHandle
    Start-Sleep -Milliseconds 1500
    $rect = Get-WindowRectOut -Handle $h
    Log "PROBE nav map rect=left:$($rect.Left) top:$($rect.Top) w:$($rect.Width) h:$($rect.Height)"

    $probeRows = @()
    $titleParts = @([string]$U.dashboard.title, [string]$U.dashboard.navInventory, [string]$U.dashboard.navSales,
        [string]$U.dashboard.navReturns, [string]$U.dashboard.navExpenses, [string]$U.dashboard.navStocktake)
    $probeX = @(125, 375, 625, 875, 1125, 1375, 850, 900, 950, 1000)
    foreach ($px in $probeX) {
        $sx = $rect.Left + $px
        $sy = $rect.Top + 820
        Log "PROBE click imgX=$px screen=($sx,$sy)"
        [void](Force-ForegroundWindow -Handle $h)
        Start-Sleep -Milliseconds 300
        [M13PWinNative]::ClickAt($sx, $sy)
        Start-Sleep -Milliseconds 1000
        $png = Join-Path $ShotsDir "probe-nav-x$px.png"
        $null = Capture-AppWindowPng -Handle $h -File $png
        $crop = Join-Path $ShotsDir "probe-nav-x$px-title.png"
        $dim = ConvertTo-CroppedPng -Source $png -Dest $crop -X0 0.35 -Y0 0.04 -X1 0.68 -Y1 0.14 -Scale 3
        $tw = @(Invoke-OcrFile -Path $crop -LanguageTag 'ar-SA' -DpiScale 1.0)
        $title = (@($tw | ForEach-Object { $_.Text }) -join ' ')
        Log "PROBE imgX=$px -> title='$title'"
        $probeRows += [ordered]@{
            imgX = $px
            screenX = $sx
            screenY = $sy
            title = $title
        }
        # Restore the grid's x positions are independent; the nav stays visible.
    }
    Save-Json -Name 'probe-navmap.json' -Object @{ rect = $rect; rows = $probeRows }
    return [ordered]@{ rect = $rect; rows = $probeRows }
}

# Probe mode: after login, click a range of X positions along the AppBar actions
# group (relative to the OCR display-name band) and classify the resulting screen
# to map each icon position. Used to validate Click-AppBarIcon's offsets
# (users = name.right+72, settings = name.right+24, logout = name.left-24).
function Step-ProbeAppBar {
    param($Cfg, $U)
    $h = $script:AppHandle
    Start-Sleep -Milliseconds 1500
    $rect = Get-WindowRectOut -Handle $h
    $png = Join-Path $ShotsDir 'probe-appbar-base.png'
    $null = Capture-AppWindowPng -Handle $h -File $png
    $words = @(Invoke-OcrFile -Path $png -LanguageTag 'ar-SA' -DpiScale 1.0)
    $band = @($words | Where-Object { $_.Y -ge 40 -and $_.Y -le 115 -and $_.X -lt 350 })
    if ($band.Count -lt 2) {
        Save-OcrDump -Name 'probe-appbar-ocrdump.txt' -Words $words
        throw 'appbar name band not found in probe'
    }
    $minX = [int](($band | ForEach-Object { $_.X } | Measure-Object -Minimum).Minimum)
    $maxX = [int](($band | ForEach-Object { $_.X + $_.W } | Measure-Object -Maximum).Maximum)
    $nameY = [int](($band | ForEach-Object { $_.Y + $_.H / 2 } | Measure-Object -Average).Average)
    $null = Log "PROBE appbar name=[$minX..$maxX] y=$nameY"

    $loginWord = [string]($U.login.buttonLogin -split '\s+')[0]
    $usersWord = [string]($U.users.fabNewUser -split '\s+')[1]
    $settingsWord = [string]($U.dashboard.settings -split '\s+')[0]
    $dashboardTitle = [string]($U.dashboard.title -split '\s+')[0]

    $probeX = @(($minX - 40), ($minX - 24), $minX, ($minX + 24), ($minX + 48), ($minX + 72), ($minX + 96),
        ($minX + 120), ($minX + 144), $maxX, ($maxX + 24), ($maxX + 48), ($maxX + 72), ($maxX + 96), ($maxX + 120))
    $rows = @()
    foreach ($cx in $probeX) {
        $sx = $rect.Left + $cx
        $sy = $rect.Top + $nameY
        $null = Log "PROBE appbar click imgX=$cx screen=($sx,$sy)"
        [void](Force-ForegroundWindow -Handle $h)
        Start-Sleep -Milliseconds 300
        [M13PWinNative]::ClickAt($sx, $sy)
        Start-Sleep -Milliseconds 1100
        $chk = Join-Path $ShotsDir "probe-appbar-x$cx.png"
        $null = Capture-AppWindowPng -Handle $h -File $chk
        $cw = @(Invoke-OcrFile -Path $chk -LanguageTag 'ar-SA' -DpiScale 1.0)
        # Markers: login button word (login screen), users FAB word (users screen),
        # settings AppBar title word in the top band (settings screen), dashboard
        # title word in the top band (still dashboard -> no-op click).
        $inTopBand = @($cw | Where-Object { $_.Y -ge 30 -and $_.Y -le 95 -and $_.X -ge 500 })
        $screen = 'none'
        if ($cw | Where-Object { Test-OcrStripAl $loginWord $_.Text }) { $screen = 'logout' }
        elseif ($cw | Where-Object { Test-OcrStripAl $usersWord $_.Text }) { $screen = 'users' }
        elseif ($inTopBand | Where-Object { Test-OcrStripAl $settingsWord $_.Text }) { $screen = 'settings' }
        elseif (-not ($inTopBand | Where-Object { Test-OcrStripAl $dashboardTitle $_.Text })) { $screen = 'unknown' }
        $rows += [ordered]@{ imgX = $cx; screen = $screen }
        $null = Log "PROBE appbar imgX=$cx -> $screen"
        if ($screen -eq 'logout') {
            $fieldDefs = [ordered]@{
                user = [ordered]@{ label = [string]$U.login.fieldUsername; value = [string]$U.owner.username }
                pass = [ordered]@{ label = [string]$U.login.fieldPassword; value = [string]$U.owner.password; secret = $true }
            }
            $methods = Fill-SimpleFields -Handle $h -FieldDefs $fieldDefs -ShotDir $ShotsDir -Tag 'probe-relogin'
            $btn = Click-OcrExact -Handle $h -Parts @($U.login.buttonLogin) -ShotDir $ShotsDir -Tag 'probe-relogin-b' -Transient
            if (-not $btn.clicked) { throw 'relogin button not found in probe' }
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            while ($sw.Elapsed.TotalSeconds -lt 60) {
                $chk2 = Join-Path $ShotsDir 'probe-appbar-relogin.png'
                $null = Capture-AppWindowPng -Handle $h -File $chk2
                $cw2 = @(Invoke-OcrFile -Path $chk2 -LanguageTag 'ar-SA' -DpiScale 1.0)
                $tb2 = @($cw2 | Where-Object { $_.Y -ge 30 -and $_.Y -le 95 -and $_.X -ge 500 })
                if ($tb2 | Where-Object { Test-OcrStripAl $dashboardTitle $_.Text }) { break }
                Start-Sleep -Milliseconds 700
            }
            Start-Sleep -Milliseconds 1000
        } elseif ($screen -ne 'none') {
            # Opened a sub-screen: back out until the dashboard title returns.
            [void](Click-Back -Handle $h)
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            while ($sw.Elapsed.TotalSeconds -lt 10) {
                $chk2 = Join-Path $ShotsDir 'probe-appbar-back.png'
                $null = Capture-AppWindowPng -Handle $h -File $chk2
                $cw2 = @(Invoke-OcrFile -Path $chk2 -LanguageTag 'ar-SA' -DpiScale 1.0)
                $tb2 = @($cw2 | Where-Object { $_.Y -ge 30 -and $_.Y -le 95 -and $_.X -ge 500 })
                if ($tb2 | Where-Object { Test-OcrStripAl $dashboardTitle $_.Text }) { break }
                [void](Click-Back -Handle $h)
                Start-Sleep -Milliseconds 800
            }
            Start-Sleep -Milliseconds 700
        }
    }
    Save-Json -Name 'probe-appbar.json' -Object @{ rect = $rect; nameBand = "$minX..$maxX"; nameY = $nameY; rows = $rows }
    return [ordered]@{ rect = $rect; nameBand = "$minX..$maxX"; nameY = $nameY; rows = $rows }
}

# Match an OCR word against a screen marker after stripping the leading Arabic
# article ال from both sides (a settings screen titled إعدادات التطبيق often
# OCRs as إعدادات without ال). Used only for screen-classification markers.
function Test-OcrStripAl {
    param([Parameter(Mandatory = $true)][string]$Expected, [Parameter(Mandatory = $true)][string]$OcrWord)
    $a = ConvertTo-OcrNormalized $Expected
    $b = ConvertTo-OcrNormalized $OcrWord
    if ($a.Length -eq 0) { return $false }
    if ($a -ceq $b) { return $true }
    $al = ([string][char]0x0627) + ([string][char]0x0644)
    if ($a.Length -ge 3 -and $a.StartsWith($al)) { $a = $a.Substring(2) }
    if ($b.Length -ge 3 -and $b.StartsWith($al)) { $b = $b.Substring(2) }
    if ($a.Length -eq 0 -or $b.Length -eq 0) { return $false }
    return ($a -ceq $b)
}

# Probe mode: reproduce Step-CreateSale's nav-sales click (from the inventory
# screen after S04), then report the resulting app-bar title.
function Step-ProbeNavSales {
    param($Cfg, $U)
    $h = $script:AppHandle
    Start-Sleep -Milliseconds 1200
    $navLabels = @($U.dashboard.title, $U.dashboard.navInventory, $U.dashboard.navSales, $U.dashboard.navReturns, $U.dashboard.navExpenses, $U.dashboard.navStocktake)
    $nav = Click-NavTileByRank -Handle $h -Labels $navLabels -Rank 2 -ShotDir $ShotsDir -Tag 'nav-sales-probe'
    Log "PROBE nav-sales clicked=$($nav.clicked) screenX=$($nav.screenX) screenY=$($nav.screenY) word=$($nav.word)"
    Start-Sleep -Milliseconds 1200
    $png = Join-Path $ShotsDir 'probe-sales-after.png'
    $null = Capture-AppWindowPng -Handle $h -File $png
    $words = @(Invoke-OcrFile -Path $png -LanguageTag 'ar-SA' -DpiScale 1.0)
    Save-OcrDump -Name 'probe-sales-after.txt' -Words $words
    $titleParts = @([string]$U.dashboard.title, [string]$U.dashboard.navInventory, [string]$U.dashboard.navSales,
        [string]$U.dashboard.navReturns, [string]$U.dashboard.navExpenses, [string]$U.dashboard.navStocktake)
    $best = @()
    foreach ($tp in $titleParts) {
        foreach ($w in $words) {
            if (Test-OcrWordSimilar $tp $w.Text) { $best += $tp }
        }
    }
    $appBar = $words | Where-Object { $_.Y -ge 40 -and $_.Y -le 110 }
    $appBarText = (@($appBar | ForEach-Object { $_.Text }) -join ' ')
    Save-Json -Name 'probe-navsales.json' -Object @{ clicked = $nav.clicked; screenX = $nav.screenX; screenY = $nav.screenY; word = $nav.word; appBarWords = $appBarText; similarTitles = $best }
    return [ordered]@{ nav = $nav; appBarText = $appBarText; similarTitles = $best }
}

# Probe mode: from the invoice creation screen, add the 17W product to the cart,
# then click the price TextField at several Y offsets from the OCR label row and
# record whether the typed value '100' is detected in the field band. Used to
# find the correct click offset for the floating-label price field.
function Step-ProbePriceField {
    param($Cfg, $U)
    $h = $script:AppHandle
    Start-Sleep -Milliseconds 1200

    $navLabels = @($U.dashboard.title, $U.dashboard.navInventory, $U.dashboard.navSales, $U.dashboard.navReturns, $U.dashboard.navExpenses, $U.dashboard.navStocktake)
    $nav = Click-NavTileByRank -Handle $h -Labels $navLabels -Rank 2 -ShotDir $ShotsDir -Tag 'nav-sales-probe'
    if (-not $nav.clicked) { throw 'sales nav not found' }
    Start-Sleep -Milliseconds 1200

    $fab = Click-OcrCropped -Handle $h -Parts @($U.sales.fabNewInvoice -split '\s+') -ShotDir $ShotsDir -Tag 'fab-inv-probe' `
        -X0 0 -Y0 0.72 -X1 0.4 -Y1 1.0 -Scale 3 -Exact
    if (-not $fab.clicked) { throw 'new-invoice FAB not found' }
    Start-Sleep -Milliseconds 1500

    # Wait for grid + scroll to the 17W product.
    $gridReady = $false
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt 45) {
        $chk = Join-Path $ShotsDir 'probe-price-grid.png'
        $null = Capture-AppWindowPng -Handle $h -File $chk
        $cw = @(Invoke-OcrFile -Path $chk -LanguageTag 'ar-SA' -DpiScale 1.0)
        if ($null -ne (Find-OcrWordByParts -Words $cw -Parts @($U.invoice.labelCart -split '\s+')) -and
            $null -ne (Find-OcrWordByParts -Words $cw -Parts @('17W'))) { $gridReady = $true; break }
        if ($sw.Elapsed.TotalSeconds -gt 5) {
            $rect = Get-WindowRectOut -Handle $h
            [void][M13PWinNative]::SetCursorPos(($rect.Left + 1200), ($rect.Top + 500))
            Start-Sleep -Milliseconds 250
            Send-WheelDown -Notches 10
            Start-Sleep -Milliseconds 600
        }
        Start-Sleep -Milliseconds 700
    }
    if (-not $gridReady) { throw 'invoice screen product grid not ready' }

    # Click the product card.
    $chk = Join-Path $ShotsDir 'probe-price-grid2.png'
    $null = Capture-AppWindowPng -Handle $h -File $chk
    $cw = @(Invoke-OcrFile -Path $chk -LanguageTag 'ar-SA' -DpiScale 1.0)
    $pw = @($cw | Where-Object { $_.Text -eq '17W' } | Sort-Object Y)[0]
    if ($null -eq $pw) { throw 'product card word not found in grid' }
    $rect = Get-WindowRectOut -Handle $h
    $sx = $rect.Left + [int]($pw.X + $pw.W / 2)
    $sy = $rect.Top + [int]($pw.Y + $pw.H / 2)
    [void](Force-ForegroundWindow -Handle $h)
    Start-Sleep -Milliseconds 350
    [M13PWinNative]::ClickAt($sx, $sy)
    Start-Sleep -Milliseconds 900

    # Wait for the price field label to appear (item card rendered in cart).
    $labelReady = $false
    $sw.Restart()
    while ($sw.Elapsed.TotalSeconds -lt 20) {
        $chk = Join-Path $ShotsDir 'probe-price-label.png'
        $null = Capture-AppWindowPng -Handle $h -File $chk
        $cw = @(Invoke-OcrFile -Path $chk -LanguageTag 'ar-SA' -DpiScale 1.0)
        if ($null -ne (Find-OcrWordByParts -Words $cw -Parts @($U.invoice.fieldPrice -split '\s+'))) { $labelReady = $true; break }
        Start-Sleep -Milliseconds 600
    }
    if (-not $labelReady) { throw 'price field label not visible after add-to-cart' }

    # Try click offsets and verify the typed value lands. The click X is the
    # center of the label words themselves (clustering with the sibling
    # 'الكمية:' label would land the click in the gap between the two fields).
    $rows = @()
    foreach ($off in @(16, 20, 24, 28, 32, 36, 40)) {
        $chk = Join-Path $ShotsDir 'probe-price-off.png'
        $null = Capture-AppWindowPng -Handle $h -File $chk
        $cw = @(Invoke-OcrFile -Path $chk -LanguageTag 'ar-SA' -DpiScale 1.0)
        $labelParts = @($U.invoice.fieldPrice -split '\s+')
        $lw = @($cw | Where-Object { if (Test-OcrWordExact $labelParts[0] $_.Text) { $true } elseif (Test-OcrWordExact $labelParts[1] $_.Text) { $true } else { $false } } | Sort-Object Y)
        if ($lw.Count -lt 2) { $rows += [ordered]@{ offset = $off; found = $false; reason = 'no-label' }; continue }
        $lTop = [int]($lw | ForEach-Object { $_.Y } | Measure-Object -Minimum).Minimum
        $lLeft = [int]($lw | ForEach-Object { $_.X } | Measure-Object -Minimum).Minimum
        $lRight = [int]($lw | ForEach-Object { $_.X + $_.W } | Measure-Object -Maximum).Maximum
        $cx = [int](($lLeft + $lRight) / 2)
        $cy = [int]($lTop + $off)
        $px = $rect.Left + $cx
        $py = $rect.Top + $cy
        [void](Force-ForegroundWindow -Handle $h)
        Start-Sleep -Milliseconds 300
        [M13PWinNative]::ClickAt($px, $py)
        Start-Sleep -Milliseconds 500
        [System.Windows.Forms.SendKeys]::SendWait('^a')
        Start-Sleep -Milliseconds 120
        [System.Windows.Forms.SendKeys]::SendWait('{BACKSPACE}')
        Start-Sleep -Milliseconds 120
        [System.Windows.Forms.SendKeys]::SendWait('{DELETE}')
        Start-Sleep -Milliseconds 150
        [M13PWinNative]::TypeText('100')
        Start-Sleep -Milliseconds 600

        $post = Join-Path $ShotsDir "probe-price-off$off.png"
        $null = Capture-AppWindowPng -Handle $h -File $post
        $pWords = @(Invoke-OcrFile -Path $post -LanguageTag 'ar-SA' -DpiScale 1.0)
        $bandTop = [int]($lTop - 15)
        $bandBot = [int]($lTop + 55)
        $found = @($pWords | Where-Object {
            $_.Y -ge $bandTop -and $_.Y -lt $bandBot -and
            $_.Text.IndexOf('100', [System.StringComparison]::Ordinal) -ge 0
        })
        $bandText = (@($pWords | Where-Object { $_.Y -ge $bandTop -and $_.Y -lt $bandBot } | Sort-Object Y, X | ForEach-Object { $_.Text }) -join ' ')
        $rowRes = [ordered]@{ offset = $off; labelTop = $lTop; clickX = $cx; clickY = $cy; clicked = "x=$px y=$py"; found = ($found.Count -gt 0); bandText = $bandText }
        $null = Log "PROBE price offset=$off labelTop=$lTop click=(x=$px y=$py) found=$($found.Count -gt 0) band='$bandText'"
        $rows += $rowRes

        # Clear the field for the next offset.
        [M13PWinNative]::ClickAt($px, $py)
        Start-Sleep -Milliseconds 400
        [System.Windows.Forms.SendKeys]::SendWait('^a')
        Start-Sleep -Milliseconds 120
        [System.Windows.Forms.SendKeys]::SendWait('{BACKSPACE}')
        Start-Sleep -Milliseconds 400
    }
    Save-Json -Name 'probe-price-field.json' -Object @{ offsets = $rows }
    return [ordered]@{ offsets = $rows }
}

# ---------------- main ----------------

Prevent-SystemSleep

$Cfg = [ordered]@{
    runId = $RunId
    releaseDir = (Resolve-Path -LiteralPath $ReleaseDir).Path
    evidenceRoot = (Resolve-Path -LiteralPath $EvidenceRoot).Path
    tempDir = Join-Path $env:TEMP 'muaman-17w'
    tempPdfDir = Join-Path $env:TEMP 'muaman-17w\pdf'
    destPdfName = 'invoice_17w_acceptance.pdf'
}

$U = [System.IO.File]::ReadAllText($UiStringsPath, (New-Object System.Text.UTF8Encoding $false)) | ConvertFrom-Json

$meta = [ordered]@{
    runId = $Cfg.runId
    startUtc = Get-UtcString
    machine = $env:COMPUTERNAME
    user = $env:USERNAME
    releaseDir = $Cfg.releaseDir
    headSha = ((& git -C (Split-Path -Parent $PSScriptRoot | Split-Path -Parent) rev-parse HEAD 2>$null) | Select-Object -First 1)
    os = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Caption)
}
Save-Json -Name '01-run-metadata.json' -Object $meta
Log "runId=$RunId metadata saved"

$null = Invoke-Step 'S01-launch' { Step-Launch -Cfg $Cfg -U $U }
if (-not $script:Abort) { $null = Invoke-Step 'S02-setup-owner' { Step-SetupOwner -Cfg $Cfg -U $U } }
if (-not $script:Abort) { $null = Invoke-Step 'S03-login-owner' { Step-LoginOwner -Cfg $Cfg -U $U } }
if ($ProbeNavMap) {
    if (-not $script:Abort) { $null = Invoke-Step 'S04-probe-navmap' { Step-ProbeNavMap -Cfg $Cfg -U $U } }
    if (-not $script:Abort) { $null = Invoke-Step 'S05-cleanup-probe' { Step-LogoutAndClose -Cfg $Cfg -U $U } }
} elseif ($ProbeNavSales) {
    if (-not $script:Abort) { $null = Invoke-Step 'S04-add-product' { Step-AddProduct -Cfg $Cfg -U $U } }
    if (-not $script:Abort) { $null = Invoke-Step 'S05-probe-navsales' { Step-ProbeNavSales -Cfg $Cfg -U $U } }
    if (-not $script:Abort) { $null = Invoke-Step 'S06-cleanup-probe' { Step-LogoutAndClose -Cfg $Cfg -U $U } }
} elseif ($ProbePriceField) {
    if (-not $script:Abort) { $null = Invoke-Step 'S04-add-product' { Step-AddProduct -Cfg $Cfg -U $U } }
    if (-not $script:Abort) { $null = Invoke-Step 'S05-probe-price-field' { Step-ProbePriceField -Cfg $Cfg -U $U } }
    if (-not $script:Abort) { $null = Invoke-Step 'S06-cleanup-probe' { Step-LogoutAndClose -Cfg $Cfg -U $U } }
} elseif ($ProbeAppBar) {
    if (-not $script:Abort) { $null = Invoke-Step 'S04-probe-appbar' { Step-ProbeAppBar -Cfg $Cfg -U $U } }
    if (-not $script:Abort) { $null = Invoke-Step 'S05-cleanup-probe' { Step-LogoutAndClose -Cfg $Cfg -U $U } }
} elseif ($ProbeRole) {
    if (-not $script:Abort) { $null = Invoke-Step 'S04-probe-role' { Step-ProbeRole -Cfg $Cfg -U $U } }
    if (-not $script:Abort) { $null = Invoke-Step 'S05-cleanup-probe' { Step-LogoutAndClose -Cfg $Cfg -U $U } }
} else {
if (-not $script:Abort) { $null = Invoke-Step 'S04-add-product' { Step-AddProduct -Cfg $Cfg -U $U } }
if (-not $script:Abort) { $null = Invoke-Step 'S05-create-sale' { Step-CreateSale -Cfg $Cfg -U $U } }
if (-not $script:Abort) { $null = Invoke-Step 'S06-save-pdf' { Step-SavePdf -Cfg $Cfg -U $U } }
if (-not $script:Abort) { $null = Invoke-Step 'S07-open-pdf' { Step-OpenPdf -Cfg $Cfg -U $U } }
if (-not $script:Abort) { $null = Invoke-Step 'S08-print-dialog' { Step-PrintDialog -Cfg $Cfg -U $U } }
if (-not $script:Abort) { $null = Invoke-Step 'S09-sales-history' { Step-SalesHistory -Cfg $Cfg -U $U } }
if (-not $script:Abort) { $null = Invoke-Step 'S10-add-cashier' { Step-AddCashierUser -Cfg $Cfg -U $U } }
if (-not $script:Abort) { $null = Invoke-Step 'S11-cashier-denied' { Step-LoginCashierDenied -Cfg $Cfg -U $U } }
if (-not $script:Abort) { $null = Invoke-Step 'S12-logout-close' { Step-LogoutAndClose -Cfg $Cfg -U $U } }
}

# Always attempt final evidence collection + app close.
try {
    if ($script:AppProc -and $script:AppHandle -ne [IntPtr]::Zero) {
        try { $script:AppProc.Refresh() } catch {}
        if (-not $script:AppProc.HasExited) {
            $close = Close-WindowGracefully -Handle $script:AppHandle -Process $script:AppProc -TimeoutSec 30
            Log "cleanup close: $($close.method)"
        }
    }
} catch {
    Log "cleanup close failed: $($_.Exception.Message)"
}

$null = Invoke-Step 'S13-final-evidence' { Step-FinalEvidence -Cfg $Cfg -U $U }

Restore-SystemSleep

$done = [ordered]@{
    runId = $Cfg.runId
    finishedUtc = Get-UtcString
    aborted = $script:Abort
    steps = $script:Results
}
Save-Json -Name 'worker-done.json' -Object $done
Log "WORKER DONE aborted=$($script:Abort)"
