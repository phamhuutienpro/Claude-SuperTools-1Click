# repo-store: kho repo cua Tien cho khach. CHI DOC + cai + cap nhat + ha cap. Khong can git hay node.
param(
    [Parameter(Position = 0)][string]$Cmd = 'help',
    [Parameter(Position = 1)][string]$Id = '',
    [string]$Ref = '',
    [switch]$All, [switch]$Yes, [switch]$NoRun, [switch]$Json, [switch]$Latest
)
try { [Console]::OutputEncoding = New-Object Text.UTF8Encoding $false } catch {}
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$home_ = $env:USERPROFILE
$CatalogUrl = 'https://raw.githubusercontent.com/phamhuutienpro/Claude-SuperTools-1Click/main/tools/repo-catalog.json'
$Allowed = '^https://github\.com/phamhuutienpro/[A-Za-z0-9._-]+?(\.git)?$'
$InstalledDir = Join-Path $home_ '.claude\installed'
$VersionsDir = Join-Path $home_ '.claude\versions'
$Keep = 3

function Say($s) { Write-Output $s }
function Fail($s) { [Console]::Error.WriteLine("[LOI] $s"); exit 1 }
function Web { $w = New-Object System.Net.WebClient; $w.Encoding = [Text.Encoding]::UTF8; $w.Headers['User-Agent'] = 'repo-store'; $w }

function Get-Catalog {
    if ($env:REPO_STORE_CATALOG -and (Test-Path $env:REPO_STORE_CATALOG)) { return @(Get-Content -Raw -Encoding UTF8 $env:REPO_STORE_CATALOG | ConvertFrom-Json | ForEach-Object { $_ }) }
    try { return @((Web).DownloadString("$CatalogUrl?t=$([DateTime]::UtcNow.Ticks)") | ConvertFrom-Json | ForEach-Object { $_ }) } catch {}
    $local = Join-Path $PSScriptRoot 'repo-catalog.json'
    if (Test-Path $local) { return @(Get-Content -Raw -Encoding UTF8 $local | ConvertFrom-Json | ForEach-Object { $_ }) }
    @()
}
function Get-Slug($e) {
    if ($e.url -notmatch $Allowed) { Fail "Link khong hop le trong kho: $($e.url)" }
    ($e.url -replace '^https://github\.com/', '' -replace '\.git$', '')
}
function Gh($path) { Invoke-RestMethod -Uri "https://api.github.com/$path" -Headers @{ 'User-Agent' = 'repo-store' } -TimeoutSec 12 }
function Get-Tags($e) {
    try {
        $t = @(Gh "repos/$(Get-Slug $e)/tags?per_page=40" | ForEach-Object { $_.name })
        $ok = @($t | Where-Object { $_ -match '^v?\d+(\.\d+){1,3}$' })
        @($ok | Sort-Object { [version](($_ -replace '^v', '')) } -Descending)
    } catch { @() }
}
function Get-LatestRef($e) {
    $tags = Get-Tags $e
    if ($tags.Count) { return @{ ref = $tags[0]; sha = ''; kind = 'tag' } }
    try { $c = Gh "repos/$(Get-Slug $e)/commits/main"; return @{ ref = 'main'; sha = [string]$c.sha; kind = 'branch' } } catch { return @{ ref = 'main'; sha = ''; kind = 'branch' } }
}
function Dir-Of($e) { Join-Path $InstalledDir $e.id }
function Marker-Of($e) { Join-Path (Dir-Of $e) '.scc-version.json' }
function Read-Marker($e) { $m = Marker-Of $e; if (Test-Path $m) { try { Get-Content -Raw -Encoding UTF8 $m | ConvertFrom-Json } catch { $null } } else { $null } }
function Snap-Dir($e) { Join-Path $VersionsDir $e.id }
function Label-Of([string]$ref, [string]$sha) { if ($ref -eq 'main' -and $sha) { 'main-' + $sha.Substring(0, 7) } else { $ref } }
function Local-Versions($e) {
    $d = Snap-Dir $e
    if (-not (Test-Path $d)) { return @() }
    @(Get-ChildItem $d -Filter *.zip | Sort-Object LastWriteTime -Descending | ForEach-Object { $_.BaseName })
}
function Prune($e) {
    $d = Snap-Dir $e
    if (-not (Test-Path $d)) { return }
    Get-ChildItem $d -Filter *.zip | Sort-Object LastWriteTime -Descending | Select-Object -Skip $Keep | Remove-Item -Force -ErrorAction SilentlyContinue
}

