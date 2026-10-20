param([string[]]$Modes = @('wpf'))
# Kiem thu tu dong: phim tat mo popup, focus co bi chiem khong, double-click co dan dung vao con tro khong.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type -TypeDefinition @'
using System; using System.Text; using System.Runtime.InteropServices;
public static class TT {
  [DllImport("user32.dll")] public static extern void keybd_event(byte v, byte s, uint f, UIntPtr e);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, int x, int y, uint d, UIntPtr e);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [StructLayout(LayoutKind.Sequential)] public struct R { public int L, T, Rt, B; }
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R r);
  public delegate bool P(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(P p, IntPtr l);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  public static IntPtr Find(string prefix) {
    IntPtr f = IntPtr.Zero;
    EnumWindows(delegate (IntPtr h, IntPtr l) { StringBuilder sb = new StringBuilder(256); GetWindowText(h, sb, 256); if (sb.Length > 0 && sb.ToString().StartsWith(prefix, StringComparison.Ordinal)) { f = h; return false; } return true; }, IntPtr.Zero);
    return f;
  }
}
'@
$dir = Join-Path $PSScriptRoot 'tools'
$title = 'Siêu Công Cụ Claude Code'
$results = @()
$setFile = Join-Path $env:LOCALAPPDATA 'PromptSpotlight\settings.json'
$setBak = "$setFile.bak"
if (Test-Path $setFile) { Move-Item $setFile $setBak -Force }

function Kill-All {
    Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*popup-host.ps1*' -or $_.Name -eq 'mshta.exe' -or $_.CommandLine -like '*PromptSpotlight*' -or $_.CommandLine -like '*tb-test.ps1*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Start-Sleep 2
}
function AltZ {
    [TT]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero); [TT]::keybd_event(0x5A, 0, 0, [UIntPtr]::Zero)
    [TT]::keybd_event(0x5A, 0, 2, [UIntPtr]::Zero); [TT]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)
}

$tbScript = Join-Path $env:TEMP 'tb-test.ps1'
@'
Add-Type -AssemblyName System.Windows.Forms
$f = New-Object Windows.Forms.Form; $f.Text = 'TBTEST'; $f.Width = 420; $f.Height = 260; $f.StartPosition = 'Manual'; $f.Location = '40,300'; $f.TopMost = $false
$t = New-Object Windows.Forms.TextBox; $t.Multiline = $true; $t.Dock = 'Fill'; $f.Controls.Add($t)
$tm = New-Object Windows.Forms.Timer; $tm.Interval = 300
$tm.Add_Tick({ Set-Content (Join-Path $env:TEMP 'tb-result.txt') $t.Text -Encoding UTF8 })
$tm.Start(); $f.Add_Shown({ $f.Activate(); $t.Focus() }); [void]$f.ShowDialog()
'@ | Set-Content $tbScript -Encoding UTF8

foreach ($mode in $Modes) {
    Write-Host "== $mode ==" -ForegroundColor Cyan
    Kill-All
    Remove-Item (Join-Path $env:TEMP 'tb-result.txt') -ErrorAction SilentlyContinue
    $logFile = Join-Path $env:TEMP 'prompt-spotlight.log'
    $before = if (Test-Path $logFile) { @(Get-Content $logFile).Count } else { 0 }
    Start-Process powershell -ArgumentList '-NoProfile', '-STA', '-WindowStyle', 'Hidden', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $dir 'popup-host.ps1')
    for ($w = 0; $w -lt 60; $w++) {
        Start-Sleep 1
        if ((Test-Path $logFile) -and (@(Get-Content $logFile).Count -gt $before) -and ((Get-Content $logFile -Tail 1) -match 'started')) { break }
    }
    Start-Sleep 1
    $tb = Start-Process powershell -ArgumentList '-NoProfile', '-STA', '-ExecutionPolicy', 'Bypass', '-File', $tbScript -PassThru
    Start-Sleep 3; $tb.Refresh()
    [TT]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero); [TT]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)
    foreach ($try in 1..5) {
        [TT]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero); [TT]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)
        [void][TT]::SetForegroundWindow($tb.MainWindowHandle); Start-Sleep -Milliseconds 500
        if ([TT]::GetForegroundWindow() -eq $tb.MainWindowHandle) { break }
    }
    $tbFg = ([TT]::GetForegroundWindow() -eq $tb.MainWindowHandle)
    $fgBefore = [TT]::GetForegroundWindow()
    AltZ; Start-Sleep 2
    $fgAfter = [TT]::GetForegroundWindow()
    $popup = [TT]::Find($title)
    $shown = ($popup -ne [IntPtr]::Zero) -and [TT]::IsWindowVisible($popup)
    $keptFocus = ($fgAfter -eq $fgBefore)

    if ($mode -eq 'wpf') {
        $r = New-Object TT+R
        [void][TT]::GetWindowRect($popup, [ref]$r)
        $x = $r.L + 200; $y = $r.T + 400
        [void][TT]::SetCursorPos($x, $y)
        foreach ($i in 1..2) { [TT]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero); [TT]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 80 }
    } else {
        $body = '{"id":"ui-freeze-detect","lang":"vi","params":{"port":"4242"}}'
        try { Invoke-WebRequest 'http://127.0.0.1:3917/api/pick' -Method POST -Body $body -UseBasicParsing | Out-Null } catch {}
    }
    Start-Sleep 3
    $txt = ''
    try { $txt = Get-Content (Join-Path $env:TEMP 'tb-result.txt') -Raw -Encoding UTF8 } catch {}
    if ($txt) { Write-Host ("  textbox: " + $txt.Substring(0, [Math]::Min(80, $txt.Length)).Replace("`r`n", " ")) }
    $pasted = $txt -match 'Tình trạng hiện tại'
    $results += [pscustomobject]@{ Mode = $mode; PopupShown = $shown; TestBoxFocused = $tbFg; KeptFocus = $keptFocus; Pasted = $pasted }
    Kill-All
}
Remove-Item $setFile -ErrorAction SilentlyContinue
if (Test-Path $setBak) { Move-Item $setBak $setFile -Force }
$results | Format-Table -AutoSize | Out-String | Write-Host
if (($results | Where-Object { -not $_.PopupShown -or -not $_.Pasted })) { exit 1 }
