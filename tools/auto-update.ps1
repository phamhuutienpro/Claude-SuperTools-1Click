# Cap nhat / ha cap Sieu Cong Cu Claude Code. Chay nen khong hoi nguoi dung; co che do thu cong (-Force) va ha cap (-Rollback).
# Chi tin nguon: github.com/phamhuutienpro/Claude-SuperTools-1Click (nhanh main da qua kiem tra; the vX.Y.Z).
param(
    [string]$RemoteBase = 'https://raw.githubusercontent.com/phamhuutienpro/Claude-SuperTools-1Click/main/tools',
    [string]$ZipUrl = 'https://github.com/phamhuutienpro/Claude-SuperTools-1Click/archive/refs/heads/main.zip',
    [string]$TagZipBase = 'https://github.com/phamhuutienpro/Claude-SuperTools-1Click/archive/refs/tags',
    [string]$ClaudeDir = '',
    [switch]$Force,        # cap nhat thu cong: bo qua tat/ghim, bo ghim
    [switch]$Rollback,     # ha cap
    [string]$To = '',      # ban muon ha cap ve, vi du 1.1.0 (mac dinh: ban truoc)
    [switch]$ListVersions, # in JSON cac ban co san
    [switch]$NoRestart
)
try { [Console]::OutputEncoding = New-Object Text.UTF8Encoding $false } catch {}
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$log = Join-Path $env:TEMP 'sieucongcu-update.log'
function Log($m) { try { Add-Content -Path $log -Value ("{0} {1}" -f (Get-Date -Format s), $m) } catch {} }
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Keep = 3
if (-not $ClaudeDir) { $ClaudeDir = Join-Path $env:USERPROFILE '.claude' }
$tools = Join-Path $ClaudeDir 'tools'
$snapDir = Join-Path $ClaudeDir 'versions\Claude-SuperTools-1Click'
$stateDir = Join-Path $env:LOCALAPPDATA 'PromptSpotlight'
$stateFile = Join-Path $stateDir 'update-state.json'

function Get-State {
    $s = @{ autoUpdate = $true; pinned = '' }
    if (Test-Path $stateFile) { try { $o = Get-Content -Raw -Encoding UTF8 $stateFile | ConvertFrom-Json; if ($null -ne $o.autoUpdate) { $s.autoUpdate = [bool]$o.autoUpdate }; if ($o.pinned) { $s.pinned = [string]$o.pinned } } catch {} }
    $s
}
function Set-State($s) {
    if (-not (Test-Path $stateDir)) { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null }
    [IO.File]::WriteAllText($stateFile, (ConvertTo-Json $s), (New-Object Text.UTF8Encoding $false))
}
function Web { $w = New-Object System.Net.WebClient; $w.Encoding = [Text.Encoding]::UTF8; $w.Headers['User-Agent'] = 'SieuCongCu-Updater'; $w }
function Local-Version { $f = Join-Path $tools 'VERSION'; if (Test-Path $f) { try { [version]((Get-Content $f -Raw).Trim()) } catch { [version]'0.0.0' } } else { [version]'0.0.0' } }
function Remote-Version {
    $t = $null
    if ($RemoteBase -match '^https://raw\.githubusercontent\.com/phamhuutienpro/Claude-SuperTools-1Click/main/tools$') {
        # API khong bi CDN giu cache nhu raw.githubusercontent.com
        try {
            $t = [string](Invoke-RestMethod -Uri 'https://api.github.com/repos/phamhuutienpro/Claude-SuperTools-1Click/contents/tools/VERSION?ref=main' -Headers @{ 'User-Agent' = 'SieuCongCu-Updater'; 'Accept' = 'application/vnd.github.raw' } -TimeoutSec 12)
            $t = $t.Trim()
        } catch { $t = $null }
    }
    if (-not $t) {
        $sep = if ($RemoteBase -match '^https?:') { "?t=$([DateTime]::UtcNow.Ticks)" } else { '' }
        $t = ((Web).DownloadString("$RemoteBase/VERSION$sep")).Trim()
    }
    if ($t -notmatch '^\d+\.\d+\.\d+$') { throw "VERSION tu xa khong hop le: $t" }
    [version]$t
}
function Local-Snapshots { if (Test-Path $snapDir) { @(Get-ChildItem $snapDir -Filter *.zip | ForEach-Object { $_.BaseName } | Sort-Object { [version]$_ } -Descending) } else { @() } }
function Remote-Tags {
    try { @(Invoke-RestMethod -Uri 'https://api.github.com/repos/phamhuutienpro/Claude-SuperTools-1Click/tags?per_page=40' -Headers @{ 'User-Agent' = 'SieuCongCu-Updater' } -TimeoutSec 12 | ForEach-Object { $_.name -replace '^v', '' } | Where-Object { $_ -match '^\d+\.\d+\.\d+$' } | Sort-Object { [version]$_ } -Descending) } catch { @() }
}
function Snapshot-Current {
    $v = Local-Version
    if ($v -eq [version]'0.0.0' -or -not (Test-Path $tools)) { return }
    New-Item -ItemType Directory -Path $snapDir -Force | Out-Null
    $z = Join-Path $snapDir "$v.zip"
    if (-not (Test-Path $z)) { [IO.Compression.ZipFile]::CreateFromDirectory($tools, $z, [IO.Compression.CompressionLevel]::Optimal, $false) }
    else { (Get-Item $z).LastWriteTime = Get-Date }
    Get-ChildItem $snapDir -Filter *.zip | Sort-Object LastWriteTime -Descending | Select-Object -Skip $Keep | Remove-Item -Force -ErrorAction SilentlyContinue
    Log "snapshot $v"
}
function Write-Notice([string]$from, [string]$to, [string]$notes) {
    if (-not (Test-Path $stateDir)) { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null }
    [IO.File]::WriteAllText((Join-Path $stateDir 'update-notice.json'), (ConvertTo-Json @{ from = $from; to = $to; notes = $notes }), (New-Object Text.UTF8Encoding $false))
}
function Install-From-Zip([string]$zipUrl, [string]$expectVersion) {
    $tmp = Join-Path $env:TEMP ("scc-update-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    try {
        $zip = Join-Path $tmp 'src.zip'
        (Web).DownloadFile($zipUrl, $zip)
        [IO.Compression.ZipFile]::ExtractToDirectory($zip, (Join-Path $tmp 'x'))
        $inst = Get-ChildItem (Join-Path $tmp 'x') -Recurse -Filter 'Cai-Dat-1-Click.ps1' | Select-Object -First 1
        if (-not $inst) { throw 'Goi tai ve khong co Cai-Dat-1-Click.ps1' }
        $verFile = Join-Path $inst.DirectoryName 'tools\VERSION'
        if (-not (Test-Path $verFile) -or (Get-Content $verFile -Raw).Trim() -ne $expectVersion) { throw "Goi tai ve khong khop VERSION ($expectVersion), huy." }
        $a = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $inst.FullName, '-Update', '-ClaudeDir', $ClaudeDir)
        if ($NoRestart) { $a += '-NoPopup' }
        $p = Start-Process -FilePath 'powershell.exe' -ArgumentList $a -Wait -PassThru -WindowStyle Hidden
        if ($p.ExitCode -ne 0) { throw "Trinh cai dat loi ma $($p.ExitCode)" }
        $nf = Join-Path $inst.DirectoryName 'tools\RELEASE_NOTES.txt'
        if (Test-Path $nf) { ((Get-Content $nf -Encoding UTF8 | Select-Object -First 6) -join "`n") } else { '' }
    } finally { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
}

