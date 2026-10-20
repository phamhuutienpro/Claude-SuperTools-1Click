# Sieu Cong Cu Claude Code (WPF): popup noi, phim tat toan cuc, double-click -> dan vao con tro van ban cu.
# Khong chiem focus: cua so WS_EX_NOACTIVATE, chi lay focus khi ban bam vao o nhap.
$ErrorActionPreference = 'Stop'
$script:dir = $PSScriptRoot
$script:log = Join-Path $env:TEMP 'prompt-spotlight.log'
function Log($m) { try { Add-Content -Path $script:log -Value ("{0} {1}" -f (Get-Date -Format s), $m) } catch {} }

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml, System.Windows.Forms, System.Drawing
$refs = @(
    [System.Windows.Window].Assembly.Location, [System.Windows.UIElement].Assembly.Location, [System.Windows.DependencyObject].Assembly.Location,
    [System.Windows.Markup.XamlReader].Assembly.Location, [System.Xaml.XamlType].Assembly.Location, [System.Windows.Forms.Form].Assembly.Location
)
Add-Type -ReferencedAssemblies $refs -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Effects;
using WF = System.Windows.Forms;

public static class PSN {
  [DllImport("user32.dll")] public static extern bool RegisterHotKey(IntPtr h, int id, uint mod, uint vk);
  [DllImport("user32.dll")] public static extern bool UnregisterHotKey(IntPtr h, int id);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
  [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool f);
  [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h, int i);
  [DllImport("user32.dll")] public static extern int SetWindowLong(IntPtr h, int i, int v);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte sc, uint fl, UIntPtr ex);
  [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
  public static void ForceForeground(IntPtr h) {
    if (IsIconic(h)) ShowWindow(h, 9);
    uint pid;
    uint t1 = GetWindowThreadProcessId(GetForegroundWindow(), out pid);
    uint t2 = GetCurrentThreadId();
    AttachThreadInput(t2, t1, true);
    keybd_event(0x12, 0, 0, UIntPtr.Zero); keybd_event(0x12, 0, 2, UIntPtr.Zero);
    SetForegroundWindow(h);
    AttachThreadInput(t2, t1, false);
  }
}

public class HotkeyWnd : WF.NativeWindow {
  public event Action<int> Fired;
  public HotkeyWnd() { WF.CreateParams cp = new WF.CreateParams(); cp.Parent = new IntPtr(-3); CreateHandle(cp); }
  protected override void WndProc(ref WF.Message m) {
    if (m.Msg == 0x312 && Fired != null) Fired(m.WParam.ToInt32());
    base.WndProc(ref m);
  }
}

public class FX {
  class P { public TextBlock T; public RotateTransform R; public double X, Y, Vx, Vy, Life, Max, Rot, Vr; }
  Canvas cv; Window win; Image cur; FrameworkElement[] tilts;
  List<P> live = new List<P>(); Stack<P> pool = new Stack<P>();
  Random rnd = new Random();
  static string[] G = { "✦", "♥", "✿", "★", "✧", "❀" };
  Brush[] pinkB, blueB;
  public bool Enabled = true, Blue = false;
  int cap = 36; bool trail = true;
  DateTime lastSpawn = DateTime.MinValue, lastFrame = DateTime.MinValue;
  double avg = 16; int frames = 0;
  public event Action<string> Notice;

  static Brush B(string hex) { Brush b = (Brush)new BrushConverter().ConvertFromString(hex); b.Freeze(); return b; }
  public FX() {
    pinkB = new Brush[] { B("#FF6F9C"), B("#FF8FB6"), B("#FFB3CF"), B("#E8559A"), B("#FFD76A") };
    blueB = new Brush[] { B("#3F79C9"), B("#7FB8FF"), B("#9CC4FF"), B("#1E40AF"), B("#FFD76A") };
  }

  public void Attach(Window w, Canvas c, Image cursor, FrameworkElement[] tiltEls) {
    win = w; cv = c; cur = cursor; tilts = tiltEls;
    foreach (FrameworkElement t in tilts) { t.RenderTransformOrigin = new Point(0.5, 0.5); t.RenderTransform = new RotateTransform(0); }
    w.PreviewMouseMove += delegate (object s, MouseEventArgs e) { OnMove(e.GetPosition(cv)); };
    w.PreviewMouseLeftButtonDown += delegate (object s, MouseButtonEventArgs e) { if (Enabled) Burst(e.GetPosition(cv)); };
    w.MouseLeave += delegate (object s, MouseEventArgs e) { cur.Visibility = Visibility.Collapsed; ResetTilt(); };
    w.MouseEnter += delegate (object s, MouseEventArgs e) { if (Enabled) cur.Visibility = Visibility.Visible; };
    CompositionTarget.Rendering += Render;
    SetEnabled(true);
  }

  public void SetEnabled(bool on) {
    Enabled = on;
    if (on) win.Cursor = Cursors.None; else win.ClearValue(FrameworkElement.CursorProperty);
    if (!on) { cur.Visibility = Visibility.Collapsed; Clear(); ResetTilt(); }
  }

  void ResetTilt() { foreach (FrameworkElement t in tilts) { RotateTransform r = t.RenderTransform as RotateTransform; if (r != null) r.Angle = 0; } }

  void OnMove(Point p) {
    if (!Enabled) return;
    Canvas.SetLeft(cur, p.X); Canvas.SetTop(cur, p.Y);
    cur.Visibility = Visibility.Visible;
    DateTime now = DateTime.UtcNow;
    if (trail && (now - lastSpawn).TotalMilliseconds > 45) { lastSpawn = now; Spawn(p.X + 6, p.Y + 6, 1, false); }
    foreach (FrameworkElement t in tilts) {
      RotateTransform r = t.RenderTransform as RotateTransform;
      if (r == null || t.ActualWidth <= 0) continue;
      Point c = t.TranslatePoint(new Point(t.ActualWidth / 2, t.ActualHeight / 2), cv);
      double a = (p.X - c.X) / 18.0; if (a > 12) a = 12; if (a < -12) a = -12;
      r.Angle = a;
    }
  }

  void Burst(Point p) { Spawn(p.X, p.Y, 12, true); }

