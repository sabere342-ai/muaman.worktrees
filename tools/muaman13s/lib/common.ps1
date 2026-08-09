# common.ps1 - shared helpers for MUAMAN-13P acceptance harness.
# IMPORTANT: this file is ASCII-only. All Arabic UI strings are loaded from ui_strings.json.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:WinNativeLoaded = $false
$script:UiaLoaded = $false
$script:WinFormsLoaded = $false
$script:OcrLoaded = $false

function Initialize-WinNative {
    if ($script:WinNativeLoaded) { return }
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -ReferencedAssemblies @(([System.Drawing.Image].Assembly.Location), ([System.Windows.Forms.Application].Assembly.Location)) -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;

public static class M13PWinNative
{
    static M13PWinNative() {
        try { if (Environment.GetEnvironmentVariable("M13P_DPI_AWARE") == "1") SetProcessDPIAware(); } catch {}
    }
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hWnd, ref POINT lpPoint);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool SetActiveWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hWnd);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(IntPtr hWnd, StringBuilder text, int count);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr parent, EnumWindowsProc callback, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc callback, IntPtr lParam);
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    public static bool ForceForeground(IntPtr hWnd) {
        if (IsIconic(hWnd)) ShowWindow(hWnd, 9);
        keybd_event(0x12, 0, 0, UIntPtr.Zero);      // fake ALT down to satisfy foreground lock
        keybd_event(0x12, 0, 2, UIntPtr.Zero);      // ALT up
        uint targetThread;
        GetWindowThreadProcessId(hWnd, out targetThread);
        uint currentThread = GetCurrentThreadId();
        bool attached = AttachThreadInput(currentThread, targetThread, true);
        ShowWindow(hWnd, 9);
        bool ok = SetForegroundWindow(hWnd);
        BringWindowToTop(hWnd);
        SetActiveWindow(hWnd);
        if (attached) AttachThreadInput(currentThread, targetThread, false);
        return ok;
    }
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X; public int Y; }

    public static string WindowTitle(IntPtr hWnd) {
        StringBuilder sb = new StringBuilder(512);
        GetWindowText(hWnd, sb, 512);
        return sb.ToString();
    }
    public static string WindowClass(IntPtr hWnd) {
        StringBuilder sb = new StringBuilder(512);
        GetClassName(hWnd, sb, 512);
        return sb.ToString();
    }
    public static string CaptureWindow(IntPtr hWnd, string filePath) {
        RECT r;
        if (!GetWindowRect(hWnd, out r)) return "GetWindowRect failed";
        int w = r.Right - r.Left;
        int h = r.Bottom - r.Top;
        if (w <= 0 || h <= 0) return "empty rect (" + w + "x" + h + ")";
        using (Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb)) {
            using (Graphics g = Graphics.FromImage(bmp)) {
                g.CopyFromScreen(r.Left, r.Top, 0, 0, new Size(w, h), CopyPixelOperation.SourceCopy);
            }
            bmp.Save(filePath, ImageFormat.Png);
        }
        return "ok";
    }
    public static string CaptureDesktop(string filePath) {
        int sx = SystemInformation.VirtualScreen.Left;
        int sy = SystemInformation.VirtualScreen.Top;
        int sw = SystemInformation.VirtualScreen.Width;
        int sh = SystemInformation.VirtualScreen.Height;
        using (Bitmap bmp = new Bitmap(sw, sh, PixelFormat.Format32bppArgb)) {
            using (Graphics g = Graphics.FromImage(bmp)) {
                g.CopyFromScreen(sx, sy, 0, 0, new Size(sw, sh), CopyPixelOperation.SourceCopy);
            }
            bmp.Save(filePath, ImageFormat.Png);
        }
        return "ok";
    }
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags);
    public static string CaptureWindowOwn(IntPtr hWnd, string filePath) {
        RECT r;
        if (!GetWindowRect2(hWnd, out r)) return "GetWindowRect failed";
        int w = r.Right - r.Left;
        int h = r.Bottom - r.Top;
        if (w <= 0 || h <= 0) return "empty rect (" + w + "x" + h + ")";
        using (Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb)) {
            using (Graphics g = Graphics.FromImage(bmp)) {
                IntPtr hdc = g.GetHdc();
                try {
                    bool ok = PrintWindow(hWnd, hdc, 0x2);
                    if (!ok) return "PrintWindow failed";
                } finally {
                    g.ReleaseHdc(hdc);
                }
            }
            bmp.Save(filePath, ImageFormat.Png);
        }
        return "ok";
    }
    public static double ImageStdDev(string filePath) {
        using (Bitmap bmp = new Bitmap(filePath)) {
            double sum = 0; double sumSq = 0; long n = 0;
            for (int y = 0; y < bmp.Height; y += 8) {
                for (int x = 0; x < bmp.Width; x += 8) {
                    Color c = bmp.GetPixel(x, y);
                    double v = (c.R + c.G + c.B) / 3.0;
                    sum += v; sumSq += v * v; n++;
                }
            }
            double mean = sum / n;
            return System.Math.Sqrt(System.Math.Max(0, sumSq / n - mean * mean));
        }
    }
    public static IntPtr CurrentForeground() { return GetForegroundWindow(); }
    public static IntPtr[] ChildWindows(IntPtr parent) {
        System.Collections.Generic.List<IntPtr> list = new System.Collections.Generic.List<IntPtr>();
        EnumChildWindows(parent, delegate(IntPtr hWnd, IntPtr lp) { list.Add(hWnd); return true; }, IntPtr.Zero);
        return list.ToArray();
    }
    public static IntPtr FindProcessWindow(uint pid, string className) {
        IntPtr found = IntPtr.Zero;
        EnumWindows(delegate(IntPtr hWnd, IntPtr lp) {
            uint wpid;
            GetWindowThreadProcessId(hWnd, out wpid);
            if (wpid == pid) {
                if (string.IsNullOrEmpty(className) || WindowClass(hWnd).IndexOf(className, System.StringComparison.OrdinalIgnoreCase) >= 0) {
                    found = hWnd;
                    return false;
                }
            }
            return true;
        }, IntPtr.Zero);
        return found;
    }
    [DllImport("user32.dll", SetLastError = true)] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int X, int Y);
    [DllImport("user32.dll", EntryPoint = "GetWindowRect")] public static extern bool GetWindowRect2(IntPtr hWnd, out RECT lpRect);
    public static int[] WindowRect(IntPtr hWnd) {
        RECT r;
        if (!GetWindowRect2(hWnd, out r)) return new int[] { 0, 0, 0, 0 };
        return new int[] { r.Left, r.Top, r.Right - r.Left, r.Bottom - r.Top };
    }
    [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, UIntPtr dwExtraInfo);
    [DllImport("user32.dll")] public static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);
    [DllImport("user32.dll")] public static extern int GetDpiForWindow(IntPtr hWnd);

    [StructLayout(LayoutKind.Sequential)]
    public struct INPUT {
        public uint type;
        public INPUTUNION u;
    }
    [StructLayout(LayoutKind.Explicit)]
    public struct INPUTUNION {
        [FieldOffset(0)] public KEYBDINPUT ki;
        [FieldOffset(0)] public MOUSEINPUT mi;
    }
    [StructLayout(LayoutKind.Sequential)]
    public struct KEYBDINPUT {
        public ushort wVk;
        public ushort wScan;
        public uint dwFlags;
        public uint time;
        public UIntPtr dwExtraInfo;
    }
    [StructLayout(LayoutKind.Sequential)]
    public struct MOUSEINPUT {
        public int dx;
        public int dy;
        public uint mouseData;
        public uint dwFlags;
        public uint time;
        public UIntPtr dwExtraInfo;
    }

    public static void ClickAt(int x, int y) {
        SetCursorPos(x, y);
        System.Threading.Thread.Sleep(40);
        mouse_event(0x0002, 0, 0, 0, UIntPtr.Zero);
        System.Threading.Thread.Sleep(40);
        mouse_event(0x0004, 0, 0, 0, UIntPtr.Zero);
    }
    public static void TypeText(string text) {
        if (string.IsNullOrEmpty(text)) return;
        var inputs = new INPUT[text.Length * 2];
        for (int i = 0; i < text.Length; i++) {
            ushort ch = (ushort)text[i];
            inputs[2 * i].type = 1;
            inputs[2 * i].u.ki.wVk = 0;
            inputs[2 * i].u.ki.wScan = ch;
            inputs[2 * i].u.ki.dwFlags = 0x0004;
            inputs[2 * i].u.ki.dwExtraInfo = UIntPtr.Zero;
            inputs[2 * i + 1].type = 1;
            inputs[2 * i + 1].u.ki.wVk = 0;
            inputs[2 * i + 1].u.ki.wScan = ch;
            inputs[2 * i + 1].u.ki.dwFlags = 0x0004 | 0x0002;
            inputs[2 * i + 1].u.ki.dwExtraInfo = UIntPtr.Zero;
        }
        SendInput((uint)inputs.Length, inputs, System.Runtime.InteropServices.Marshal.SizeOf(typeof(INPUT)));
    }
    public static void SendTab() {
        INPUT i = new INPUT();
        i.type = 1; i.u.ki.wVk = 0x09; i.u.ki.dwFlags = 0; i.u.ki.dwExtraInfo = UIntPtr.Zero;
        INPUT i2 = new INPUT();
        i2.type = 1; i2.u.ki.wVk = 0x09; i2.u.ki.dwFlags = 0x0002; i2.u.ki.dwExtraInfo = UIntPtr.Zero;
        INPUT[] arr = new INPUT[] { i, i2 };
        SendInput(2, arr, System.Runtime.InteropServices.Marshal.SizeOf(typeof(INPUT)));
    }
    public static void SendEnter() {
        INPUT i = new INPUT();
        i.type = 1; i.u.ki.wVk = 0x0D; i.u.ki.dwFlags = 0; i.u.ki.dwExtraInfo = UIntPtr.Zero;
        INPUT i2 = new INPUT();
        i2.type = 1; i2.u.ki.wVk = 0x0D; i2.u.ki.dwFlags = 0x0002; i2.u.ki.dwExtraInfo = UIntPtr.Zero;
        INPUT[] arr = new INPUT[] { i, i2 };
        SendInput(2, arr, System.Runtime.InteropServices.Marshal.SizeOf(typeof(INPUT)));
    }
    [DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);
    public const uint ES_CONTINUOUS = 0x80000000;
    public const uint ES_SYSTEM_REQUIRED = 0x00000001;
    public const uint ES_DISPLAY_REQUIRED = 0x00000002;
}
'@
    $script:WinNativeLoaded = $true
}