function Get-RefZip($e, [string]$ref, [string]$dest) {
    $slug = Get-Slug $e
    $url = if ($ref -eq 'main') { "https://github.com/$slug/archive/refs/heads/main.zip" } else { "https://github.com/$slug/archive/refs/tags/$ref.zip" }
    (Web).DownloadFile($url, $dest)
}
function Install-Zip($e, [string]$zip, [string]$ref, [string]$sha, [bool]$pin) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $tmp = Join-Path $env:TEMP ('rs-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    [IO.Compression.ZipFile]::ExtractToDirectory($zip, $tmp)
    $root = @(Get-ChildItem $tmp -Directory)
    $src = if ($root.Count -eq 1 -and -not (Get-ChildItem $tmp -File)) { $root[0].FullName } else { $tmp }
    $dir = Dir-Of $e
    if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }
    New-Item -ItemType Directory -Path $InstalledDir -Force | Out-Null
    Move-Item $src $dir
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    $mk = @{ id = $e.id; ref = $ref; sha = $sha; installedAt = (Get-Date).ToString('s'); pinned = $pin }
    [IO.File]::WriteAllText((Marker-Of $e), (ConvertTo-Json $mk), (New-Object Text.UTF8Encoding $false))
}
function Run-Setup($e) {
    $dir = Dir-Of $e; $code = 0
    $inst = if ($e.installer) { Join-Path $dir $e.installer } else { '' }
    if ($inst -and (Test-Path $inst)) {
        Say "Chay trinh cai dat: $inst"
        $p = Start-Process powershell.exe -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $inst -WorkingDirectory $dir -Wait -PassThru -WindowStyle Hidden
        return $p.ExitCode
    }
    foreach ($s in @($e.setup)) {
        if (-not $s) { continue }
        if ($s.type -eq 'pip') {
            Say "Cai thu vien Python: $(@($s.packages) -join ' ')"
            $p = Start-Process python -ArgumentList (@('-m', 'pip', 'install', '--user') + @($s.packages)) -WorkingDirectory $dir -Wait -PassThru -WindowStyle Hidden
            if ($p.ExitCode) { $code = $p.ExitCode; Say 'Cai thu vien that bai. Kiem tra da cai Python chua (python.org).' }
        } elseif ($s.type -eq 'npm') {
            Say 'Chay npm install'
            $p = Start-Process cmd.exe -ArgumentList '/c', 'npm install' -WorkingDirectory $dir -Wait -PassThru -WindowStyle Hidden
            if ($p.ExitCode) { $code = $p.ExitCode }
        }
    }
    if (-not $inst -and -not @($e.setup).Count) { Say "Repo nay khong co trinh cai dat; chi tai ve. Xem README trong $dir" }
    if ($e.launch) { Say "Cach chay: cd `"$dir`" ; $($e.launch)" }
    $code
}
function Do-Install($e, [string]$ref, [bool]$pin) {
    if (-not $ref) { $l = Get-LatestRef $e; $ref = $l.ref; $sha = $l.sha } else { $sha = '' }
    if ($ref -eq 'main' -and -not $sha) { try { $sha = [string](Gh "repos/$(Get-Slug $e)/commits/main").sha } catch {} }
    $label = Label-Of $ref $sha
    New-Item -ItemType Directory -Path (Snap-Dir $e) -Force | Out-Null
    $zip = Join-Path (Snap-Dir $e) "$label.zip"
    if (-not (Test-Path $zip)) { Get-RefZip $e $ref $zip } else { (Get-Item $zip).LastWriteTime = Get-Date }
    Install-Zip $e $zip $ref $sha $pin
    Prune $e
    Say "Da cai $($e.id) phien ban $label"
    if (-not $NoRun) { [void](Run-Setup $e) }
}

function Status-Of($e, $cache) {
    $mk = Read-Marker $e
    $row = [ordered]@{ id = $e.id; name = $(if ($e.name_vi) { $e.name_vi } else { $e.name }); desc = $e.desc_vi; url = $e.url; installed = [bool]$mk; ref = ''; latest = ''; status = 'chua cai'; pinned = $false; local = @(Local-Versions $e); remote = @() }
    $l = Get-LatestRef $e
    $row.latest = Label-Of $l.ref $l.sha
    $row.remote = @(Get-Tags $e)
    if ($mk) {
        $row.ref = Label-Of $mk.ref $mk.sha; $row.pinned = [bool]$mk.pinned
        if ($mk.pinned) { $row.status = "da ghim ban $($row.ref)" }
        elseif ($row.ref -eq $row.latest -or ($l.ref -eq 'main' -and $mk.ref -eq 'main' -and (-not $l.sha -or $mk.sha -eq $l.sha))) { $row.status = 'moi nhat' }
        else { $row.status = "co ban moi ($($row.latest))" }
    }
    [pscustomobject]$row
}
function Find-Entry($cat, [string]$k) { $cat | Where-Object { $_.id -eq $k -or $_.name -eq $k } | Select-Object -First 1 }

$cat = @(Get-Catalog)
switch ($Cmd) {
    'list' {
        $rows = @($cat | ForEach-Object { Status-Of $_ })
        if ($Json) { Say (ConvertTo-Json -InputObject $rows -Depth 5 -Compress); break }
        Say "Kho repo ($($rows.Count))`n"
        foreach ($r in $rows) { Say ("{0,-26} {1}`n   {2} - {3}`n   {4}" -f $r.id, $r.status, $r.name, $r.desc, $r.url) }
    }
    'install' {
        $e = Find-Entry $cat $Id; if (-not $e) { Fail 'Khong co trong kho. Xem: repo-store list' }
        Do-Install $e $Ref ([bool]$Ref)
    }
    'update' {
        $targets = @(if ($All) { $cat | Where-Object { Read-Marker $_ } } else { Find-Entry $cat $Id | Where-Object { $_ } })
        if (-not $targets.Count) { if ($All) { Say 'Chua cai repo nao tu kho, khong co gi de cap nhat.'; break } Fail 'Dung: repo-store update <id> hoac -All' }
        foreach ($e in $targets) {
            $mk = Read-Marker $e
            if (-not $mk) { Say "$($e.id): chua cai, bo qua."; continue }
            if ($mk.pinned -and -not $Latest -and $All) { Say "$($e.id): dang ghim ban $($mk.ref), bo qua."; continue }
            $s = Status-Of $e
            if ($s.status -eq 'moi nhat' -and -not $Latest) { Say "$($e.id): da la ban moi nhat."; continue }
            Do-Install $e '' $false
        }
    }
    'versions' {
        $e = Find-Entry $cat $Id; if (-not $e) { Fail 'Khong co trong kho.' }
        $s = Status-Of $e
        if ($Json) { Say (ConvertTo-Json -InputObject $s -Depth 5 -Compress); break }
        Say "Dang cai: $($s.ref)  Moi nhat: $($s.latest)"; Say ('Co san tren may: ' + ($s.local -join ', ')); Say ('Tren GitHub: ' + ($s.remote -join ', '))
    }
    'rollback' {
        $e = Find-Entry $cat $Id; if (-not $e) { Fail 'Khong co trong kho.' }
        $mk = Read-Marker $e
        $target = $Ref
        if (-not $target) {
            $cur = if ($mk) { Label-Of $mk.ref $mk.sha } else { '' }
            $target = (Local-Versions $e | Where-Object { $_ -ne $cur } | Select-Object -First 1)
            if (-not $target) { Fail 'Khong co ban cu nao co san. Chon mot phien ban: repo-store versions <id>' }
        }
        $ref = $target; $sha = ''
        if ($target -match '^main-([0-9a-f]{7})$') { $ref = 'main'; $sha = $Matches[1] }
        New-Item -ItemType Directory -Path (Snap-Dir $e) -Force | Out-Null
        $zip = Join-Path (Snap-Dir $e) "$target.zip"
        if (-not (Test-Path $zip)) { Get-RefZip $e $ref $zip }
        Install-Zip $e $zip $ref $sha $true
        Say "Da ha cap $($e.id) ve $target (ghim, khong tu cap nhat). Cap nhat lai bang: repo-store update $($e.id) -Latest"
        if (-not $NoRun) { [void](Run-Setup $e) }
    }
    'remove' {
        $e = Find-Entry $cat $Id; if (-not $e) { Fail 'Khong co trong kho.' }
        if (-not $Yes) { Fail "Se xoa $(Dir-Of $e) (khong dung vao GitHub). Chay lai kem -Yes." }
        Remove-Item (Dir-Of $e) -Recurse -Force -ErrorAction SilentlyContinue; Say "Da xoa $(Dir-Of $e)"
    }
    default {
        Say @"
repo-store - kho repo cua Tien (khong can git/node)
  repo-store list [-Json]                 Xem repo, da cai / co ban moi
  repo-store install <id> [-Ref v1.0.0]   Cai (mac dinh ban moi nhat), chay trinh cai dat
  repo-store update <id>|-All [-Latest]   Cap nhat len ban moi nhat (-Latest: bo ghim)
  repo-store versions <id>                Xem ban co san (giu 3 ban gan nhat) va tren GitHub
  repo-store rollback <id> [-Ref ban]     Ha cap ve ban truoc (hoac ban chon); ghim ban do
  repo-store remove <id> -Yes             Xoa ban tai ve tren may
Cai vao: $InstalledDir ; ban luu: $VersionsDir
"@
    }
}