  void Spawn(double x, double y, int n, bool burst) {
    for (int i = 0; i < n; i++) {
      if (live.Count >= cap) break;
      P p;
      if (pool.Count > 0) p = pool.Pop();
      else { p = new P(); p.T = new TextBlock(); p.T.IsHitTestVisible = false; p.T.RenderTransformOrigin = new Point(0.5, 0.5); p.R = new RotateTransform(0); p.T.RenderTransform = p.R; }
      p.T.Text = G[rnd.Next(G.Length)];
      p.T.FontSize = 10 + rnd.Next(11);
      Brush[] set = Blue ? blueB : pinkB;
      p.T.Foreground = set[rnd.Next(set.Length)];
      p.X = x; p.Y = y;
      if (burst) { double a = rnd.NextDouble() * Math.PI * 2, sp = 60 + rnd.NextDouble() * 120; p.Vx = Math.Cos(a) * sp; p.Vy = Math.Sin(a) * sp; p.Max = 0.7 + rnd.NextDouble() * 0.4; }
      else { p.Vx = rnd.NextDouble() * 40 - 20; p.Vy = rnd.NextDouble() * 30 - 10; p.Max = 0.9 + rnd.NextDouble() * 0.5; }
      p.Life = p.Max; p.Rot = rnd.Next(360); p.Vr = rnd.NextDouble() * 240 - 120;
      Canvas.SetLeft(p.T, x); Canvas.SetTop(p.T, y);
      p.T.Opacity = 1;
      cv.Children.Add(p.T); live.Add(p);
    }
  }

  void Render(object s, EventArgs e) {
    DateTime now = DateTime.UtcNow;
    if (live.Count == 0) { lastFrame = now; return; }
    double dt = (now - lastFrame).TotalSeconds; lastFrame = now;
    if (dt > 0.25 || dt <= 0) dt = 0.016;
    frames++; avg = avg * 0.95 + dt * 1000.0 * 0.05;
    if (frames > 150 && avg > 45 && cap > 12) {
      cap = 12; trail = false;
      Action<string> h = Notice; if (h != null) h("Da giam hieu ung de may muot hon");
    }
    for (int i = live.Count - 1; i >= 0; i--) {
      P p = live[i];
      p.Life -= dt;
      if (p.Life <= 0) { cv.Children.Remove(p.T); live.RemoveAt(i); pool.Push(p); continue; }
      p.X += p.Vx * dt; p.Y += p.Vy * dt; p.Vy += 90 * dt; p.Rot += p.Vr * dt;
      Canvas.SetLeft(p.T, p.X); Canvas.SetTop(p.T, p.Y);
      p.T.Opacity = p.Life / p.Max; p.R.Angle = p.Rot;
    }
  }

  void Clear() { foreach (P p in live) { cv.Children.Remove(p.T); pool.Push(p); } live.Clear(); }

  public void Lift(FrameworkElement el) {
    el.MouseEnter += delegate (object s, MouseEventArgs e) {
      if (!Enabled) return;
      el.RenderTransform = new TranslateTransform(0, -2);
      DropShadowEffect fx = new DropShadowEffect();
      fx.Color = Blue ? Color.FromRgb(0x7F, 0xB8, 0xFF) : Color.FromRgb(0xFF, 0x8F, 0xB6);
      fx.BlurRadius = 16; fx.ShadowDepth = 0; fx.Opacity = 0.85;
      el.Effect = fx;
    };
    el.MouseLeave += delegate (object s, MouseEventArgs e) { el.RenderTransform = null; el.Effect = null; };
  }
}
'@

$createdNew = $false
$script:mutex = New-Object System.Threading.Mutex($true, 'Local\SieuCongCuClaudeCode', [ref]$createdNew)
if (-not $createdNew) { Log 'already running'; exit 0 }

# ---------- du lieu ----------
$libPath = Join-Path $script:dir 'prompts_library.json'
if (-not (Test-Path $libPath)) { $libPath = Join-Path $env:USERPROFILE '.claude\tools\prompts_library.json' }
$script:lib = @(Get-Content -Raw -Encoding UTF8 $libPath | ConvertFrom-Json | ForEach-Object { $_ })
$script:byId = @{}
foreach ($p in $script:lib) { $script:byId[[string]$p.id] = $p }
$script:uiItems = @($script:lib | ForEach-Object {
        [pscustomobject]@{ id = [string]$_.id; title = [string]$_.title; icon = [string]$_.icon; cat = [string]$_.category_name; tags = (@($_.tags) -join ', '); dp = $_.default_params }
    })
$script:quotes = @()
$qp = Join-Path $script:dir 'quotes.json'
if (Test-Path $qp) { $script:quotes = @(Get-Content -Raw -Encoding UTF8 $qp | ConvertFrom-Json | ForEach-Object { $_ }) }

$script:chibiMap = @{
    'ui-freeze-detect' = 'tired'; 'ui-console-exception' = 'alarm'; 'ui-screenshot-inspect' = 'camera'; 'ui-perf-check' = 'timer'
    'daemon-start-server' = 'rocket'; 'daemon-port-check' = 'plug'; 'daemon-log-watch' = 'loupe'; 'daemon-stop-port' = 'plug'
    'visual-diff-regression' = 'loupe'; 'visual-responsive' = 'camera'; 'knowledge-save-lesson' = 'book'; 'knowledge-search' = 'book'
    'coding-refactor-safe' = 'laptop'; 'coding-write-tests' = 'check'; 'coding-explain-code' = 'laptop'; 'coding-precommit-review' = 'check'
    'project-health-review' = 'check'; 'pkg-build-exe' = 'box'; 'pkg-zip-backup' = 'box'
}

function Get-PromptText($id, $lang, $params) {
    $p = $script:byId[[string]$id]
    if (-not $p) { return $null }
    $prop = switch ($lang) { 'en' { 'prompt_template_en' } 'bi' { 'prompt_template_bilingual' } default { 'prompt_template_vi' } }
    $t = [string]$p.$prop
    if (-not $t) { $t = [string]$p.prompt_template_vi }
    $map = @{}
    if ($p.default_params) { foreach ($kv in $p.default_params.PSObject.Properties) { $map[$kv.Name] = [string]$kv.Value } }
    foreach ($k in 'port', 'status', 'requirement', 'error', 'purpose') {
        $v = $null
        if ($params -is [hashtable]) { $v = $params[$k] }
        if (-not [string]::IsNullOrWhiteSpace([string]$v)) { $map[$k] = [string]$v }
    }
    foreach ($k in $map.Keys) { $t = $t.Replace('{' + $k + '}', $map[$k]) }
    $t
}