# Keep the machine (and display) awake for the duration of a run so idle sleep
# cannot suspend the app between captures. Call Restore-SystemSleep when done.
function Prevent-SystemSleep {
    Initialize-WinNative
    [void][M13PWinNative]::SetThreadExecutionState([M13PWinNative]::ES_CONTINUOUS -bor [M13PWinNative]::ES_SYSTEM_REQUIRED -bor [M13PWinNative]::ES_DISPLAY_REQUIRED)
}

function Restore-SystemSleep {
    if (-not $script:WinNativeLoaded) { return }
    [void][M13PWinNative]::SetThreadExecutionState([M13PWinNative]::ES_CONTINUOUS)
}

function Initialize-Uia {
    if ($script:UiaLoaded) { return }
    Add-Type -AssemblyName UIAutomationClient -ErrorAction Stop
    Add-Type -AssemblyName UIAutomationTypes -ErrorAction Stop
    $script:UiaLoaded = $true
}

function Initialize-WinForms {
    if ($script:WinFormsLoaded) { return }
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    $script:WinFormsLoaded = $true
}

function Initialize-Ocr {
    if ($script:OcrLoaded) { return }
    Add-Type -AssemblyName System.Runtime.WindowsRuntime -ErrorAction Stop
    $null = [Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime]
    $null = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
    $null = [Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics.Imaging, ContentType = WindowsRuntime]
    $script:OcrLoaded = $true
}

# Wait for a WinRT IAsyncOperation<T> via the AsTask reflection bridge.
function Wait-WinRtAsync {
    param($AsyncOperation, [Type]$ResultType)
    Initialize-Ocr
    $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() |
        Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.IsGenericMethod })[0]
    $method = $asTaskGeneric.MakeGenericMethod($ResultType)
    $task = $method.Invoke($null, @($AsyncOperation))
    return $task.Result
}

# OCR an image file and return one object per recognized word:
# { Text, X, Y, W, H } in image pixels (scale-corrected from OCR DIPs via dpiScale).
function Invoke-OcrFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string]$LanguageTag = 'ar-SA',
        [double]$DpiScale = 1.0
    )
    Initialize-Ocr
    $file = Wait-WinRtAsync -AsyncOperation ([Windows.Storage.StorageFile]::GetFileFromPathAsync($Path)) -ResultType ([Windows.Storage.StorageFile])
    $stream = Wait-WinRtAsync -AsyncOperation ($file.OpenReadAsync()) -ResultType ([Windows.Storage.Streams.IRandomAccessStreamWithContentType])
    $decoder = Wait-WinRtAsync -AsyncOperation ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) -ResultType ([Windows.Graphics.Imaging.BitmapDecoder])
    $bitmap = Wait-WinRtAsync -AsyncOperation ($decoder.GetSoftwareBitmapAsync()) -ResultType ([Windows.Graphics.Imaging.SoftwareBitmap])
    $lang = $null
    if ($LanguageTag) {
        foreach ($l in [Windows.Media.Ocr.OcrEngine]::AvailableRecognizerLanguages) {
            if ($l.LanguageTag -eq $LanguageTag) { $lang = $l; break }
        }
    }
    $engine = if ($lang) { [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage($lang) } else { [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages() }
    if (-not $engine) { return @() }
    $result = Wait-WinRtAsync -AsyncOperation ($engine.RecognizeAsync($bitmap)) -ResultType ([Windows.Media.Ocr.OcrResult])
    $out = @()
    foreach ($line in $result.Lines) {
        foreach ($word in $line.Words) {
            $r = $word.BoundingRect
            $out += [pscustomobject]@{
                Text = [string]$word.Text
                X = [int][math]::Floor($r.X * $DpiScale)
                Y = [int][math]::Floor($r.Y * $DpiScale)
                W = [int][math]::Ceiling($r.Width * $DpiScale)
                H = [int][math]::Ceiling($r.Height * $DpiScale)
            }
        }
    }
    return $out
}

# Find OCR words matching a target substring; returns list of matched word objects.
function Find-OcrWords {
    param(
        $Words,
        [Parameter(Mandatory = $true)][string]$Target
    )
    return @($Words | Where-Object { $_.Text -like "*$Target*" })
}

# Estimate screen click point for the input field BELOW a label word.
# The field is drawn under the label text (label bottom + gap); we click centered,
# slightly below the label, assuming default field height ~40px at scale 1.
function Get-FieldClickPoint {
    param(
        [Parameter(Mandatory = $true)]$Label,
        [double]$DpiScale = 1.0
    )
    $cx = $Label.X + [int]($Label.W / 2)
    $cy = $Label.Y + $Label.H + [int](14 * $DpiScale)
    return [ordered]@{ X = $cx; Y = $cy }
}

# Window rect helpers for mapping OCR image coords to screen coords.
function Get-WindowRectOut {
    param([IntPtr]$Handle)
    Initialize-WinNative
    $r = [M13PWinNative]::WindowRect($Handle)
    return [ordered]@{ Left = $r[0]; Top = $r[1]; Width = $r[2]; Height = $r[3] }
}

# Robustly find a live top-level window for a process by class substring.
function Get-WindowByPidClass {
    param(
        [Parameter(Mandatory = $true)][int]$ProcessId,
        [string]$ClassName = 'FLUTTER_RUNNER_WIN32_WINDOW'
    )
    Initialize-WinNative
    $h = [M13PWinNative]::FindProcessWindow([uint32]$ProcessId, $ClassName)
    return $h
}

# Assert the window is usable (alive, correct class) and return facts.
function Test-AppWindowReady {
    param([IntPtr]$Handle, [string]$ExpectedClass = 'FLUTTER_RUNNER_WIN32_WINDOW')
    Initialize-WinNative
    if ($Handle -eq [IntPtr]::Zero) { return $false }
    $cls = [M13PWinNative]::WindowClass($Handle)
    return ($cls -like "*$ExpectedClass*")
}

# Launch a GUI app, wait for its main window, position it deterministically and
# bring it to the foreground. Returns proc/handle/windowFound. Screen coordinates
# from OCR images are mapped via the window rect from this handle.
function Get-LaunchWindow {
    param(
        [Parameter(Mandatory = $true)][string]$Exe,
        [string]$WorkDir,
        [hashtable]$Environment = @{},
        [int]$TimeoutSec = 180,
        [int]$PosX = 30,
        [int]$PosY = 30,
        [int]$PosW = 1500,
        [int]$PosH = 850
    )
    Initialize-WinNative
    $proc = Start-AppProcess -FilePath $Exe -WorkingDir $WorkDir -Environment $Environment
    $handle = Get-MainWindowHandle -Process $proc -TimeoutSec $TimeoutSec
    $windowFound = ($handle -ne [IntPtr]::Zero)
    if ($windowFound) {
        [void][M13PWinNative]::SetWindowPos($handle, [IntPtr]::Zero, $PosX, $PosY, $PosW, $PosH, 0x0040)
        Start-Sleep -Milliseconds 800
        [void](Force-ForegroundWindow -Handle $handle)
    }
    return [ordered]@{
        proc = $proc
        handle = $handle
        windowFound = $windowFound
    }
}

function Get-ChildWindowHandles {
    param([Parameter(Mandatory = $true)][IntPtr]$Handle)
    Initialize-WinNative
    return ,[M13PWinNative]::ChildWindows($Handle)
}

# Normalize Arabic OCR text so minor engine variance does not break matching:
# strip diacritics, fold hamza-bearing alef variants onto plain alef, and fold
# alef-maksura onto ya. ASCII-only source: the Arabic ranges are written as .NET
# regex unicode escapes.
function ConvertTo-OcrNormalized {
    param([Parameter(Mandatory = $true)][string]$S)
    if ($S.Length -eq 0) { return $S }
    $n = $S
    $n = $n -replace '[\u064B-\u065F\u0670]', ''
    $n = $n -replace '[\u0621\u0622\u0623\u0625]', ([string][char]0x0627)
    $n = $n -replace '\u0649', ([string][char]0x064A)
    return $n
}

# Classic Levenshtein distance (bounded helper for OCR word tolerance).
function Get-EditDistance {
    param([Parameter(Mandatory = $true)][string]$A, [Parameter(Mandatory = $true)][string]$B)
    if ($A.Length -eq 0) { return $B.Length }
    if ($B.Length -eq 0) { return $A.Length }
    $n = $B.Length
    $prev = New-Object 'int[]' ($n + 1)
    for ($j = 0; $j -le $n; $j++) { $prev[$j] = $j }
    for ($i = 1; $i -le $A.Length; $i++) {
        $cur = New-Object 'int[]' ($n + 1)
        $cur[0] = $i
        for ($j = 1; $j -le $n; $j++) {
            $cost = if ($A[$i - 1] -ceq $B[$j - 1]) { 0 } else { 1 }
            $cur[$j] = [Math]::Min([Math]::Min($prev[$j] + 1, $cur[$j - 1] + 1), $prev[$j - 1] + $cost)
        }
        $prev = $cur
    }
    return $prev[$n]
}

# Whether an OCR word counts as a match for an expected label word.
function Test-OcrWordSimilar {
    param([Parameter(Mandatory = $true)][string]$Expected, [Parameter(Mandatory = $true)][string]$OcrWord)
    $a = ConvertTo-OcrNormalized $Expected
    $b = ConvertTo-OcrNormalized $OcrWord
    if ($a.Length -eq 0) { return $false }
    if ($a -ceq $b) { return $true }
    # Relative threshold: short words stay strict (a 3-char label must not
    # match its 5-char sibling), longer words tolerate common Arabic OCR
    # confusions (taa/daal, khaa/haa, daal/faa swaps ~3 edits on an
    # 8-char word).
    $thr = [int][math]::Max(1, [math]::Floor($a.Length / 2.5))
    return ((Get-EditDistance $a $b) -le $thr)
}

# Restrict OCR words to the right-hand field/input column (labels sit beside
# the inputs; the left column carries captions and the action button). Ratio is
# relative to the widest word right-edge, so it needs no image dimensions.
function Filter-OcrFieldColumn {
    param($Words, [double]$Ratio = 0.6)
    if ($Ratio -le 0) { return ,$Words }
    $maxRight = [double](($Words | ForEach-Object { $_.X + $_.W } | Measure-Object -Maximum).Maximum)
    return @($Words | Where-Object { $_.X -ge [double]($maxRight * $Ratio) })
}

# Whether a FieldDef (OrderedDictionary or PSCustomObject) carries a key.
function Test-FieldDefHasKey {
    param($Def, [string]$Key)
    if ($Def -is [System.Collections.IDictionary]) { return $Def.Contains($Key) }
    return ($null -ne $Def -and ($Def.PSObject.Properties.Name -contains $Key))
}

# Find the top-most OCR word matching any of the label parts. Matching is exact
# after Arabic normalization, with a small edit-distance tolerance for OCR
# engine variance on small Arabic words. MinColRatio > 0 restricts the search
# to the right-hand field column (labels sit beside the inputs; captions and
# the action button live in the left column and must not shadow field labels).
function Find-OcrWordByParts {
    param(
        $Words,
        [Parameter(Mandatory = $true)][string[]]$Parts,
        [double]$MinColRatio = 0.0
    )
    $cand = @($Words)
    if ($MinColRatio -gt 0) { $cand = @(Filter-OcrFieldColumn -Words $Words -Ratio $MinColRatio) }
    foreach ($p in $Parts) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        $hits = @($cand | Where-Object { Test-OcrWordSimilar $p $_.Text } | Sort-Object Y)
        if ($hits.Count -gt 0) { return $hits[0] }
    }
    return $null
}

