# Cua so "Cap nhat & phien ban": bat/tat tu cap nhat, cap nhat bang tay, ha cap ve ban cu, quan ly cac app trong kho.
$ErrorActionPreference = 'Stop'
$script:dir = $PSScriptRoot
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

$createdNew = $false
$script:mutex = New-Object System.Threading.Mutex($true, 'Local\SCCVersionManager', [ref]$createdNew)
if (-not $createdNew) { exit 0 }

$script:upd = Join-Path $script:dir 'auto-update.ps1'
$script:store = Join-Path $script:dir 'repo-store.ps1'
$script:stateFile = Join-Path $env:LOCALAPPDATA 'PromptSpotlight\update-state.json'
$script:apps = @()

function Log([string]$m) { $script:wLog.AppendText("[$(Get-Date -Format HH:mm:ss)] $m`r`n"); $script:wLog.ScrollToEnd() }
function Run-Ps([string]$file, [string[]]$a) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'powershell.exe'
    $psi.Arguments = (@('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $file) + $a | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }) -join ' '
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.StandardOutputEncoding = [Text.Encoding]::UTF8; $psi.StandardErrorEncoding = [Text.Encoding]::UTF8
    $script:win.Cursor = [System.Windows.Input.Cursors]::Wait
    $script:win.Dispatcher.Invoke([Action] {}, 'Render')
    try {
        $p = [System.Diagnostics.Process]::Start($psi)
        $o = $p.StandardOutput.ReadToEnd(); $e = $p.StandardError.ReadToEnd(); $p.WaitForExit()
        [pscustomobject]@{ Ok = ($p.ExitCode -eq 0); Out = (($o + $e).Trim()) }
    } finally { $script:win.Cursor = $null }
}
function Get-State {
    $s = @{ autoUpdate = $true; pinned = '' }
    if (Test-Path $script:stateFile) { try { $o = Get-Content -Raw -Encoding UTF8 $script:stateFile | ConvertFrom-Json; if ($null -ne $o.autoUpdate) { $s.autoUpdate = [bool]$o.autoUpdate }; if ($o.pinned) { $s.pinned = [string]$o.pinned } } catch {} }
    $s
}
function Set-AutoUpdate([bool]$on) {
    $s = Get-State; $s.autoUpdate = $on
    $d = Split-Path $script:stateFile; if (-not (Test-Path $d)) { New-Item -ItemType Directory $d -Force | Out-Null }
    [IO.File]::WriteAllText($script:stateFile, (ConvertTo-Json $s), (New-Object Text.UTF8Encoding $false))
}

function Refresh-App {
    $o = Run-Ps $script:upd @('-ListVersions')
    try { $v = $o.Out.Split("`n")[-1] | ConvertFrom-Json } catch { Log "Không đọc được phiên bản: $($o.Out)"; return }
    $script:appInfo = $v
    $st = if ($v.pinned) { "đã ghim bản $($v.pinned) (không tự cập nhật)" } elseif ($v.latest -and [version]$v.latest -gt [version]$v.current) { "CÓ BẢN MỚI $($v.latest)" } else { 'đang là bản mới nhất' }
    $script:wAppInfo.Text = "Đang dùng: v$($v.current)   ·   Mới nhất: v$($v.latest)   ·   $st"
    $script:wAuto.IsChecked = [bool]$v.autoUpdate
    $script:wVerBox.Items.Clear()
    foreach ($x in @($v.local)) { if ($x -ne $v.current) { [void]$script:wVerBox.Items.Add("$x   (có sẵn trên máy)") } }
    foreach ($x in @($v.remote)) { if ($x -ne $v.current -and (@($v.local) -notcontains $x)) { [void]$script:wVerBox.Items.Add("$x   (tải từ GitHub)") } }
    if ($script:wVerBox.Items.Count) { $script:wVerBox.SelectedIndex = 0 }
}
function Refresh-Store {
    $o = Run-Ps $script:store @('list', '-Json')
    try { $rows = @($o.Out.Split("`n")[-1] | ConvertFrom-Json | ForEach-Object { $_ }) } catch { Log "Không đọc được kho: $($o.Out)"; return }
    $rows = @($rows | Where-Object { $_.id -ne 'claude-supertools-1click' })
    $script:apps = $rows
    $script:wGrid.ItemsSource = @($rows | ForEach-Object { [pscustomobject]@{ Id = $_.id; Name = $_.name; Cur = $(if ($_.installed) { $_.ref } else { '—' }); Latest = $_.latest; Status = $_.status } })
}
function Selected-App { $r = $script:wGrid.SelectedItem; if (-not $r) { [void][System.Windows.MessageBox]::Show('Hãy chọn một app trong danh sách.', 'Cập nhật & phiên bản') }; $r }
function Pick-Version([string]$s) { ($s -split '\s+')[0] }

function Act-UpdateNow {
    Log 'Đang cập nhật bản mới nhất...'
    $o = Run-Ps $script:upd @('-Force'); Log $(if ($o.Ok) { 'Xong. Nếu có bản mới, popup sẽ tự khởi động lại.' } else { "Lỗi: $($o.Out)" })
    Refresh-App; Refresh-Store
}
function Act-Rollback([bool]$previous) {
    $to = ''
    if (-not $previous) { if (-not $script:wVerBox.SelectedItem) { Log 'Chưa chọn phiên bản.'; return }; $to = Pick-Version $script:wVerBox.SelectedItem }
    $what = if ($to) { "bản $to" } else { 'bản trước đó' }
    if ([System.Windows.MessageBox]::Show("Hạ cấp về $what?`r`nPopup sẽ khởi động lại và tạm dừng tự cập nhật cho đến khi bạn bấm 'Cập nhật ngay'.", 'Hạ cấp', 'YesNo', 'Question') -ne 'Yes') { return }
    Log "Đang hạ cấp về $what..."
    $a = @('-Rollback'); if ($to) { $a += @('-To', $to) }
    $o = Run-Ps $script:upd $a; Log $(if ($o.Ok) { 'Đã hạ cấp.' } else { "Lỗi: $($o.Out)" }); Refresh-App
}
function Act-StoreInstall {
    $r = Selected-App; if (-not $r) { return }
    Log "Đang cài / cập nhật $($r.Id)..."
    $o = Run-Ps $script:store @('update', $r.Id, '-Latest'); if ($o.Out -match 'chua cai') { $o = Run-Ps $script:store @('install', $r.Id) }
    Log $o.Out; Refresh-Store
}
function Act-StoreAll {
    Log 'Đang cập nhật tất cả app đã cài...'
    $o = Run-Ps $script:store @('update', '-All', '-Latest'); Log $o.Out; Refresh-Store
}
function Act-StoreRollback {
    $r = Selected-App; if (-not $r) { return }
    $v = Run-Ps $script:store @('versions', $r.Id, '-Json')
    try { $j = $v.Out.Split("`n")[-1] | ConvertFrom-Json } catch { Log "Lỗi: $($v.Out)"; return }
    $opts = @(@($j.local) + @($j.remote | Where-Object { @($j.local) -notcontains $_ }) | Where-Object { $_ -and $_ -ne $j.ref } | Select-Object -Unique)
    if (-not $opts.Count) { Log 'Chưa có phiên bản cũ nào để hạ cấp.'; return }
    $pick = [Microsoft.VisualBasic.Interaction]::InputBox("Gõ phiên bản muốn hạ cấp cho '$($r.Id)':`r`n$($opts -join ', ')", 'Hạ cấp app', $opts[0])
    if (-not $pick) { return }
    Log "Đang hạ cấp $($r.Id) về $pick..."
    $o = Run-Ps $script:store @('rollback', $r.Id, '-Ref', $pick); Log $o.Out; Refresh-Store
}

Add-Type -AssemblyName Microsoft.VisualBasic
$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Cập nhật &amp; phiên bản" Width="860" Height="660" MinWidth="720" MinHeight="560" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI, Segoe UI Emoji">
  <Window.Background>
    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1"><GradientStop Color="#FFE3EE" Offset="0"/><GradientStop Color="#FFF6FA" Offset="0.45"/><GradientStop Color="#E2F0FF" Offset="1"/></LinearGradientBrush>
  </Window.Background>
  <Grid Margin="16">
    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="140"/></Grid.RowDefinitions>
    <TextBlock Grid.Row="0" Text="&#128260; Cập nhật &amp; phiên bản" FontSize="24" FontWeight="Bold" Foreground="#E8559A"/>
    <Border Grid.Row="1" Margin="0,10,0,0" Padding="14" CornerRadius="16" Background="#CCFFFFFF" BorderBrush="#FFC2D9" BorderThickness="1.5">
      <StackPanel>
        <TextBlock Text="Siêu Công Cụ Claude Code" FontWeight="Bold" FontSize="15"/>
        <TextBlock Name="AppInfo" Margin="0,4,0,8" Foreground="#8A6A82" Text="Đang kiểm tra..."/>
        <CheckBox Name="Auto" Content="Tự cập nhật nền (khi mở máy và mỗi 24 giờ, không hỏi)" Margin="0,0,0,8"/>
        <WrapPanel>
          <Button Name="BNow" Content="&#11014; Cập nhật ngay" Padding="12,5" Margin="0,0,8,6"/>
          <Button Name="BPrev" Content="&#8617; Quay về bản trước" Padding="12,5" Margin="0,0,8,6"/>
          <ComboBox Name="VerBox" Width="230" Margin="0,0,8,6" VerticalContentAlignment="Center"/>
          <Button Name="BDown" Content="&#11015; Hạ cấp về bản chọn" Padding="12,5" Margin="0,0,8,6"/>
          <Button Name="BRef" Content="&#8635; Làm mới" Padding="12,5" Margin="0,0,8,6"/>
        </WrapPanel>
      </StackPanel>
    </Border>
    <Border Grid.Row="2" Margin="0,10,0,0" Padding="14" CornerRadius="16" Background="#CCFFFFFF" BorderBrush="#B9D9FF" BorderThickness="1.5">
      <Grid>
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <TextBlock Text="Các app trong kho (chỉ đọc: cài, cập nhật, hạ cấp)" FontWeight="Bold" FontSize="15" Margin="0,0,0,8"/>
        <ListView Name="Grid" Grid.Row="1" SelectionMode="Single">
          <ListView.View><GridView>
            <GridViewColumn Header="App" Width="300" DisplayMemberBinding="{Binding Name}"/>
            <GridViewColumn Header="Đang cài" Width="120" DisplayMemberBinding="{Binding Cur}"/>
            <GridViewColumn Header="Mới nhất" Width="120" DisplayMemberBinding="{Binding Latest}"/>
            <GridViewColumn Header="Trạng thái" Width="200" DisplayMemberBinding="{Binding Status}"/>
          </GridView></ListView.View>
        </ListView>
        <WrapPanel Grid.Row="2" Margin="0,8,0,0">
          <Button Name="BSInst" Content="&#128230; Cài / Cập nhật app chọn" Padding="12,5" Margin="0,0,8,0"/>
          <Button Name="BSAll" Content="&#11014; Cập nhật tất cả" Padding="12,5" Margin="0,0,8,0"/>
          <Button Name="BSDown" Content="&#11015; Hạ cấp app chọn..." Padding="12,5" Margin="0,0,8,0"/>
        </WrapPanel>
      </Grid>
    </Border>
    <TextBox Name="LogBox" Grid.Row="3" Margin="0,10,0,0" IsReadOnly="True" FontFamily="Consolas" FontSize="12" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap"/>
  </Grid>
</Window>
'@
$script:win = [System.Windows.Markup.XamlReader]::Parse($xaml)
foreach ($n in 'AppInfo', 'Auto', 'BNow', 'BPrev', 'VerBox', 'BDown', 'BRef', 'Grid', 'BSInst', 'BSAll', 'BSDown', 'LogBox') { Set-Variable -Scope Script -Name ('w' + $n) -Value $script:win.FindName($n) }
$script:wLog = $script:wLogBox
$script:wAuto.Add_Click({ Set-AutoUpdate ([bool]$script:wAuto.IsChecked); Log $(if ($script:wAuto.IsChecked) { 'Đã bật tự cập nhật nền.' } else { 'Đã tắt tự cập nhật nền (vẫn có thể cập nhật bằng tay).' }) })
$script:wBNow.Add_Click({ Act-UpdateNow })
$script:wBPrev.Add_Click({ Act-Rollback $true })
$script:wBDown.Add_Click({ Act-Rollback $false })
$script:wBRef.Add_Click({ Refresh-App; Refresh-Store })
$script:wBSInst.Add_Click({ Act-StoreInstall })
$script:wBSAll.Add_Click({ Act-StoreAll })
$script:wBSDown.Add_Click({ Act-StoreRollback })
$script:win.Add_ContentRendered({ Refresh-App; Refresh-Store })
[void]$script:win.ShowDialog()