# ---------- cai dat ----------
$script:setPath = Join-Path $env:LOCALAPPDATA 'PromptSpotlight\settings.json'
$script:defaultKeys = @('Alt+Z', 'Alt+Shift+Z', 'Ctrl+Shift+Z', 'Ctrl+Alt+Z')
$script:S = @{ w = 780; h = 800; lang = 'vi'; theme = 'pink'; params = @{}; fx = $true; hotkeys = $script:defaultKeys; remind = $true }
function Load-Settings {
    try {
        if (Test-Path $script:setPath) {
            $o = Get-Content -Raw -Encoding UTF8 $script:setPath | ConvertFrom-Json
            if ($o.w) { $script:S.w = [int]$o.w }
            if ($o.h) { $script:S.h = [int]$o.h }
            if ($o.lang) { $script:S.lang = [string]$o.lang }
            if ($o.theme) { $script:S.theme = [string]$o.theme }
            if ($null -ne $o.fx) { $script:S.fx = [bool]$o.fx }
            if ($null -ne $o.remind) { $script:S.remind = [bool]$o.remind }
            if ($o.hotkeys) { $script:S.hotkeys = @($o.hotkeys | ForEach-Object { [string]$_ }) }
            if ($o.params) { foreach ($kv in $o.params.PSObject.Properties) { $script:S.params[$kv.Name] = [string]$kv.Value } }
        }
    } catch { Log "settings load: $_" }
}
function Save-Settings {
    try {
        $d = Split-Path $script:setPath
        if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
        [IO.File]::WriteAllText($script:setPath, (ConvertTo-Json -InputObject $script:S -Depth 4), (New-Object Text.UTF8Encoding $false))
    } catch { Log "settings save: $_" }
}
Load-Settings

# ---------- trang thai ----------
$script:prev = [IntPtr]::Zero
$script:visible = $false
$script:shownAt = Get-Date
$script:win = $null
$script:wpfHwnd = [IntPtr]::Zero
$script:inDialog = $false
$script:quitting = $false
$script:pkeys = 'port', 'status', 'requirement', 'error', 'purpose'
$script:labels = @{ port = 'CỔNG ({port})'; status = 'TÌNH TRẠNG ({status})'; requirement = 'YÊU CẦU ({requirement})'; error = 'MÔ TẢ LỖI ({error})'; purpose = 'MỤC ĐÍCH MONG MUỐN ({purpose})' }