# ---- Row-based OCR targeting ----

# Cluster OCR words into visual rows by vertical overlap. Returns rows top-down,
# each with words and a bounding box (left/top/right/bottom) in image pixels.
# Arabic labels that the OCR engine splits across words (e.g. a label rendered as
# "اسم" + "المستخدم") and stray diacritic glyphs sharing a row stay together, so
# matching can operate on whole rows instead of single words.
function ConvertTo-OcrRows {
    param($Words)
    $rows = New-Object System.Collections.ArrayList
    foreach ($w in @($Words | Sort-Object Y, X)) {
        $wBottom = $w.Y + $w.H
        $added = $false
        for ($i = 0; $i -lt $rows.Count; $i++) {
            $r = $rows[$i]
            if (($w.Y -lt $r.bottom) -and ($wBottom -gt $r.top)) {
                $r.words = @($r.words) + $w
                if ($w.Y -lt $r.top) { $r.top = $w.Y }
                if ($wBottom -gt $r.bottom) { $r.bottom = $wBottom }
                if ($w.X -lt $r.left) { $r.left = $w.X }
                if (($w.X + $w.W) -gt $r.right) { $r.right = $w.X + $w.W }
                $added = $true
                break
            }
        }
        if (-not $added) {
            [void]$rows.Add([pscustomobject]@{
                words = @($w)
                top = $w.Y
                bottom = $w.Y + $w.H
                left = $w.X
                right = $w.X + $w.W
            })
        }
    }
    return $rows | Sort-Object top
}

# Return every visual row whose word set contains a similar word for EVERY
# expected label part (row-wise multi-word matching). Returns rows top-down.
function Find-OcrLabelRows {
    param(
        $Words,
        [Parameter(Mandatory = $true)][string[]]$Parts
    )
    $hits = @()
    foreach ($r in @(ConvertTo-OcrRows -Words $Words)) {
        $ok = $true
        foreach ($p in $Parts) {
            if ([string]::IsNullOrWhiteSpace($p)) { continue }
            $m = @($r.words | Where-Object { Test-OcrWordSimilar $p $_.Text })
            if ($m.Count -eq 0) { $ok = $false; break }
        }
        if ($ok) { $hits += $r }
    }
    return $hits | Sort-Object top
}

# Resolve every field of an ordered FieldDefs map to exactly one label row from a
# single OCR pass. Each label is matched row-wise (all parts in one visual row);
# a label matching several rows (e.g. the password label is shared by the
# password and confirm-password rows) is disambiguated by taking the top-most
# candidate strictly below the previous field's row. Returns an ordered map
# key -> { label, words, top, bottom, left, right } or $null when any field has
# zero candidates, or the resolved rows are not strictly top-down ordered.
function Resolve-OcrFieldRows {
    param(
        $Words,
        [Parameter(Mandatory = $true)][System.Collections.IDictionary]$FieldDefs
    )
    # Field labels live in the right-hand column of the form; the centered
    # header/tagline/button rows must not be considered candidates. The column
    # threshold is derived from the capture (rightmost word edge), so it holds
    # even if the window size or layout scale changes.
    $allRows = @(ConvertTo-OcrRows -Words $Words)
    $maxRight = [int](@($allRows | ForEach-Object { $_.right } | Measure-Object -Maximum).Maximum)
    $colMinX = [int]($maxRight * 0.7)
    $resolved = [ordered]@{}
    $prevBottom = [int](-1)
    foreach ($key in @($FieldDefs.Keys)) {
        $label = [string]$FieldDefs[$key].label
        $parts = @($label -split '\s+')
        $cands = @(Find-OcrLabelRows -Words $Words -Parts $parts |
            Where-Object { $_.left -ge $colMinX -and $_.top -gt $prevBottom })
        if ($cands.Count -eq 0) { return $null }
        $chosen = $cands[0]
        $resolved[$key] = [ordered]@{
            label = $label
            words = $chosen.words
            top = $chosen.top
            bottom = $chosen.bottom
            left = $chosen.left
            right = $chosen.right
        }
        $prevBottom = $chosen.bottom
    }
    return $resolved
}

# Derive the screen-relative click point for the input box of a resolved label
# row, from the SAME capture. X sits just left of the row's text, inside the
# input box (the box spans from x~1000 to the window's right edge in this
# layout, with the right-aligned label near the right edge); Y is the row's
# vertical center, which stays inside the input box whether the label is at
# rest (centered in the box) or floated (moved up to the box top).
function Get-OcrRowInputRect {
    param($Row, [int]$ClickXPad = 90, [int]$MinX = 1150)
    $cx = [int][math]::Max($Row.left - $ClickXPad, $MinX)
    $cy = [int](($Row.top + $Row.bottom) / 2)
    return [ordered]@{ X = $cx; Y = $cy }
}

# Maximum OCR height among the words of a resolved field row that plausibly
# belong to the field's label (match one of the expected label parts). Stray
# noise glyphs that ride in the same row are excluded from the metric.
function Get-OcrRowPartMaxH {
    param($Row, [Parameter(Mandatory = $true)][string[]]$Parts)
    $hs = @()
    foreach ($w in @($Row.words)) {
        $hit = $false
        foreach ($p in $Parts) { if (Test-OcrWordSimilar $p $w.Text) { $hit = $true; break } }
        if ($hit) { $hs += [int]$w.H }
    }
    return [int](@($hs | Measure-Object -Maximum).Maximum)
}

