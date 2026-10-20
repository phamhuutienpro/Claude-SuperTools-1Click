# Dong goi thanh Setup.exe (tu giai nen + chay trinh cai dat). Khong can cong cu ngoai: dung csc.exe co san cua .NET Framework.
param([string]$OutDir = (Join-Path $PSScriptRoot 'dist'))
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$ver = (Get-Content (Join-Path $root 'tools\VERSION') -Raw).Trim()
if ($ver -notmatch '^\d+\.\d+\.\d+$') { throw "VERSION khong hop le: $ver" }
$csc = @("$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe", "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $csc) { throw 'Khong tim thay csc.exe (.NET Framework 4).' }
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$work = Join-Path $env:TEMP ("scc-build-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $work | Out-Null

# 1) payload.zip (ten muc dung dau '/')
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$payload = Join-Path $work 'payload.zip'
$fs = [IO.File]::Open($payload, 'Create')
$zip = New-Object IO.Compression.ZipArchive($fs, [IO.Compression.ZipArchiveMode]::Create)
$include = @('Cai-Dat-1-Click.ps1', 'Cai-Dat-1-Click.cmd', 'PROMPT_HUB.md', 'HDSD_Cai_Dat.txt', 'INSTALL_PROMPT.md')
foreach ($f in $include) { $p = Join-Path $root $f; if (Test-Path $p) { [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $p, $f) } }
Get-ChildItem (Join-Path $root 'tools') -Recurse -File | Where-Object { $_.FullName -notmatch 'chibi-src' } | ForEach-Object {
    $rel = 'tools/' + $_.FullName.Substring((Join-Path $root 'tools').Length + 1).Replace('\', '/')
    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $rel)
}
$zip.Dispose(); $fs.Dispose()

# 2) icon tu chibi-heart.png
Add-Type -AssemblyName System.Drawing
$ico = Join-Path $work 'app.ico'
$png = Join-Path $root 'tools\chibi-heart.png'
$src = New-Object System.Drawing.Bitmap($png)
$bmp = New-Object System.Drawing.Bitmap($src, 48, 48)
$icon = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
$st = [IO.File]::Create($ico); $icon.Save($st); $st.Close()

# 3) bien dich
$cs = (Get-Content (Join-Path $root 'build\Setup.cs') -Raw -Encoding UTF8).Replace('AssemblyVersion("0.0.0.0")', "AssemblyVersion(`"$ver.0`")")
$csFile = Join-Path $work 'Setup.cs'
[IO.File]::WriteAllText($csFile, $cs, (New-Object Text.UTF8Encoding $true))
$out = Join-Path $OutDir 'SieuCongCuClaudeCode-Setup.exe'
& $csc /nologo /target:winexe "/out:$out" "/win32icon:$ico" "/resource:$payload,payload.zip" /reference:System.Windows.Forms.dll /reference:System.IO.Compression.dll /reference:System.IO.Compression.FileSystem.dll $csFile
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $out)) { throw 'Bien dich that bai.' }
Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
$sha = (Get-FileHash $out -Algorithm SHA256).Hash
Set-Content (Join-Path $OutDir 'SieuCongCuClaudeCode-Setup.exe.sha256') "$sha  SieuCongCuClaudeCode-Setup.exe" -Encoding ASCII
"OK $out ($([math]::Round((Get-Item $out).Length/1KB)) KB) v$ver SHA256=$sha"