function Get-Work { [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea }
function Get-Pfx { if ($script:S.theme -eq 'blue') { 'b' } else { 'p' } }

function Set-Clip($text) {
    for ($i = 0; $i -lt 8; $i++) {
        try { [System.Windows.Forms.Clipboard]::SetDataObject($text, $true); return $true } catch { Start-Sleep -Milliseconds 60 }
    }
    $false
}
function Send-CtrlV {
    [PSN]::keybd_event(0x11, 0, 0, [UIntPtr]::Zero); [PSN]::keybd_event(0x56, 0, 0, [UIntPtr]::Zero)
    [PSN]::keybd_event(0x56, 0, 2, [UIntPtr]::Zero); [PSN]::keybd_event(0x11, 0, 2, [UIntPtr]::Zero)
}
function Invoke-Later([int]$ms, [scriptblock]$action) {
    $t = New-Object System.Windows.Threading.DispatcherTimer
    $t.Interval = [TimeSpan]::FromMilliseconds($ms)
    $t.Tag = $action
    $t.Add_Tick({ param($s, $e) $s.Stop(); & $s.Tag })
    $t.Start()
}

$script:imgCache = @{}
function Load-Img($name) {
    if ($script:imgCache.ContainsKey($name)) { return $script:imgCache[$name] }
    $f = Join-Path $script:dir $name
    if (-not (Test-Path $f)) { return $null }
    $bi = New-Object System.Windows.Media.Imaging.BitmapImage
    $bi.BeginInit(); $bi.CacheOption = 'OnLoad'; $bi.UriSource = New-Object Uri($f); $bi.EndInit(); $bi.Freeze()
    $script:imgCache[$name] = $bi
    $bi
}

# ---------- phim tat ----------
function ConvertTo-Hotkey([string]$s) {
    $mod = 0x4000; $key = $null
    foreach ($tok in ($s -split '\+')) {
        switch ($tok.Trim().ToLowerInvariant()) {
            'alt' { $mod = $mod -bor 1 } 'ctrl' { $mod = $mod -bor 2 } 'shift' { $mod = $mod -bor 4 } 'win' { $mod = $mod -bor 8 }
            default { $key = $tok.Trim() }
        }
    }
    if (-not $key) { return $null }
    $name = if ($key -match '^\d$') { "D$key" } else { $key }
    try { $k = [Enum]::Parse([System.Windows.Input.Key], $name, $true); $vk = [System.Windows.Input.KeyInterop]::VirtualKeyFromKey($k) } catch { return $null }
    @{ mod = [uint32]$mod; vk = [uint32]$vk }
}
function Register-Hotkeys {
    for ($i = 1; $i -le 12; $i++) { [void][PSN]::UnregisterHotKey($script:hk.Handle, $i) }
    $failed = @(); $id = 1
    foreach ($s in $script:S.hotkeys) {
        $h = ConvertTo-Hotkey $s
        if ($h -and [PSN]::RegisterHotKey($script:hk.Handle, $id, $h.mod, $h.vk)) { $id++ } else { $failed += $s }
    }
    $failed
}
function Get-HotkeyText { ($script:S.hotkeys | Select-Object -First 1) }

function Show-HotkeyDialog {
    $script:inDialog = $true
    $x = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="Đổi phím tắt" Width="420" Height="230" WindowStartupLocation="CenterScreen" Topmost="True" ResizeMode="NoResize" FontFamily="Segoe UI">
  <StackPanel Margin="18">
    <TextBlock Text="Nhấn tổ hợp phím mới (cần ít nhất một phím Ctrl / Alt / Shift / Win):" TextWrapping="Wrap" FontSize="13"/>
    <Border Margin="0,12" Background="#FFF0F6" BorderBrush="#FF8FB6" BorderThickness="2" CornerRadius="10" Padding="10">
      <TextBlock Name="Cap" Text="..." FontSize="22" FontWeight="Bold" Foreground="#E8559A" HorizontalAlignment="Center"/>
    </Border>
    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
      <Button Name="Def" Content="Mặc định" Padding="12,4" Margin="0,0,8,0"/>
      <Button Name="Ok" Content="Lưu" Padding="16,4" Margin="0,0,8,0" IsDefault="True"/>
      <Button Name="No" Content="Hủy" Padding="12,4" IsCancel="True"/>
    </StackPanel>
  </StackPanel>
</Window>
'@
    $dlg = [System.Windows.Markup.XamlReader]::Parse($x)
    $cap = $dlg.FindName('Cap'); $script:newKey = $null
    $cap.Text = Get-HotkeyText
    $dlg.Add_PreviewKeyDown({
            param($s, $e)
            $k = if ($e.Key -eq 'System') { $e.SystemKey } else { $e.Key }
            if ($k -in 'LeftCtrl', 'RightCtrl', 'LeftAlt', 'RightAlt', 'LeftShift', 'RightShift', 'LWin', 'RWin', 'None', 'DeadCharProcessed') { return }
            $m = [System.Windows.Input.Keyboard]::Modifiers
            $parts = @()
            if ($m -band [System.Windows.Input.ModifierKeys]::Control) { $parts += 'Ctrl' }
            if ($m -band [System.Windows.Input.ModifierKeys]::Alt) { $parts += 'Alt' }
            if ($m -band [System.Windows.Input.ModifierKeys]::Shift) { $parts += 'Shift' }
            if ($m -band [System.Windows.Input.ModifierKeys]::Windows) { $parts += 'Win' }
            $e.Handled = $true
            if ($parts.Count -eq 0) { $cap.Text = 'Cần thêm Ctrl / Alt / Shift / Win'; return }
            $name = [string]$k; if ($name -match '^D(\d)$') { $name = $Matches[1] }
            $script:newKey = ($parts + $name) -join '+'
            $cap.Text = $script:newKey
        })
    $dlg.FindName('Def').Add_Click({ $script:newKey = 'DEFAULT'; $dlg.DialogResult = $true })
    $dlg.FindName('Ok').Add_Click({ if ($script:newKey) { $dlg.DialogResult = $true } })
    $r = $dlg.ShowDialog()
    $script:inDialog = $false
    if ($r -and $script:newKey) {
        $script:S.hotkeys = if ($script:newKey -eq 'DEFAULT') { $script:defaultKeys } else { @($script:newKey) }
        $failed = Register-Hotkeys
        Save-Settings
        Update-HotkeyUi
        if ($failed.Count) { [void][System.Windows.MessageBox]::Show("Không đăng ký được: $($failed -join ', ') (đã bị phần mềm khác chiếm). Hãy chọn tổ hợp khác.", 'Đổi phím tắt') }
        else { Show-Reminder "Phím tắt đã đổi: $(Get-HotkeyText)" }
    }
}
function Update-HotkeyUi {
    if ($script:wFootTxt) { $script:wFootTxt.Text = "Nhấp đôi → tự dán vào con trỏ · Phím tắt: $(Get-HotkeyText)" }
    if ($script:ni) { $script:ni.Text = "Siêu Công Cụ Claude Code - nhấn $(Get-HotkeyText)" }
}
function Show-Reminder([string]$msg) {
    if ($script:ni) { $script:ni.ShowBalloonTip(5000, 'Siêu Công Cụ Claude Code', $msg, 'Info') }
}

# ---------- khoi dong cung Windows ----------
function Get-StartupLnk { Join-Path ([Environment]::GetFolderPath('Startup')) 'SieuCongCuClaudeCode.lnk' }
function Test-Autostart { Test-Path (Get-StartupLnk) }
function Set-Autostart([bool]$on) {
    $lnk = Get-StartupLnk
    if ($on) {
        $ws = New-Object -ComObject WScript.Shell
        $s = $ws.CreateShortcut($lnk)
        $s.TargetPath = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
        $s.Arguments = "-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$($script:dir)\popup-host.ps1`""
        $s.WorkingDirectory = $script:dir
        $s.WindowStyle = 7
        $s.Save()
    } elseif (Test-Path $lnk) { Remove-Item $lnk -Force }
}

# ---------- giao dien WPF ----------
function Build-Wpf {
    $xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Siêu Công Cụ Claude Code" Width="780" Height="800" MinWidth="580" MinHeight="560" WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        ShowInTaskbar="False" Topmost="True" ShowActivated="False" ResizeMode="CanResizeWithGrip" FontFamily="Segoe UI, Segoe UI Emoji">
  <Border Name="Card" Margin="10" CornerRadius="28" BorderBrush="White" BorderThickness="3">
    <Border.Background>
      <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
        <GradientStop Color="#FFE3EE" Offset="0"/><GradientStop Color="#FFF6FA" Offset="0.45"/><GradientStop Color="#E2F0FF" Offset="1"/>
      </LinearGradientBrush>
    </Border.Background>
    <Border.Effect><DropShadowEffect BlurRadius="26" Opacity="0.35" ShadowDepth="4" Color="#E8559A"/></Border.Effect>
    <Grid>
      <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/>
      </Grid.RowDefinitions>
      <Grid Grid.Row="0" Name="Head" Background="Transparent" Margin="10,8,10,0">
        <Grid.ColumnDefinitions><ColumnDefinition Width="92"/><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions>
        <Image Name="Girl1" Grid.Column="0" Height="84" Width="84"/>
        <StackPanel Grid.Column="1" VerticalAlignment="Center" HorizontalAlignment="Center">
          <TextBlock Name="Ttl" Text="&#127800; Siêu Công Cụ Claude Code &#127800;" FontSize="22" FontWeight="Bold" Foreground="#E8559A" HorizontalAlignment="Center"/>
          <Border Name="Pill" Background="#FF8FB6" CornerRadius="12" Padding="14,2" Margin="0,6,0,0" HorizontalAlignment="Center">
            <TextBlock Text="&#128144; Quà 20/10 &#128144;" Foreground="White" FontWeight="Bold" FontSize="12"/>
          </Border>
        </StackPanel>
        <Image Name="Girl2" Grid.Column="2" Height="84" Width="84"/>
        <Button Name="Theme" Grid.Column="2" Content="&#127752;" Width="26" Height="26" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,0,-4,0" Background="White" BorderBrush="#FFC2D9" ToolTip="Đổi giao diện hồng / xanh"/>
      </Grid>
      <Border Grid.Row="1" Name="QuoteBox" Margin="18,4,18,0" Padding="12,5" CornerRadius="14" Background="#99FFFFFF" Cursor="Hand" ToolTip="Bấm để đổi câu khác">
        <TextBlock Name="Quote" FontSize="12.5" FontStyle="Italic" TextAlignment="Center" TextWrapping="Wrap" Foreground="#C24A82"/>
      </Border>
      <WrapPanel Grid.Row="2" Name="Params" Margin="14,8,6,0"/>
      <Border Grid.Row="3" Margin="16,2,16,0" CornerRadius="16" BorderBrush="#FFC2D9" BorderThickness="2" Background="White">
        <Grid>
          <TextBox Name="Q" BorderThickness="0" Background="Transparent" Padding="10,7" FontSize="14" Foreground="#4A3350"/>
          <TextBlock Name="QHint" Text="Tìm prompt... (gõ để lọc, Enter = dán, Esc = đóng)" Foreground="#B9A3B3" FontSize="14" Margin="12,7,0,0" IsHitTestVisible="False"/>
        </Grid>
      </Border>
      <WrapPanel Grid.Row="4" Name="Tabs" Margin="14,8,6,0"/>
      <ListBox Grid.Row="5" Name="Lst" Margin="12,4,12,4" Background="Transparent" BorderThickness="0" HorizontalContentAlignment="Stretch" ScrollViewer.HorizontalScrollBarVisibility="Disabled">
        <ListBox.Resources>
          <SolidColorBrush x:Key="{x:Static SystemColors.HighlightBrushKey}" Color="#FFD6E6"/>
          <SolidColorBrush x:Key="{x:Static SystemColors.ControlBrushKey}" Color="#FFD6E6"/>
          <SolidColorBrush x:Key="{x:Static SystemColors.HighlightTextBrushKey}" Color="#4A3350"/>
          <SolidColorBrush x:Key="{x:Static SystemColors.ControlTextBrushKey}" Color="#4A3350"/>
        </ListBox.Resources>
      </ListBox>
      <Border Grid.Row="6" CornerRadius="0,0,24,24" Background="#A6FFFFFF" Padding="8,4">
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="52"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
          <Image Name="Bunny" Width="46" Height="46"/>
          <TextBlock Name="FootTxt" Grid.Column="1" VerticalAlignment="Center" FontSize="11.5" Foreground="#8A6A82" TextWrapping="Wrap"/>
          <CheckBox Name="FxChk" Grid.Column="2" Content="&#10024; Hiệu ứng" IsChecked="True" VerticalAlignment="Center" Margin="6,0" Foreground="#8A6A82" FontSize="11.5"/>
          <Button Name="KeyBtn" Grid.Column="3" Content="&#9000; Phím tắt" Padding="8,2" Margin="4,0" Background="White" BorderBrush="#FFC2D9" FontSize="11.5" ToolTip="Đổi phím tắt"/>
          <StackPanel Grid.Column="4" Orientation="Horizontal" VerticalAlignment="Center" Margin="4,0,18,0">
            <RadioButton Name="LVi" Content="VI" IsChecked="True" Margin="4,0" Foreground="#3F79C9" FontWeight="Bold"/>
            <RadioButton Name="LEn" Content="EN" Margin="4,0" Foreground="#3F79C9" FontWeight="Bold"/>
            <RadioButton Name="LBi" Content="VI+EN" Margin="4,0" Foreground="#3F79C9" FontWeight="Bold"/>
          </StackPanel>
        </Grid>
      </Border>
      <Canvas Name="FxCanvas" Grid.RowSpan="7" IsHitTestVisible="False">
        <Image Name="Cur" Width="40" Height="40" Visibility="Collapsed"/>
      </Canvas>
    </Grid>
  </Border>
</Window>
'@
    $win = [System.Windows.Markup.XamlReader]::Parse($xaml)
    foreach ($n in 'Card', 'Ttl', 'Pill', 'Theme', 'Head', 'Girl1', 'Girl2', 'Bunny', 'Quote', 'QuoteBox', 'Params', 'Q', 'QHint', 'Tabs', 'Lst', 'FootTxt', 'FxChk', 'KeyBtn', 'LVi', 'LEn', 'LBi', 'FxCanvas', 'Cur') {
        Set-Variable -Scope Script -Name ('w' + $n) -Value $win.FindName($n)
    }
    $win.Width = [Math]::Max(580, $script:S.w); $win.Height = [Math]::Max(560, $script:S.h)
    $script:curLang = [string]$script:S.lang
    $script:curCat = ''
    $script:wFields = @{}; $script:wHints = @{}
    $conv = New-Object System.Windows.Media.BrushConverter
    foreach ($k in $script:pkeys) {
        $sp = New-Object System.Windows.Controls.StackPanel
        $sp.Margin = '0,0,8,6'; $sp.Width = $(if ($k -eq 'port') { 84 } else { 170 })
        $lb = New-Object System.Windows.Controls.TextBlock
        $lb.Text = $script:labels[$k]; $lb.FontSize = 10; $lb.FontWeight = 'Bold'; $lb.Foreground = [System.Windows.Media.Brushes]::Gray; $lb.Margin = '4,0,0,2'; $lb.TextTrimming = 'CharacterEllipsis'
        $bd = New-Object System.Windows.Controls.Border
        $bd.CornerRadius = 10; $bd.BorderThickness = 1.5; $bd.BorderBrush = $conv.ConvertFromString('#FFC2D9'); $bd.Background = [System.Windows.Media.Brushes]::White
        $g = New-Object System.Windows.Controls.Grid
        $tb = New-Object System.Windows.Controls.TextBox
        $tb.BorderThickness = 0; $tb.Background = [System.Windows.Media.Brushes]::Transparent; $tb.Padding = '8,4'; $tb.FontSize = 12.5; $tb.Tag = $k
        $tb.Text = [string]$script:S.params[$k]
        $hn = New-Object System.Windows.Controls.TextBlock
        $hn.Foreground = $conv.ConvertFromString('#B9A3B3'); $hn.FontSize = 12.5; $hn.Margin = '9,5,4,0'; $hn.IsHitTestVisible = $false; $hn.TextTrimming = 'CharacterEllipsis'
        if ($k -eq 'port') { $tb.FontFamily = 'Consolas'; $tb.FontWeight = 'Bold' }
        [void]$g.Children.Add($tb); [void]$g.Children.Add($hn); $bd.Child = $g
        [void]$sp.Children.Add($lb); [void]$sp.Children.Add($bd)
        [void]$script:wParams.Children.Add($sp)
        $script:wFields[$k] = $tb; $script:wHints[$k] = $hn
        $tb.Add_PreviewMouseLeftButtonDown({ Set-WpfActivatable $true })
        $tb.Add_TextChanged({
                param($s, $e)
                $script:S.params[[string]$s.Tag] = $s.Text
                $script:wHints[[string]$s.Tag].Visibility = $(if ($s.Text) { 'Collapsed' } else { 'Visible' })
                Save-Settings
            })
        $hn.Visibility = $(if ($tb.Text) { 'Collapsed' } else { 'Visible' })
    }
    if ($script:curLang -eq 'en') { $script:wLEn.IsChecked = $true } elseif ($script:curLang -eq 'bi') { $script:wLBi.IsChecked = $true }

    $script:fx = New-Object FX
    $script:fx.Attach($win, $script:wFxCanvas, $script:wCur, [System.Windows.FrameworkElement[]]@($script:wGirl1, $script:wGirl2))
    $script:fx.add_Notice({ param($m) Log $m })
    $script:wFxChk.IsChecked = [bool]$script:S.fx
    $script:fx.SetEnabled([bool]$script:S.fx)
    $script:wFxChk.Add_Click({ $script:S.fx = [bool]$script:wFxChk.IsChecked; $script:fx.SetEnabled($script:S.fx); Save-Settings })

    Set-WpfTheme ($script:S.theme -eq 'blue')
    Update-HotkeyUi

    $script:wTheme.Add_Click({ Set-WpfTheme ($script:S.theme -ne 'blue'); Save-Settings })
    $script:wKeyBtn.Add_Click({ Show-HotkeyDialog })
    $script:wQuoteBox.Add_MouseLeftButtonDown({ Next-Quote })
    $script:wQ.Add_TextChanged({ $script:wQHint.Visibility = $(if ($script:wQ.Text) { 'Collapsed' } else { 'Visible' }); Update-WpfList })
    $script:wLst.Add_SelectionChanged({ Update-WpfHints })
    $script:wLVi.Add_Checked({ $script:curLang = 'vi'; $script:S.lang = 'vi'; Save-Settings; Set-Quote })
    $script:wLEn.Add_Checked({ $script:curLang = 'en'; $script:S.lang = 'en'; Save-Settings; Set-Quote })
    $script:wLBi.Add_Checked({ $script:curLang = 'bi'; $script:S.lang = 'bi'; Save-Settings; Set-Quote })
    $script:wHead.Add_MouseLeftButtonDown({ try { $script:win.DragMove() } catch {} })
    $script:wLst.Add_MouseDoubleClick({
            $it = $script:wLst.SelectedItem
            if ($it -and $it.Tag) { Do-Pick ([string]$it.Tag) $script:curLang $script:S.params }
        })
    $script:wQ.Add_PreviewMouseLeftButtonDown({ Set-WpfActivatable $true })
    $win.Add_PreviewKeyDown({
            param($s, $e)
            if ($e.Key -eq 'Escape') { Hide-Popup; $e.Handled = $true }
            elseif ($e.Key -eq 'Enter') {
                $it = $script:wLst.SelectedItem
                if ($it -and $it.Tag) { Do-Pick ([string]$it.Tag) $script:curLang $script:S.params }
                $e.Handled = $true
            }
            elseif ($e.Key -eq 'Down' -and $script:wQ.IsKeyboardFocused) {
                if ($script:wLst.SelectedIndex -lt $script:wLst.Items.Count - 1) { $script:wLst.SelectedIndex++ }
                $script:wLst.ScrollIntoView($script:wLst.SelectedItem); $e.Handled = $true
            }
            elseif ($e.Key -eq 'Up' -and $script:wQ.IsKeyboardFocused) {
                if ($script:wLst.SelectedIndex -gt 0) { $script:wLst.SelectedIndex-- }
                $script:wLst.ScrollIntoView($script:wLst.SelectedItem); $e.Handled = $true
            }
        })
    $win.Add_SourceInitialized({
            $script:wpfHwnd = (New-Object System.Windows.Interop.WindowInteropHelper($script:win)).Handle
            Set-WpfActivatable $false
        })
    Build-WpfTabs
    $qt = New-Object System.Windows.Threading.DispatcherTimer
    $qt.Interval = [TimeSpan]::FromSeconds(120)
    $qt.Add_Tick({ Next-Quote })
    $qt.Start()
    $win
}

function Set-Quote {
    if (-not $script:quotes.Count) { $script:wQuoteBox.Visibility = 'Collapsed'; return }
    $q = $script:quotes[$script:qi]
    $script:wQuote.Text = switch ($script:curLang) { 'en' { [string]$q.en } 'bi' { "$($q.vi)`n$($q.en)" } default { [string]$q.vi } }
}
function Next-Quote {
    if (-not $script:quotes.Count) { return }
    $n = $script:quotes.Count
    $script:qi = (([int]$script:qi) + 1 + (Get-Random -Maximum ([Math]::Max(1, $n - 1)))) % $n
    $out = New-Object System.Windows.Media.Animation.DoubleAnimation(1, 0, [TimeSpan]::FromMilliseconds(250))
    $out.Add_Completed({
            Set-Quote
            $in = New-Object System.Windows.Media.Animation.DoubleAnimation(0, 1, [TimeSpan]::FromMilliseconds(350))
            $script:wQuote.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $in)
        })
    $script:wQuote.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $out)
}