# ---- che do chi doc: liet ke phien ban ----
if ($ListVersions) {
    $st = Get-State
    $latest = ''; try { $latest = [string](Remote-Version) } catch {}
    $o = @{ current = [string](Local-Version); latest = $latest; pinned = $st.pinned; autoUpdate = $st.autoUpdate; local = @(Local-Snapshots); remote = @(Remote-Tags) }
    Write-Output (ConvertTo-Json $o -Compress)
    exit 0
}

$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, 'Local\SCCAutoUpdate', [ref]$createdNew)
if (-not $createdNew) { Log 'dang chay, bo qua'; exit 0 }

try {
    $st = Get-State
    $cur = Local-Version

    if ($Rollback) {
        $target = $To
        if (-not $target) { $target = (Local-Snapshots | Where-Object { [version]$_ -ne $cur } | Select-Object -First 1) }
        if (-not $target) { throw 'Khong co ban cu nao de ha cap.' }
        if ([version]$target -eq $cur) { throw "Dang o ban $target roi." }
        Snapshot-Current
        $snap = Join-Path $snapDir "$target.zip"
        if (Test-Path $snap) {
            Log "ha cap tu snapshot $target"
            Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like '*popup-host.ps1*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
            Start-Sleep -Milliseconds 800
            $tmp = Join-Path $env:TEMP ("scc-rb-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
            [IO.Compression.ZipFile]::ExtractToDirectory($snap, $tmp)
            Copy-Item -Path (Join-Path $tmp '*') -Destination $tools -Recurse -Force
            Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
            if (-not $NoRestart -and (Test-Path (Join-Path $tools 'Chay-Popup.cmd'))) { Start-Process (Join-Path $tools 'Chay-Popup.cmd') }
        } else {
            Log "ha cap tu GitHub v$target"
            [void](Install-From-Zip "$TagZipBase/v$target.zip" $target)
        }
        $st.pinned = $target; Set-State $st
        Write-Notice "$cur" $target "Da ha cap ve $target va ghim phien ban nay (tu cap nhat tam dung). Bam 'Cap nhat ngay' de len ban moi."
        Log "da ha cap $cur -> $target"
        exit 0
    }

    if (-not $Force) {
        if (-not $st.autoUpdate) { Log 'tu cap nhat dang tat'; exit 0 }
        if ($st.pinned) { Log "dang ghim ban $($st.pinned), bo qua cap nhat tu dong"; exit 0 }
    }
    $remote = Remote-Version
    Log "local=$cur remote=$remote force=$Force"

    if ($remote -gt $cur -or ($Force -and $st.pinned)) {
        Snapshot-Current
        $notes = Install-From-Zip $ZipUrl "$remote"
        $st.pinned = ''; Set-State $st
        Write-Notice "$cur" "$remote" $notes
        Log "da cap nhat len $remote"
    } elseif ($Force) { Log 'da la ban moi nhat' }

    # cac repo khach da cai tu kho
    $store = Join-Path $tools 'repo-store.ps1'
    if (Test-Path $store) {
        $o = & powershell -NoProfile -ExecutionPolicy Bypass -File $store update -All 2>&1 | Out-String
        Log ("repo-store: " + ($o -replace "\s+", ' ').Trim())
    }
} catch {
    Log "LOI: $_"
    exit 1
}