# Whether a resolved-row set shows the intended field as the focused one.
# A focused field's label floats: its OCR height shrinks versus the same
# field's label in the pre-click capture. Filled sibling fields legitimately
# keep floated labels, so only the target's own shrink is required. The first
# field of the screen is autofocused with its label already floated (the label
# does not shrink), so for FieldIndex 0 the assertion passes when the target
# resolves and no sibling label is floated (nothing is filled yet at that point).
function Test-OcrRowsFocused {
    param(
        [Parameter(Mandatory = $true)]$Rows,
        [Parameter(Mandatory = $true)]$Baseline,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][System.Collections.IDictionary]$FieldDefs,
        [int]$FieldIndex = 0,
        [double]$ShrinkRatio = 0.92
    )
    if ($null -eq $Rows -or -not $Rows.Contains($Key) -or -not $Baseline.Contains($Key)) { return $false }
    $parts = @([string]$FieldDefs[$Key].label -split '\s+')
    $targetH = Get-OcrRowPartMaxH -Row $Rows[$Key] -Parts $parts
    $baseH = Get-OcrRowPartMaxH -Row $Baseline[$Key] -Parts $parts
    if ($baseH -le 0) { $baseH = 1 }
    if ($targetH -le [int]($baseH * $ShrinkRatio)) { return $true }
    if ($FieldIndex -eq 0) {
        foreach ($k2 in @($FieldDefs.Keys)) {
            if ($k2 -eq $Key) { continue }
            if (-not $Rows.Contains($k2) -or -not $Baseline.Contains($k2)) { continue }
            $p2 = @([string]$FieldDefs[$k2].label -split '\s+')
            $t2 = Get-OcrRowPartMaxH -Row $Rows[$k2] -Parts $p2
            $b2 = Get-OcrRowPartMaxH -Row $Baseline[$k2] -Parts $p2
            if ($b2 -le 0) { $b2 = 1 }
            if ($t2 -le [int]($b2 * $ShrinkRatio)) { return $false }
        }
        return $true
    }
    return $false
}

# The OCR probe used to verify a typed value: the trailing up-to-3 non-space
# characters. Leading characters of a typed value are frequently mangled by the
# OCR engine, the trailing ones are not. Matching is case-sensitive (Ordinal):
# the display-name probe "13P" must not collide with the username probe "13p".
function Get-OcrValueProbe {
    param([Parameter(Mandatory = $true)][string]$Value)
    $probe = $Value.Trim()
    if ($probe.Length -gt 3) { $probe = $probe.Substring($probe.Length - 3) }
    return $probe.Trim()
}

# Remove a transient capture file (post-secret frames must never persist).
function Remove-OcrTempFile {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (Test-Path -LiteralPath $Path) { Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue }
}

# Whether a typed value's probe sits inside the vertical band of a field, and
# nowhere else. Bands come from the resolved label rows (a field's label top
# down to the next field's label top); the probe is located across ALL visual
# rows, because a filled value commonly lands in its own row just below the
# floated label rather than inside the label row. Probe matching is Ordinal.
function Test-OcrValueInBand {
    param(
        [Parameter(Mandatory = $true)]$Rows,
        [Parameter(Mandatory = $true)]$Resolved,
        [Parameter(Mandatory = $true)][System.Collections.IDictionary]$FieldDefs,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$Probe
    )
    $keys = @($FieldDefs.Keys)
    $keyIdx = [Array]::IndexOf($keys, $Key)
    if ($keyIdx -lt 0 -or -not $Resolved.Contains($Key)) { return $false }
    $targetTop = [int]$Resolved[$Key].top
    $nextTop = if ($keyIdx + 1 -lt $keys.Count -and $Resolved.Contains($keys[$keyIdx + 1])) { [int]$Resolved[$keys[$keyIdx + 1]].top } else { $targetTop + 120 }
    $inTarget = $false
    foreach ($r in @($Rows)) {
        $hasProbe = @($r.words | Where-Object { $_.Text.IndexOf($Probe, [System.StringComparison]::Ordinal) -ge 0 }).Count -gt 0
        if (-not $hasProbe) { continue }
        if ($r.top -ge ($targetTop - 4) -and $r.top -lt $nextTop) { $inTarget = $true }
        else { return $false }
    }
    return $inTarget
}

# Post-secret assertions on an OCR word set. Returns { ok, reasons }. Every
# field marked secret must be masked (no Latin/digit text anywhere in its band);
# every non-secret field must still contain its expected value probe inside its
# own band; the secret probe must not appear anywhere; and non-secret value
# probes must not leak into other fields' bands. The secret value is never
# emitted; only the probe string participates. Matching is Ordinal so the
# display-name probe "13P" and the username probe "13p" stay distinct.
function Test-OcrSecretPostWords {
    param(
        [Parameter(Mandatory = $true)]$Words,
        [Parameter(Mandatory = $true)][System.Collections.IDictionary]$FieldDefs,
        [Parameter(Mandatory = $true)][string]$SecretProbe
    )
    $resolved = Resolve-OcrFieldRows -Words $Words -FieldDefs $FieldDefs
    if ($null -eq $resolved) { return [ordered]@{ ok = $false; reasons = @('rows-unresolvable') } }
    $allRows = @(ConvertTo-OcrRows -Words $Words)
    $reasons = @()
    $keys = @($FieldDefs.Keys)
    $secretKeys = @($keys | Where-Object {
        (Test-FieldDefHasKey $FieldDefs[$_] 'secret') -and [bool]$FieldDefs[$_].secret
    })

    # masked: no Latin/digit text anywhere in a secret field's band
    foreach ($k in $secretKeys) {
        $idx = [Array]::IndexOf($keys, $k)
        if (-not $resolved.Contains($k)) { $reasons += "row-missing-$k"; continue }
        $top = [int]$resolved[$k].top
        $nextTop = if ($idx + 1 -lt $keys.Count -and $resolved.Contains($keys[$idx + 1])) { [int]$resolved[$keys[$idx + 1]].top } else { $top + 120 }
        $latin = @($allRows | Where-Object {
            $_.top -ge ($top - 4) -and $_.top -lt $nextTop -and
            (@($_.words | Where-Object { $_.Text -match '[A-Za-z0-9]' }).Count -gt 0)
        })
        if ($latin.Count -gt 0) { $reasons += "secret-not-masked-$k($($latin.Count))" }
    }

    # every non-secret field still holds its expected value probe in its band
    foreach ($k in $keys) {
        if ($k -in $secretKeys) { continue }
        if (-not (Test-FieldDefHasKey $FieldDefs[$k] 'value')) { continue }
        $probe = Get-OcrValueProbe -Value ([string]$FieldDefs[$k].value)
        if ($probe.Length -eq 0) { continue }
        if (-not (Test-OcrValueInBand -Rows $allRows -Resolved $resolved -FieldDefs $FieldDefs -Key $k -Probe $probe)) { $reasons += "expected-value-missing-in-$k" }
    }

    # secret probe must not appear anywhere
    $leaks = @($Words | Where-Object { $_.Text.IndexOf($SecretProbe, [System.StringComparison]::Ordinal) -ge 0 })
    if ($leaks.Count -gt 0) { $reasons += "secret-probe-visible($($leaks.Count))" }

    # non-secret probes must not leak into other fields' bands
    foreach ($k in $keys) {
        if ($k -in $secretKeys) { continue }
        if (-not (Test-FieldDefHasKey $FieldDefs[$k] 'value')) { continue }
        $probe = Get-OcrValueProbe -Value ([string]$FieldDefs[$k].value)
        if ($probe.Length -eq 0) { continue }
        $idx = [Array]::IndexOf($keys, $k)
        $top = [int]$resolved[$k].top
        $nextTop = if ($idx + 1 -lt $keys.Count -and $resolved.Contains($keys[$idx + 1])) { [int]$resolved[$keys[$idx + 1]].top } else { $top + 120 }
        $outside = @($allRows | Where-Object {
            ($_.top -lt ($top - 4) -or $_.top -ge $nextTop) -and
            (@($_.words | Where-Object { $_.Text.IndexOf($probe, [System.StringComparison]::Ordinal) -ge 0 }).Count -gt 0)
        })
        if ($outside.Count -gt 0) { $reasons += "value-contamination-$k($($outside.Count))" }
    }

    return [ordered]@{ ok = ($reasons.Count -eq 0); reasons = $reasons }
}

# OCR a screenshot and return, for each field key, its resolved label row box.
# FieldLabels is an ordered IDictionary of key -> Arabic label string.
function Get-OcrFields {
    param(
        [Parameter(Mandatory = $true)][string]$PngPath,
        [Parameter(Mandatory = $true)][System.Collections.IDictionary]$FieldLabels,
        [double]$DpiScale = 1.0,
        [string]$LanguageTag = 'ar-SA'
    )
    $words = @(Invoke-OcrFile -Path $PngPath -LanguageTag $LanguageTag -DpiScale $DpiScale)
    $defs = [ordered]@{}
    foreach ($key in $FieldLabels.Keys) { $defs[$key] = [ordered]@{ label = [string]$FieldLabels[$key] } }
    $rows = Resolve-OcrFieldRows -Words $words -FieldDefs $defs
    $out = [ordered]@{}
    foreach ($key in $FieldLabels.Keys) {
        if ($rows -and $rows.Contains($key)) {
            $row = $rows[$key]
            $out[$key] = [ordered]@{
                label = [string]$FieldLabels[$key]
                matchedRow = (@($row.words | ForEach-Object { $_.Text }) -join ' ')
                x = $row.left
                y = $row.top
                w = ($row.right - $row.left)
                h = ($row.bottom - $row.top)
            }
        } else {
            $out[$key] = $null
        }
    }
    return $out
}