function Set-WpfTheme([bool]$blue) {
    $script:S.theme = $(if ($blue) { 'blue' } else { 'pink' })
    $pfx = Get-Pfx
    $conv = New-Object System.Windows.Media.BrushConverter
    $script:wGirl1.Source = Load-Img "chibi-$pfx-hero1.png"
    $script:wGirl2.Source = Load-Img "chibi-$pfx-hero2.png"
    $script:wBunny.Source = Load-Img $(if ($blue) { 'chibi-bear.png' } else { 'chibi-bunny.png' })
    $script:wCur.Source = Load-Img "cursor-$pfx.png"
    $g = $(if ($blue) { '#DCECFF', '#F4F9FF', '#E6EEFF' } else { '#FFE3EE', '#FFF6FA', '#E2F0FF' })
    $script:wTtl.Foreground = $conv.ConvertFromString($(if ($blue) { '#3F79C9' } else { '#E8559A' }))
    $script:wQuote.Foreground = $conv.ConvertFromString($(if ($blue) { '#3F79C9' } else { '#C24A82' }))
    $script:wPill.Background = $conv.ConvertFromString($(if ($blue) { '#7FB8FF' } else { '#FF8FB6' }))
    $br = New-Object System.Windows.Media.LinearGradientBrush
    $br.StartPoint = '0,0'; $br.EndPoint = '1,1'
    $o = 0, 0.45, 1
    for ($i = 0; $i -lt 3; $i++) { [void]$br.GradientStops.Add((New-Object System.Windows.Media.GradientStop($conv.ConvertFromString($g[$i]).Color, $o[$i]))) }
    $script:wCard.Background = $br
    if ($script:fx) { $script:fx.Blue = $blue }
    if ($script:wTabs.Children.Count) { Update-WpfTabs; Update-WpfList }
}

