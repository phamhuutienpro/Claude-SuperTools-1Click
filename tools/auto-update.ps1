# Tu dong cap nhat nen: kiem tra phien ban moi tren GitHub cua tac gia, tai ve va cai lai, khong hoi nguoi dung.
# Chi tin nguon: github.com/phamhuutienpro/Claude-SuperTools-1Click (nhanh main, da duoc kiem tra truoc khi phat hanh).
param(
    [string]$RemoteBase = 'https://raw.githubusercontent.com/phamhuutienpro/Claude-SuperTools-1Click/main/tools',
    [string]$ZipUrl = 'https://github.com/phamhuutienpro/Claude-SuperTools-1Click/archive/refs/heads/main.zip',
    [string]$ClaudeDir = '',
    [switch]$Force,
    [switch]$NoRestart
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$log = Join-Path $env:TEMP 'sieucongcu-update.log'
function Log($m) { try { Add-Content -Path $log -Value ("{0} {1}" -f (Get-Date -Format s), $m) } catch {} }

$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, 'Local\SCCAutoUpdate', [ref]$createdNew)
if (-not $createdNew) { Log 'dang chay, bo qua'; exit 0 }

try {
    if (-not $ClaudeDir) { $ClaudeDir = Join-Path $env:USERPROFILE '.claude' }
    $tools = Join-Path $ClaudeDir 'tools'
    $setFile = Join-Path $env:LOCALAPPDATA 'PromptSpotlight\settings.json'
    if (-not $Force -and (Test-Path $setFile)) {
        try { $s = Get-Content -Raw -Encoding UTF8 $setFile | ConvertFrom-Json; if ($null -ne $s.autoUpdate -and -not $s.autoUpdate) { Log 'tu cap nhat dang tat'; exit 0 } } catch {}
    }
    $wc = New-Object System.Net.WebClient
    $wc.Encoding = [Text.Encoding]::UTF8
    $wc.Headers['User-Agent'] = 'SieuCongCu-Updater'
    $stamp = [DateTime]::UtcNow.Ticks
    $sep = if ($RemoteBase -match '^https?:') { "?t=$stamp" } else { '' }
    $remoteText = ($wc.DownloadString("$RemoteBase/VERSION$sep")).Trim()
    if ($remoteText -notmatch '^\d+\.\d+\.\d+$') { throw "VERSION tu xa khong hop le: $remoteText" }
    $remote = [version]$remoteText
    $localFile = Join-Path $tools 'VERSION'
    $local = if (Test-Path $localFile) { try { [version]((Get-Content $localFile -Raw).Trim()) } catch { [version]'0.0.0' } } else { [version]'0.0.0' }
    Log "local=$local remote=$remote"

    if ($remote -gt $local -or $Force) {
        $tmp = Join-Path $env:TEMP ("scc-update-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
        New-Item -ItemType Directory -Path $tmp -Force | Out-Null
        $zip = Join-Path $tmp 'src.zip'
        $wc.DownloadFile($ZipUrl, $zip)
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [IO.Compression.ZipFile]::ExtractToDirectory($zip, (Join-Path $tmp 'x'))
        $inst = Get-ChildItem (Join-Path $tmp 'x') -Recurse -Filter 'Cai-Dat-1-Click.ps1' | Select-Object -First 1
        if (-not $inst) { throw 'Goi tai ve khong co Cai-Dat-1-Click.ps1' }
        $verFile = Join-Path $inst.DirectoryName 'tools\VERSION'
        if (-not (Test-Path $verFile) -or (Get-Content $verFile -Raw).Trim() -ne $remoteText) { throw 'Goi tai ve khong khop VERSION, huy cap nhat.' }
        $args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $inst.FullName, '-Update', '-ClaudeDir', $ClaudeDir)
        if ($NoRestart) { $args += '-NoPopup' }
        Log "cai ban $remoteText ..."
        $p = Start-Process -FilePath 'powershell.exe' -ArgumentList $args -Wait -PassThru -WindowStyle Hidden
        if ($p.ExitCode -ne 0) { throw "Trinh cai dat loi ma $($p.ExitCode)" }
        $notes = ''
        $nf = Join-Path $inst.DirectoryName 'tools\RELEASE_NOTES.txt'
        if (Test-Path $nf) { $notes = ((Get-Content $nf -Encoding UTF8 | Select-Object -First 6) -join "`n") }
        $nd = Split-Path $setFile
        if (-not (Test-Path $nd)) { New-Item -ItemType Directory -Path $nd -Force | Out-Null }
        [IO.File]::WriteAllText((Join-Path $nd 'update-notice.json'), (ConvertTo-Json @{ from = "$local"; to = $remoteText; notes = $notes }), (New-Object Text.UTF8Encoding $false))
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        Log "da cap nhat len $remoteText"
    }

    # cap nhat cac repo khach da cai tu kho (neu co node)
    $store = Join-Path $tools 'repo-store.cjs'
    if ((Test-Path $store) -and (Get-Command node -ErrorAction SilentlyContinue)) {
        $o = & node $store update --all 2>&1 | Out-String
        Log ("repo-store: " + ($o -replace "\s+", ' ').Trim())
    }
} catch {
    Log "LOI: $_"
    exit 1
}