# Fill a set of form fields using row-based OCR targeting. For each field in
# order: capture fresh -> resolve the label row -> derive the input rect from
# that SAME capture -> click -> assert the intended field is focused (transient
# verify capture; the focused label floats and shrinks) -> type -> verify the
# value landed in the field's band (or, for a secret field, that the password
# stays masked and nothing leaked). Every click rect and every decision comes
# from a freshly captured frame; coordinates are never carried across captures.
# FieldDefs is an ordered IDictionary of key -> { label, value [, secret] }.
# Secret fields (secret=$true) are never persisted: their post-fill captures
# and any capture taken after the first secret was typed are deleted, and the
# methods map records only sanitized verdicts.
function Invoke-OcrFieldFlow {
    param(
        [Parameter(Mandatory = $true)][IntPtr]$Handle,
        [Parameter(Mandatory = $true)][System.Collections.IDictionary]$FieldDefs,
        [Parameter(Mandatory = $true)][string]$ShotDir,
        [Parameter(Mandatory = $true)][string]$Tag,
        [double]$DpiScale = 1.0,
        [string]$LanguageTag = 'ar-SA',
        [int]$Retries = 3,
        [int]$ClickXPad = 90,
        [int]$MinX = 1150,
        [double]$ShrinkRatio = 0.92
    )
    Initialize-WinNative
    $rect = Get-WindowRectOut -Handle $Handle
    $methods = [ordered]@{}
    $keys = @($FieldDefs.Keys)
    $secretTyped = $false
    for ($fi = 0; $fi -lt $keys.Count; $fi++) {
        $key = $keys[$fi]
        $def = $FieldDefs[$key]
        $label = [string]$def.label
        $value = [string]$def.value
        $isSecret = ((Test-FieldDefHasKey $def 'secret') -and [bool]$def.secret)
        $parts = @($label -split '\s+')

        # Fresh capture -> resolve the intended label row (Resolve returns $null
        # on any ambiguity or non-top-down layout, so we fail closed).
        $baselinePng = Join-Path $ShotDir "$Tag-field-$key-b.png"
        $baselineTransient = $secretTyped
        $null = Capture-AppWindowPng -Handle $Handle -File $baselinePng
        $baselineWords = @(Invoke-OcrFile -Path $baselinePng -LanguageTag $LanguageTag -DpiScale $DpiScale)
        $baseline = Resolve-OcrFieldRows -Words $baselineWords -FieldDefs $FieldDefs
        if ($null -eq $baseline -or -not $baseline.Contains($key)) {
            Remove-OcrTempFile -Path $baselinePng
            throw "field label not resolved in OCR: $label"
        }
        $pt = Get-OcrRowInputRect -Row $baseline[$key] -ClickXPad $ClickXPad -MinX $MinX
        if ($baselineTransient) { Remove-OcrTempFile -Path $baselinePng }

        # Click, then assert the intended field became the focused one before
        # typing anything. At most two fresh re-derivations, then fail closed.
        $focused = $false
        $typed = $null
        for ($try = 1; $try -le $Retries -and -not $focused; $try++) {
            $sx = $rect.Left + [int]($pt.X * $DpiScale)
            $sy = $rect.Top + [int]($pt.Y * $DpiScale)
            [void](Force-ForegroundWindow -Handle $Handle)
            Start-Sleep -Milliseconds 350
            [void][M13PWinNative]::SetCursorPos($sx, $sy)
            Start-Sleep -Milliseconds 250
            [M13PWinNative]::ClickAt($sx, $sy)
            Start-Sleep -Milliseconds 450
            $verifyPng = Join-Path $ShotDir "$Tag-field-$key-f$try.png"
            $null = Capture-AppWindowPng -Handle $Handle -File $verifyPng
            $verifyWords = @(Invoke-OcrFile -Path $verifyPng -LanguageTag $LanguageTag -DpiScale $DpiScale)
            $rows = Resolve-OcrFieldRows -Words $verifyWords -FieldDefs $FieldDefs
            if ($null -ne $rows -and
                (Test-OcrRowsFocused -Rows $rows -Baseline $baseline -Key $key -FieldDefs $FieldDefs -FieldIndex $fi -ShrinkRatio $ShrinkRatio)) {
                $focused = $true
                $typed = "RowTarget+FocusVerify try=$try x=$sx y=$sy"
            }
            if ($secretTyped) { Remove-OcrTempFile -Path $verifyPng }
            if (-not $focused -and $try -lt $Retries) {
                # Re-derive the input rect from a fresh baseline capture.
                $null = Capture-AppWindowPng -Handle $Handle -File $baselinePng
                $baselineWords = @(Invoke-OcrFile -Path $baselinePng -LanguageTag $LanguageTag -DpiScale $DpiScale)
                $baseline = Resolve-OcrFieldRows -Words $baselineWords -FieldDefs $FieldDefs
                if ($null -eq $baseline -or -not $baseline.Contains($key)) {
                    Remove-OcrTempFile -Path $baselinePng
                    throw "field label not resolved in OCR on re-derivation: $label"
                }
                $pt = Get-OcrRowInputRect -Row $baseline[$key] -ClickXPad $ClickXPad -MinX $MinX
                if ($baselineTransient) { Remove-OcrTempFile -Path $baselinePng }
                Start-Sleep -Milliseconds 700
            }
        }
        if (-not $focused) {
            Remove-OcrTempFile -Path $baselinePng
            throw "field not focused after click (label float not observed): $label"
        }

        # Type the value into the now-verified focused field.
        [void](Force-ForegroundWindow -Handle $Handle)
        Start-Sleep -Milliseconds 250
        [System.Windows.Forms.SendKeys]::SendWait('^a')
        Start-Sleep -Milliseconds 120
        [System.Windows.Forms.SendKeys]::SendWait('{BACKSPACE}')
        Start-Sleep -Milliseconds 120
        [System.Windows.Forms.SendKeys]::SendWait('{DELETE}')
        Start-Sleep -Milliseconds 150
        [M13PWinNative]::TypeText($value)

        if (-not $isSecret) {
            # Verify the value actually landed in this field's band (self-heals
            # lost types by clearing and re-typing once).
            $probe = Get-OcrValueProbe -Value $value
            $bandOk = $false
            $postPng = Join-Path $ShotDir "$Tag-field-$key-post.png"
            for ($v = 1; $v -le 2 -and -not $bandOk; $v++) {
                Start-Sleep -Milliseconds 600
                $null = Capture-AppWindowPng -Handle $Handle -File $postPng
                $postWords = @(Invoke-OcrFile -Path $postPng -LanguageTag $LanguageTag -DpiScale $DpiScale)
                $postResolved = Resolve-OcrFieldRows -Words $postWords -FieldDefs $FieldDefs
                if ($null -ne $postResolved -and $probe.Length -gt 0) {
                    $bandOk = Test-OcrValueInBand -Rows @(ConvertTo-OcrRows -Words $postWords) -Resolved $postResolved -FieldDefs $FieldDefs -Key $key -Probe $probe
                }
                if (-not $bandOk -and $v -lt 2) {
                    [void](Force-ForegroundWindow -Handle $Handle)
                    Start-Sleep -Milliseconds 250
                    [System.Windows.Forms.SendKeys]::SendWait('^a')
                    Start-Sleep -Milliseconds 120
                    [System.Windows.Forms.SendKeys]::SendWait('{BACKSPACE}')
                    Start-Sleep -Milliseconds 120
                    [System.Windows.Forms.SendKeys]::SendWait('{DELETE}')
                    Start-Sleep -Milliseconds 150
                    [M13PWinNative]::TypeText($value)
                }
            }
            if ($secretTyped) { Remove-OcrTempFile -Path $postPng }
            if (-not $bandOk) {
                throw "field value not verified in band: $label"
            }
            $methods[$label] = "$typed band-verified probe=$probe"
        } else {
            # Secret field: the post-fill frame is transient and must never be
            # persisted (a masking bug could put the plaintext in it). Verify
            # masked state and cross-field contamination, then delete it.
            Start-Sleep -Milliseconds 600
            $secretPng = Join-Path $ShotDir "$Tag-field-$key-secret.png"
            $null = Capture-AppWindowPng -Handle $Handle -File $secretPng
            $secretWords = @(Invoke-OcrFile -Path $secretPng -LanguageTag $LanguageTag -DpiScale $DpiScale)
            $check = Test-OcrSecretPostWords -Words $secretWords -FieldDefs $FieldDefs -SecretProbe (Get-OcrValueProbe -Value $value)
            Remove-OcrTempFile -Path $secretPng
            $secretTyped = $true
            if (-not $check.ok) {
                throw "post-secret verification failed ($label): $($check.reasons -join '; ')"
            }
            $methods[$label] = "$typed masked-verified"
        }
    }
    return $methods
}