function Build-WpfTabs {
    $script:wTabs.Children.Clear()
    $cats = @($script:uiItems | ForEach-Object { $_.cat } | Select-Object -Unique)
    $names = @('') + $cats
    foreach ($c in $names) {
        $cnt = if ($c) { @($script:uiItems | Where-Object { $_.cat -eq $c }).Count } else { $script:uiItems.Count }
        $b = New-Object System.Windows.Controls.Border
        $b.CornerRadius = 14; $b.BorderThickness = 1.5; $b.Padding = '12,4'; $b.Margin = '0,0,5,6'; $b.Cursor = 'Hand'; $b.Tag = $c
        $tx = New-Object System.Windows.Controls.TextBlock
        $tx.FontSize = 12; $tx.Text = $(if ($c) { "$c ($cnt)" } else { "Tất cả ($cnt)" })
        $b.Child = $tx
        $b.Add_MouseLeftButtonDown({
                param($s, $e)
                $script:curCat = [string]$s.Tag
                Update-WpfTabs
                Update-WpfList
            })
        [void]$script:wTabs.Children.Add($b)
    }
    Update-WpfTabs
}

function Update-WpfTabs {
    $conv = New-Object System.Windows.Media.BrushConverter
    $blue = ($script:S.theme -eq 'blue')
    $main = $(if ($blue) { '#7FB8FF' } else { '#FF8FB6' })
    $i = 0
    foreach ($b in $script:wTabs.Children) {
        $alt = ($i % 2 -eq 1)
        $useBlue = ($alt -xor $blue)
        $line = $(if ($useBlue) { '#B9D9FF' } else { '#FFC2D9' })
        $txt = $(if ($useBlue) { '#3F79C9' } else { '#C24A82' })
        $b.BorderBrush = $conv.ConvertFromString($line)
        if ([string]$b.Tag -eq $script:curCat) { $b.Background = $conv.ConvertFromString($main); $b.Child.Foreground = [System.Windows.Media.Brushes]::White }
        else { $b.Background = [System.Windows.Media.Brushes]::White; $b.Child.Foreground = $conv.ConvertFromString($txt) }
        $i++
    }
}

function Update-WpfHints {
    $it = $script:wLst.SelectedItem
    $dp = $null
    if ($it -and $it.Tag) { $d = $script:uiItems | Where-Object { $_.id -eq [string]$it.Tag } | Select-Object -First 1; if ($d) { $dp = $d.dp } }
    foreach ($k in $script:pkeys) { $script:wHints[$k].Text = $(if ($dp) { [string]$dp.$k } else { '' }) }
}

function Set-WpfActivatable([bool]$on) {
    if (-not $script:wpfHwnd -or $script:wpfHwnd -eq [IntPtr]::Zero) { return }
    $ex = [PSN]::GetWindowLong($script:wpfHwnd, -20)
    if ($on) { $ex = $ex -band (-bnot 0x08000000) } else { $ex = $ex -bor 0x08000000 -bor 0x80 }
    [void][PSN]::SetWindowLong($script:wpfHwnd, -20, $ex)
    if ($on) { [void]$script:win.Activate(); [PSN]::ForceForeground($script:wpfHwnd) }
}

function Update-WpfList {
    $q = $script:wQ.Text.ToLowerInvariant()
    $pfx = Get-Pfx
    $script:wLst.Items.Clear()
    foreach ($d in $script:uiItems) {
        if ($script:curCat -and $d.cat -ne $script:curCat) { continue }
        if ($q -and (($d.title + ' ' + $d.tags + ' ' + $d.cat).ToLowerInvariant().IndexOf($q) -lt 0)) { continue }
        $scn = $script:chibiMap[$d.id]; if (-not $scn) { $scn = 'laptop' }
        $row = New-Object System.Windows.Controls.StackPanel
        $row.Orientation = 'Horizontal'
        $im = New-Object System.Windows.Controls.Image
        $im.Width = 48; $im.Height = 48; $im.Margin = '0,0,10,0'; $im.Source = Load-Img "chibi-$pfx-$scn.png"
        $col = New-Object System.Windows.Controls.StackPanel
        $col.VerticalAlignment = 'Center'
        $t1 = New-Object System.Windows.Controls.TextBlock
        $t1.Text = "$($d.icon) $($d.title)"; $t1.FontWeight = 'SemiBold'; $t1.FontSize = 13; $t1.TextWrapping = 'Wrap'; $t1.MaxWidth = 560
        $t2 = New-Object System.Windows.Controls.TextBlock
        $t2.Text = $d.tags; $t2.FontSize = 11; $t2.Foreground = [System.Windows.Media.Brushes]::Gray; $t2.TextTrimming = 'CharacterEllipsis'; $t2.MaxWidth = 560
        [void]$col.Children.Add($t1); [void]$col.Children.Add($t2)
        [void]$row.Children.Add($im); [void]$row.Children.Add($col)
        $li = New-Object System.Windows.Controls.ListBoxItem
        $li.Content = $row; $li.Tag = $d.id; $li.Padding = '6,4'
        $script:fx.Lift($li)
        [void]$script:wLst.Items.Add($li)
    }
    if ($script:wLst.Items.Count -gt 0) { $script:wLst.SelectedIndex = 0 }
}