# Click the bottom-most OCR word matching any of the button parts.
# Returns { clicked, try, screenX, screenY, word }. With -Transient the capture
# frames are deleted after use (required after a password has been typed, so a
# masking bug can never leave a plaintext frame in evidence).
function Click-OcrButtonByParts {
    param(
        [Parameter(Mandatory = $true)][IntPtr]$Handle,
        [Parameter(Mandatory = $true)][string[]]$Parts,
        [Parameter(Mandatory = $true)][string]$ShotDir,
        [Parameter(Mandatory = $true)][string]$Tag,
        [double]$DpiScale = 1.0,
        [string]$LanguageTag = 'ar-SA',
        [int]$Retries = 4,
        [switch]$Transient
    )
    Initialize-WinNative
    $rect = Get-WindowRectOut -Handle $Handle
    for ($try = 1; $try -le $Retries; $try++) {
        $png = Join-Path $ShotDir ("$Tag-button-t$try.png")
        $capNote = Capture-AppWindowPng -Handle $Handle -File $png
        $words = @(Invoke-OcrFile -Path $png -LanguageTag $LanguageTag -DpiScale $DpiScale)
        $btn = $null
        foreach ($p in $Parts) {
            $hits = @($words | Where-Object { $_.Text -eq $p } | Sort-Object Y -Descending)
            if ($hits.Count -gt 0) { $btn = $hits[0]; break }
        }
        if ($btn) {
            $sx = $rect.Left + [int]($btn.X + $btn.W / 2)
            $sy = $rect.Top + [int]($btn.Y + $btn.H / 2)
            [void](Force-ForegroundWindow -Handle $Handle)
            Start-Sleep -Milliseconds 350
            [M13PWinNative]::ClickAt($sx, $sy)
            Start-Sleep -Milliseconds 600
            if ($Transient) { Remove-OcrTempFile -Path $png }
            return [ordered]@{ clicked = $true; try = $try; screenX = $sx; screenY = $sy; word = $btn.Text }
        }
        if ($Transient) { Remove-OcrTempFile -Path $png }
        Start-Sleep -Milliseconds 700
    }
    return [ordered]@{ clicked = $false; try = $Retries }
}

function Get-UtcString {
    param([System.DateTime]$Time = (Get-Date))
    return $Time.ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'")
}

function Write-JsonUtf8 {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object
    )
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $json = $Object | ConvertTo-Json -Depth 30
    [System.IO.File]::WriteAllText($Path, $json, (New-Object System.Text.UTF8Encoding $false))
}

function Read-JsonUtf8 {
    param([Parameter(Mandatory = $true)][string]$Path)
    return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}

# Safe per-key registry property read: never assumes a property exists.
function Get-RegValueSafe {
    param([string]$Path, [string]$Property)
    try {
        $item = Get-ItemProperty -LiteralPath $Path -ErrorAction Stop
        $props = @($item.PSObject.Properties.Name)
        if ($props -contains $Property) { return [string]$item.$Property }
        return $null
    } catch {
        return $null
    }
}

# Enumerate HKCU uninstall registration keys matching the muaman AppId suffix or
# DisplayName/publisher. Returns the list of PSChildName keys (duplicates counted).
function Get-HkcuUninstallMuamanKeys {
    param([string]$Root, [string]$DisplayName, [string]$Publisher, [string]$KeySuffix)
    $hits = @()
    try {
        Get-ChildItem -LiteralPath $Root -ErrorAction Stop | ForEach-Object {
            $child = $_.PSChildName
            $display = Get-RegValueSafe -Path $_.PSPath -Property 'DisplayName'
            $pub = Get-RegValueSafe -Path $_.PSPath -Property 'Publisher'
            $match = $false
            if ($KeySuffix -and $child.EndsWith($KeySuffix, [System.StringComparison]::OrdinalIgnoreCase)) { $match = $true }
            if ($display -and $display -eq $DisplayName) { $match = $true }
            if ($pub -and $pub -eq $Publisher) { $match = $true }
            if ($match) { $hits += $child }
        }
    } catch {
        return ,@()
    }
    return ,$hits
}

# Full property snapshot of a registry key (no secrets expected here).
function Get-RegKeySnapshot {
    param([string]$Path)
    $props = $null
    try {
        $item = Get-ItemProperty -LiteralPath $Path -ErrorAction Stop
        $props = [ordered]@{}
        $item.PSObject.Properties | ForEach-Object {
            if ($_.Name -notlike 'PS*') { $props[$_.Name] = [string]$_.Value }
        }
    } catch {
        return $null
    }
    return $props
}

function Get-FileSha256 {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [int]$Retries = 4,
        [int]$DelayMs = 250
    )
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    for ($attempt = 0; $attempt -le $Retries; $attempt++) {
        try {
            $h = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
            return $h
        } catch {
            if ($attempt -ge $Retries) { throw }
            Start-Sleep -Milliseconds $DelayMs
        }
    }
    return $null
}

function Get-Sha256HexLower {
    param([byte[]]$Bytes)
    $sb = New-Object System.Text.StringBuilder
    foreach ($b in $Bytes) { [void]$sb.Append($b.ToString('X2')) }
    return $sb.ToString()
}

# Read a file that another process may hold open (e.g. the app's SQLite DB),
# sharing read/write so the owner can keep working. Returns bytes.
function Read-FileShared {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [int]$Retries = 10,
        [int]$DelayMs = 300
    )
    for ($attempt = 0; $attempt -le $Retries; $attempt++) {
        try {
            $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
            try {
                $bytes = New-Object byte[] $fs.Length
                $read = 0
                while ($read -lt $bytes.Length) {
                    $n = $fs.Read($bytes, $read, $bytes.Length - $read)
                    if ($n -le 0) { break }
                    $read += $n
                }
                return $bytes
            } finally {
                $fs.Dispose()
            }
        } catch {
            if ($attempt -ge $Retries) { throw }
            Start-Sleep -Milliseconds $DelayMs
        }
    }
    return $null
}

# Recursive listing of a directory: relative path, size, lastWriteTimeUtc, sha256.
function Get-DirListing {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [switch]$IncludeSha
    )
    $result = @()
    if (-not (Test-Path -LiteralPath $Root)) { return ,$result }
    $fullRoot = [System.IO.Path]::GetFullPath($Root)
    Get-ChildItem -LiteralPath $Root -Recurse -Force -File | ForEach-Object {
        $rel = $_.FullName.Substring($fullRoot.Length).TrimStart('\', '/')
        $item = [ordered]@{
            rel = $rel
            size = $_.Length
            lastWriteTimeUtc = $_.LastWriteTimeUtc.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        }
        if ($IncludeSha) {
            # System-hive files (e.g. Microsoft\Windows\UsrClass.dat) are held
            # open by the OS for the whole session; hash them when readable and
            # record locked=true otherwise so listing never aborts on them.
            # No retries here: a still-locked file is recorded as locked.
            try { $item['sha256'] = (Get-FileSha256 -Path $_.FullName -Retries 0) }
            catch { $item['sha256'] = $null; $item['locked'] = $true }
        }
        $result += $item
    }
    return ,$result
}

function Diff-DirListings {
    param(
        [Parameter(Mandatory = $true)]$Before,
        [Parameter(Mandatory = $true)]$After
    )
    $beforeMap = @{}
    foreach ($it in $Before) { $beforeMap[$it.rel] = $it }
    $afterMap = @{}
    foreach ($it in $After) { $afterMap[$it.rel] = $it }

    $added = @()
    $removed = @()
    $changed = @()
    $unchanged = @()

    foreach ($rel in $afterMap.Keys) {
        if (-not $beforeMap.ContainsKey($rel)) { $added += $rel; continue }
        $b = $beforeMap[$rel]; $a = $afterMap[$rel]
        if ($b.size -ne $a.size) { $changed += $rel; continue }
        $bSha = if ($b.PSObject.Properties['sha256']) { $b.sha256 } else { $null }
        $aSha = if ($a.PSObject.Properties['sha256']) { $a.sha256 } else { $null }
        if ($bSha -and $aSha -and $bSha -ne $aSha) { $changed += $rel; continue }
        $unchanged += $rel
    }
    foreach ($rel in $beforeMap.Keys) {
        if (-not $afterMap.ContainsKey($rel)) { $removed += $rel }
    }
    return [ordered]@{
        added = ($added | Sort-Object)
        removed = ($removed | Sort-Object)
        changed = ($changed | Sort-Object)
        unchangedCount = $unchanged.Count
    }
}

# Start a child process in the SAME session/user (used by the worker),
# with optional environment overrides and optional stdout redirect.
# Returns object: exitCode, timedOut, processId, process.
function Start-ChildProcess {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string]$Arguments,
        [string]$WorkingDir,
        [hashtable]$Environment = @{},
        [string]$StdoutFile,
        [string]$StderrFile,
        [int]$TimeoutMs = 120000
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath
    if ($Arguments) { $psi.Arguments = $Arguments }
    $psi.UseShellExecute = $false
    if ($WorkingDir) {
        if (-not (Test-Path -LiteralPath $WorkingDir -PathType Container)) {
            New-Item -ItemType Directory -Path $WorkingDir -Force | Out-Null
        }
        $psi.WorkingDirectory = $WorkingDir
    }
    foreach ($k in $Environment.Keys) {
        $psi.EnvironmentVariables[$k] = [string]$Environment[$k]
    }
    if ($StdoutFile) {
        $psi.RedirectStandardOutput = $true
        $psi.StandardOutputEncoding = New-Object System.Text.UTF8Encoding $false
    }
    if ($StderrFile) {
        $psi.RedirectStandardError = $true
        $psi.StandardErrorEncoding = New-Object System.Text.UTF8Encoding $false
    }

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    $outBuilder = New-Object System.Text.StringBuilder
    $errBuilder = New-Object System.Text.StringBuilder

    if ($StdoutFile) {
        $proc.add_OutputDataReceived([System.Diagnostics.DataReceivedEventHandler]{
            param($s, $e)
            if ($e.Data -ne $null) {
                [void]$outBuilder.AppendLine($e.Data)
                if ($outBuilder.Length -ge 100000) { $outBuilder.Clear() }
            }
        })
    }
    if ($StderrFile) {
        $proc.add_ErrorDataReceived([System.Diagnostics.DataReceivedEventHandler]{
            param($s, $e)
            if ($e.Data -ne $null) { [void]$errBuilder.AppendLine($e.Data) }
        })
    }

    [void]$proc.Start()
    if ($StdoutFile) { $proc.BeginOutputReadLine() }
    if ($StderrFile) { $proc.BeginErrorReadLine() }

    $timedOut = -not $proc.WaitForExit($TimeoutMs)
    if (-not $timedOut) {
        if ($StdoutFile) { $proc.WaitForExit() }
        if ($StdoutFile) { [System.IO.File]::WriteAllText($StdoutFile, $outBuilder.ToString(), (New-Object System.Text.UTF8Encoding $false)) }
        if ($StderrFile) { [System.IO.File]::WriteAllText($StderrFile, $errBuilder.ToString(), (New-Object System.Text.UTF8Encoding $false)) }
        return [ordered]@{ exitCode = $proc.ExitCode; timedOut = $false; processId = $proc.Id; process = $proc }
    }
    # Timeout: try to terminate.
    try { $proc.Kill() } catch {}
    $proc.Dispose()
    return [ordered]@{ exitCode = $null; timedOut = $true; processId = $proc.Id; process = $null }
}