function Show-Popup {
    if ($script:inDialog) { return }
    $fg = [PSN]::GetForegroundWindow()
    if ($fg -ne $script:wpfHwnd) { $script:prev = $fg }
    if (-not $script:win) { $script:win = Build-Wpf; $script:win.Show(); $script:win.Hide() }
    $script:wQ.Text = ''
    $script:qi = Get-Random -Maximum ([Math]::Max(1, $script:quotes.Count))
    Set-Quote
    Update-WpfList
    $w = Get-Work
    $script:win.Left = $w.Left + ($w.Width - $script:win.Width) / 2
    $script:win.Top = $w.Top + ($w.Height - $script:win.Height) / 3
    Set-WpfActivatable $false
    $script:win.Show()
    $script:visible = $true
    $script:shownAt = Get-Date
}

function Hide-Popup {
    if ($script:visible -and $script:win) {
        $w = [int]$script:win.ActualWidth; $h = [int]$script:win.ActualHeight
        if ($w -gt 300 -and $h -gt 300 -and ($w -ne $script:S.w -or $h -ne $script:S.h)) { $script:S.w = $w; $script:S.h = $h; Save-Settings }
    }
    $script:visible = $false
    if ($script:win) { $script:win.Hide() }
}

function Toggle-Popup { if ($script:visible) { Hide-Popup } else { Show-Popup } }

function Do-Pick($id, $lang, $params) {
    $text = Get-PromptText $id $lang $params
    if (-not $text) { return }
    [void](Set-Clip $text)
    Hide-Popup
    $script:pickTarget = [IntPtr]$script:prev
    Invoke-Later 120 {
        $target = $script:pickTarget
        if ($target -ne [IntPtr]::Zero -and [PSN]::IsWindow($target) -and [PSN]::GetForegroundWindow() -ne $target) { [PSN]::ForceForeground($target) }
        Invoke-Later 200 { Send-CtrlV }
    }
    Log "pick $id ($lang)"
}

# ---------- khoi dong ----------
try {
    $script:app = New-Object System.Windows.Application
    $script:app.ShutdownMode = 'OnExplicitShutdown'
    $script:qi = 0
    $script:win = Build-Wpf
    $script:win.Show(); $script:win.Hide()

    $script:hk = New-Object HotkeyWnd
    $failed = Register-Hotkeys
    $script:hk.add_Fired({ param($id) try { Toggle-Popup } catch { Log "hotkey error: $_" } })

    $ni = New-Object System.Windows.Forms.NotifyIcon
    $png = Join-Path $script:dir 'chibi-heart.png'
    if (Test-Path $png) {
        $ms = New-Object IO.MemoryStream(, [IO.File]::ReadAllBytes($png))
        $bmp = New-Object System.Drawing.Bitmap((New-Object System.Drawing.Bitmap($ms)), 32, 32)
        $ni.Icon = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
    } else { $ni.Icon = [System.Drawing.SystemIcons]::Information }
    $script:ni = $ni
    Update-HotkeyUi
    $menu = New-Object System.Windows.Forms.ContextMenuStrip
    [void]$menu.Items.Add('Mở Siêu Công Cụ', $null, { Show-Popup })
    [void]$menu.Items.Add('Đổi phím tắt...', $null, { Show-HotkeyDialog })
    $rem = New-Object System.Windows.Forms.ToolStripMenuItem('Nhắc phím tắt mỗi giờ')
    $rem.Checked = [bool]$script:S.remind
    $rem.Add_Click({ $script:S.remind = -not $script:S.remind; $script:rem.Checked = [bool]$script:S.remind; Save-Settings })
    $script:rem = $rem
    [void]$menu.Items.Add($rem)
    $auto = New-Object System.Windows.Forms.ToolStripMenuItem('Khởi động cùng Windows')
    $auto.Checked = Test-Autostart
    $auto.Add_Click({ Set-Autostart (-not $script:auto.Checked); $script:auto.Checked = Test-Autostart })
    $script:auto = $auto
    [void]$menu.Items.Add($auto)
    [void]$menu.Items.Add('Thoát', $null, {
            $script:quitting = $true
            $script:ni.Visible = $false
            for ($i = 1; $i -le 12; $i++) { [void][PSN]::UnregisterHotKey($script:hk.Handle, $i) }
            $script:app.Shutdown()
        })
    $ni.ContextMenuStrip = $menu
    $ni.Visible = $true
    $ni.Add_MouseClick({ param($s, $e) if ($e.Button -eq 'Left') { Show-Popup } })

    $msg = "Nhấn $(Get-HotkeyText) để mở bất cứ lúc nào. Nhấp đôi một prompt để dán vào con trỏ."
    if ($failed.Count) { $msg += "`nKhông đăng ký được: " + ($failed -join ', ') + ' (đã bị phần mềm khác chiếm).' }
    Show-Reminder $msg

    $remT = New-Object System.Windows.Threading.DispatcherTimer
    $remT.Interval = [TimeSpan]::FromMinutes(60)
    $remT.Add_Tick({ if ($script:S.remind -and -not $script:visible) { Show-Reminder "Nhớ nhé: nhấn $(Get-HotkeyText) để mở Siêu Công Cụ Claude Code." } })
    $remT.Start()

    $watch = New-Object System.Windows.Threading.DispatcherTimer
    $watch.Interval = [TimeSpan]::FromMilliseconds(400)
    $watch.Add_Tick({
            if ($script:visible -and -not $script:inDialog -and ((Get-Date) - $script:shownAt).TotalMilliseconds -gt 1200) {
                $fg = [PSN]::GetForegroundWindow()
                if ($fg -ne [IntPtr]::Zero -and $fg -ne $script:wpfHwnd -and $fg -ne $script:prev) { Hide-Popup }
            }
        })
    $watch.Start()
    Log "started; failed hotkeys: $($failed -join ',')"

    [void]$script:app.Run()
} catch {
    Log "fatal: $_"
    [System.Windows.Forms.MessageBox]::Show("Loi: $_`nLog: $($script:log)", 'Siêu Công Cụ Claude Code') | Out-Null
}