# Start a long-running (GUI) child process in the SAME session/user and return
# immediately with the live Process object. Optional environment overrides.
function Start-AppProcess {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string]$Arguments,
        [string]$WorkingDir,
        [hashtable]$Environment = @{}
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath
    if ($Arguments) { $psi.Arguments = $Arguments }
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    if ($WorkingDir) { $psi.WorkingDirectory = $WorkingDir }
    foreach ($k in $Environment.Keys) {
        $psi.EnvironmentVariables[$k] = [string]$Environment[$k]
    }
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    [void]$proc.Start()
    $null = $proc.StandardOutput.ReadToEndAsync()
    $null = $proc.StandardError.ReadToEndAsync()
    return $proc
}

# Start a process as a different (standard) user using CreateProcessWithLogonW.
# Used by the orchestrator to launch the worker as the fresh account.
function Start-ProcessAsUser {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string]$Arguments,
        [string]$WorkingDir,
        [Parameter(Mandatory = $true)][string]$Domain,
        [Parameter(Mandatory = $true)][string]$UserName,
        [Parameter(Mandatory = $true)][System.Security.SecureString]$Password,
        [int]$TimeoutMs = 1800000
    )
    Initialize-WinNative
    Add-Type -AssemblyName System.Security -ErrorAction Stop

    # ProcessStartInfo with credentials does not load the target profile by
    # default (child would inherit the caller's TEMP and have no HKCU hive).
    # LoadUserProfile makes .NET use LOGON_WITH_PROFILE semantics: the profile is
    # created/loaded, HKCU resolves, and TEMP/USERPROFILE/LOCALAPPDATA all point at
    # the target user's fresh profile. Process-local env overrides are not applied
    # in this mode, so callers must convey script-specific variables by other means
    # (e.g. a run-scoped secrets file read by the launched script).
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath
    if ($Arguments) { $psi.Arguments = $Arguments }
    if ($WorkingDir) { $psi.WorkingDirectory = $WorkingDir }
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.LoadUserProfile = $true
    $psi.UserName = $UserName
    $psi.Domain = $Domain
    $psi.Password = $Password

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    try {
        [void]$proc.Start()
    } catch {
        throw "process start failed: $($_.Exception.Message)"
    }

    $timedOut = $false
    if (-not $proc.WaitForExit($TimeoutMs)) {
        $timedOut = $true
        try { $proc.Kill() } catch {}
    }
    $exitCode = $null
    if (-not $timedOut) { $exitCode = $proc.ExitCode }
    return [ordered]@{ exitCode = $exitCode; timedOut = $timedOut; processId = $proc.Id }
}

function Protect-CurrentUserText {
    param([Parameter(Mandatory = $true)][string]$Text, [Parameter(Mandatory = $true)][string]$OutFile)
    Add-Type -AssemblyName System.Security -ErrorAction Stop
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $protected = [System.Security.Cryptography.ProtectedData]::Protect(
        $bytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
    [System.IO.File]::WriteAllBytes($OutFile, $protected)
}

function Unprotect-CurrentUserText {
    param([Parameter(Mandatory = $true)][string]$InFile)
    Add-Type -AssemblyName System.Security -ErrorAction Stop
    $protected = [System.IO.File]::ReadAllBytes($InFile)
    $bytes = [System.Security.Cryptography.ProtectedData]::Unprotect(
        $protected, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
    return [System.Text.Encoding]::UTF8.GetString($bytes)
}

# ---------------- UI helpers ----------------

function Get-MainWindowHandle {
    param([Parameter(Mandatory = $true)][System.Diagnostics.Process]$Process, [int]$TimeoutSec = 120)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
        try {
            $Process.Refresh()
            $h = $Process.MainWindowHandle
            if ($h -ne [IntPtr]::Zero) { return $h }
        } catch {}
        Start-Sleep -Milliseconds 500
    }
    return [IntPtr]::Zero
}

function Get-WindowFacts {
    param([IntPtr]$Handle)
    Initialize-WinNative
    return [ordered]@{
        handle = ('0x{0:X}' -f $Handle.ToInt64())
        title = [M13PWinNative]::WindowTitle($Handle)
        className = [M13PWinNative]::WindowClass($Handle)
    }
}

function Capture-WindowPng {
    param(
        [Parameter(Mandatory = $true)][IntPtr]$Handle,
        [Parameter(Mandatory = $true)][string]$File
    )
    Initialize-WinNative
    Initialize-WinForms
    $dir = Split-Path -Parent $File
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    return [M13PWinNative]::CaptureWindow($Handle, $File)
}

function Capture-DesktopPng {
    param([Parameter(Mandatory = $true)][string]$File)
    Initialize-WinNative
    Initialize-WinForms
    $dir = Split-Path -Parent $File
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    return [M13PWinNative]::CaptureDesktop($File)
}

# Capture a window's OWN surface (foreground + PrintWindow w/ render-full-content),
# falling back to CopyFromScreen if the own-surface capture is blank.
function Capture-AppWindowPng {
    param(
        [Parameter(Mandatory = $true)][IntPtr]$Handle,
        [Parameter(Mandatory = $true)][string]$File
    )
    Initialize-WinNative
    $dir = Split-Path -Parent $File
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [void](Force-ForegroundWindow -Handle $Handle)
    Start-Sleep -Milliseconds 700
    $r = [M13PWinNative]::CaptureWindowOwn($Handle, $File)
    if ($r -ne 'ok') { return "own-capture failed: $r" }
    $sd = [M13PWinNative]::ImageStdDev($File)
    if ($sd -lt 3.0) {
        $r2 = [M13PWinNative]::CaptureWindow($Handle, $File)
        if ($r2 -ne 'ok') { return "screen-capture fallback failed: $r2" }
        return "fallback-screen (own-capture blank, sd=$([math]::Round($sd,2)))"
    }
    return "own-capture sd=$([math]::Round($sd,2))"
}

function Force-ForegroundWindow {
    param([IntPtr]$Handle)
    Initialize-WinNative
    return [M13PWinNative]::ForceForeground($Handle)
}

function Close-WindowGracefully {
    param([IntPtr]$Handle, [System.Diagnostics.Process]$Process, [int]$TimeoutSec = 30)
    Initialize-WinNative
    [void][M13PWinNative]::PostMessage($Handle, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) # WM_CLOSE
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
        try {
            $Process.Refresh()
            if ($Process.HasExited) { return [ordered]@{ method = 'WM_CLOSE'; exited = $true; exitCode = $Process.ExitCode; seconds = [math]::Round($sw.Elapsed.TotalSeconds, 1) } }
        } catch {
            return [ordered]@{ method = 'WM_CLOSE'; exited = $true; exitCode = $null; seconds = [math]::Round($sw.Elapsed.TotalSeconds, 1) }
        }
        Start-Sleep -Milliseconds 300
    }
    try {
        $closed = $Process.CloseMainWindow()
        if ($closed) {
            $done = $Process.WaitForExit((($TimeoutSec - $sw.Elapsed.TotalSeconds) * 1000))
            if ($done) { return [ordered]@{ method = 'CloseMainWindow'; exited = $true; exitCode = $Process.ExitCode; seconds = [math]::Round($sw.Elapsed.TotalSeconds, 1) } }
        }
    } catch {}
    try { $Process.Kill() } catch {}
    return [ordered]@{ method = 'Kill'; exited = $true; exitCode = $Process.ExitCode; seconds = [math]::Round($sw.Elapsed.TotalSeconds, 1) }
}

# ---------------- UIA helpers ----------------

function Get-UiaRootFromHandle {
    param([IntPtr]$Handle)
    Initialize-Uia
    return [System.Windows.Automation.AutomationElement]::FromHandle($Handle)
}

function Find-UiaDescendant {
    param(
        $Root,
        [string]$Name,
        $ControlType,
        [switch]$StartsWith,
        [switch]$Contains
    )
    Initialize-Uia
    $conds = @()
    if ($Name) {
        if ($StartsWith) {
            $conds += New-Object System.Windows.Automation.PropertyCondition(
                [System.Windows.Automation.AutomationElement]::NameProperty, $Name,
                [System.Windows.Automation.PropertyConditionFlags]::Startswith)
        } elseif ($Contains) {
            $conds += New-Object System.Windows.Automation.PropertyCondition(
                [System.Windows.Automation.AutomationElement]::NameProperty, $Name,
                [System.Windows.Automation.PropertyConditionFlags]::MatchSubstring)
        } else {
            $conds += New-Object System.Windows.Automation.PropertyCondition(
                [System.Windows.Automation.AutomationElement]::NameProperty, $Name)
        }
    }
    if ($ControlType) {
        $conds += New-Object System.Windows.Automation.PropertyCondition(
            [System.Windows.Automation.AutomationElement]::ControlTypeProperty, $ControlType)
    }
    $condition = $null
    if ($conds.Count -eq 0) {
        $condition = [System.Windows.Automation.Condition]::TrueCondition
    } elseif ($conds.Count -eq 1) {
        $condition = $conds[0]
    } else {
        $condition = New-Object System.Windows.Automation.AndCondition([System.Windows.Automation.Condition[]]$conds)
    }
    return $Root.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $condition)
}

function Wait-UiaElement {
    param(
        $Root,
        [string]$Name,
        $ControlType,
        [int]$TimeoutSec = 30,
        [int]$IntervalMs = 500,
        [switch]$StartsWith
    )
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
        try {
            $el = Find-UiaDescendant -Root $Root -Name $Name -ControlType $ControlType -StartsWith:$StartsWith
            if ($el -and $el.Current.IsEnabled) { return $el }
        } catch {}
        Start-Sleep -Milliseconds $IntervalMs
    }
    return $null
}

function Get-UiaDumpText {
    param($Root, [int]$MaxDepth = 40)
    Initialize-Uia
    $sb = New-Object System.Text.StringBuilder
    $walker = [System.Windows.Automation.TreeWalker]::ControlViewWalker

    function Walk($el, $depth) {
        if ($depth -gt $MaxDepth) { return }
        try {
            $ct = $el.Current.ControlType.ProgrammaticName
            $name = $el.Current.Name
            $aid = $el.Current.AutomationId
            $enabled = $el.Current.IsEnabled
            $offscreen = $el.Current.IsOffscreen
            $rect = $el.Current.BoundingRectangle
            $line = ('  ' * $depth) + $ct + ' | Name="' + $name + '" | AutomationId="' + $aid + '" | enabled=' + $enabled + ' | offscreen=' + $offscreen + ' | x=' + [int]$rect.X + ' y=' + [int]$rect.Y + ' w=' + [int]$rect.Width + ' h=' + [int]$rect.Height
            [void]$sb.AppendLine($line)
            $child = $walker.GetFirstChild($el)
            while ($child -ne $null) {
                Walk $child ($depth + 1)
                $child = $walker.GetNextSibling($child)
            }
        } catch {}
    }
    Walk $Root 0
    return $sb.ToString()
}

function Set-UiaValue {
    param($Element, [string]$Value)
    Initialize-Uia
    $vp = $Element.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern)
    $vp.SetValue($Value)
}

function Set-UiaValueBySendKeys {
    param($Element, [string]$Value)
    Initialize-Uia
    Initialize-WinForms
    $Element.SetFocus()
    Start-Sleep -Milliseconds 400
    Send-KeysLiteral -Text $Value
}

function Invoke-UiaElement {
    param($Element)
    Initialize-Uia
    $ip = $Element.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
    $ip.Invoke()
}

function Send-KeysLiteral {
    param([string]$Text)
    Initialize-WinForms
    $escaped = $Text -replace '([\+\^\%\~\(\)\[\]\{\}])', '{$1}'
    [System.Windows.Forms.SendKeys]::SendWait($escaped)
}

function Send-RawKeys {
    param([string]$Text)
    Initialize-WinForms
    [System.Windows.Forms.SendKeys]::SendWait($Text)
}

function Set-ClipboardText {
    param([string]$Text)
    Initialize-WinForms
    [System.Windows.Forms.Clipboard]::SetText($Text)
}

function Get-ClipboardText {
    Initialize-WinForms
    return [System.Windows.Forms.Clipboard]::GetText()
}

function Get-UiaTreeStats {
    param($DumpText)
    $controlCount = ([regex]::Matches($DumpText, "ControlType\.")).Count
    $editCount = ([regex]::Matches($DumpText, "ControlType\.Edit\b")).Count
    $buttonCount = ([regex]::Matches($DumpText, "ControlType\.Button\b")).Count
    $textCount = ([regex]::Matches($DumpText, "ControlType\.Text\b")).Count
    return [ordered]@{ controlCount = $controlCount; editCount = $editCount; buttonCount = $buttonCount; textCount = $textCount }
}

# ---------------- identity helpers ----------------

function Get-WhoamiGroups {
    $out = & whoami /groups 2>$null | Out-String
    return $out
}

function Get-WhoamiPriv {
    $out = & whoami /priv 2>$null | Out-String
    return $out
}

function Get-IntegrityLevel {
    $groups = Get-WhoamiGroups
    $m = [regex]::Match($groups, 'Mandatory Label\\(.*?)\s+Label\s+S-1-16-(\d+)')
    if ($m.Success) {
        return [ordered]@{ level = $m.Groups[1].Value.Trim(); sid = 'S-1-16-' + $m.Groups[2].Value }
    }
    return [ordered]@{ level = 'unknown'; sid = '' }
}

function Get-PrivateTokenFacts {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($id)
    $isAdmin = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    return [ordered]@{
        name = $id.Name
        sid = $id.User.Value
        authenticationType = $id.AuthenticationType
        isAdministratorRole = $isAdmin
        isInteractive = [System.Environment]::UserInteractive
    }
}

function Get-SessionInfo {
    $p = Get-Process -Id $PID
    return [ordered]@{
        sessionId = $p.SessionId
        processId = $PID
        processName = $p.ProcessName
    }
}

function Get-AccountGroupMembership {
    param([Parameter(Mandatory = $true)][string]$AccountName)
    $groups = @()
    try {
        $u = Get-LocalUser -Name $AccountName -ErrorAction Stop
        $groups = @(Get-LocalGroup | ForEach-Object {
            $g = $_
            $memberNames = @()
            try { $memberNames = @(Get-LocalGroupMember -Group $g.Name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name) } catch {}
            if ($memberNames -contains $u.Name -or $memberNames -contains $u.SID.Value) {
                return $g.Name
            }
        } | Where-Object { $_ })
    } catch {}
    return ,($groups | Sort-Object)
}

function Test-ElevationViaToken {
    # Reports whether the current process token is elevated (filtered-admin token check).
    $t = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    try {
        $admin = New-Object System.Security.Principal.WindowsPrincipal($t)
        return [ordered]@{ isInAdministrators = $admin.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator); note = 'IsInRole(Administrator) false for a plain standard user' }
    } catch {
        return [ordered]@{ isInAdministrators = $null; note = $_.Exception.Message }
    }
}

function Get-RestrictedPath {
    $windir = $env:SystemRoot
    $system32 = Join-Path $windir 'System32'
    return "$system32;$windir"
}

function Assert-NoAdminPrivileges {
    param($WhoamiPriv)
    $forbidden = @('SeDebugPrivilege', 'SeTcbPrivilege', 'SeAssignPrimaryTokenPrivilege', 'SeIncreaseQuotaPrivilege', 'SeTakeOwnershipPrivilege', 'SeLoadDriverPrivilege', 'SeSystemProfilePrivilege', 'SeBackupPrivilege', 'SeRestorePrivilege')
    $found = @()
    foreach ($p in $forbidden) {
        if ($WhoamiPriv -match $p) { $found += $p }
    }
    return ,$found
}

function Expand-EnvironmentString {
    param([string]$Text)
    $expanded = [System.Environment]::ExpandEnvironmentVariables($Text)
    return $expanded
}

# Build a process environment hashtable: current env + restricted PATH + overrides.
function New-RestrictedEnvironment {
    param([string]$RestrictedPath)
    $envMap = @{}
    Get-ChildItem Env: | ForEach-Object { $envMap[$_.Name] = [string]$_.Value }
    $envMap['PATH'] = $RestrictedPath
    return $envMap
}

# Returns true if the repo is at the expected HEAD, clean of tracked modifications,
# and has only untracked paths under the allowed prefixes.
function Test-GitCleanScope {
    param(
        [Parameter(Mandatory = $true)][string]$RepoPath,
        [Parameter(Mandatory = $true)][string]$ExpectedHead,
        [string[]]$AllowedPrefixes,
        [ref]$Violations = $null
    )
    $head = (& git -C $RepoPath rev-parse HEAD 2>$null | Select-Object -First 1)
    $lines = @(& git -C $RepoPath status --porcelain -uall 2>$null)
    $issueList = @()
    if ($head -ne $ExpectedHead) { $issueList += "HEAD=$head expected=$ExpectedHead" }
    foreach ($line in $lines) {
        $path = $line.Substring(3).Trim('"')
        if ($line -match '^\?\?') {
            $ok = $false
            foreach ($p in $AllowedPrefixes) {
                if ($path.StartsWith($p, [System.StringComparison]::Ordinal)) { $ok = $true; break }
            }
            if (-not $ok) { $issueList += $line }
        } else {
            $issueList += $line
        }
    }
    if ($Violations -ne $null) { $Violations.Value = $issueList }
    return ($issueList.Count -eq 0)
}
