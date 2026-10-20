param([switch]$NoPopup, [switch]$Update, [string]$ClaudeDir = "")
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
# ==============================================================================
# BỘ CÀI ĐẶT 1-CLICK TỰ ĐỘNG: CLAUDE CODE PROMPT HUB & SUPER TOOLS
# Tương thích 100% mọi máy tính Windows, mọi ổ đĩa, mọi User Profile
# ==============================================================================

$ErrorActionPreference = "Stop"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "   ⚡ CLAUDE CODE PROMPT & SUPER TOOLS - CÀI ĐẶT 1-CLICK TỰ ĐỘNG" -ForegroundColor Yellow
Write-Host "=====================================================================" -ForegroundColor Cyan

# 1. Xác định thư mục người dùng (%USERPROFILE%\.claude)
$userHome = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
$targetClaudeDir = if ($ClaudeDir) { $ClaudeDir } else { Join-Path $userHome ".claude" }
$targetToolsDir = Join-Path $targetClaudeDir "tools"
$targetKnowledgeDir = Join-Path $targetClaudeDir "knowledge"

Write-Host "[1/5] Thư mục đích: $targetClaudeDir" -ForegroundColor Green

# 2. Tạo các thư mục nếu chưa tồn tại
if (-not (Test-Path $targetToolsDir)) {
    New-Item -ItemType Directory -Path $targetToolsDir -Force | Out-Null
}
if (-not (Test-Path $targetKnowledgeDir)) {
    New-Item -ItemType Directory -Path $targetKnowledgeDir -Force | Out-Null
}

# 3. Sao chép toàn bộ công cụ từ thư mục 'tools'
$currentDir = $PSScriptRoot
$sourceTools = Join-Path $currentDir "tools"
if (-not (Test-Path $sourceTools)) { $sourceTools = $currentDir }

Write-Host "[2/5] Đang sao chép toàn bộ file (.cjs, .html, .json, .cmd, .md)..." -ForegroundColor Green

# Dung ban Popup cu dang chay de khong bi khoa file
Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*popup-host.ps1*" -or ($_.Name -eq "mshta.exe" -and $_.CommandLine -like "*prompt-spotlight.hta*") -or ($_.Name -eq "msedge.exe" -and $_.CommandLine -like "*PromptSpotlight*") } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep -Milliseconds 800

Get-ChildItem -Path $sourceTools -Recurse | Where-Object { -not $_.PSIsContainer -and $_.FullName -notmatch 'chibi-src' } | ForEach-Object {
    try {
        Copy-Item -Path $_.FullName -Destination $targetToolsDir -Force -ErrorAction Stop
        Write-Host "      + $($_.Name)" -ForegroundColor DarkGray
    } catch {
        Write-Host "      ! Bo qua $($_.Name) (dang duoc dung): $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Sao chép PROMPT_HUB.md vào gốc .claude
$promptHubMd = Join-Path $currentDir "PROMPT_HUB.md"
if (Test-Path $promptHubMd) {
    Copy-Item -Path $promptHubMd -Destination (Join-Path $targetClaudeDir "PROMPT_HUB.md") -Force
    Write-Host "[3/5] Đã sao chép PROMPT_HUB.md vào $targetClaudeDir" -ForegroundColor Green
}

# 4. Tự động thêm vào biến môi trường PATH của User
Write-Host "[4/5] Đang kiểm tra và cấu hình biến môi trường PATH..." -ForegroundColor Green
$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
$pathList = if ([string]::IsNullOrWhiteSpace($userPath)) { @() } else { $userPath -split ';' }

if (($pathList -notcontains $targetToolsDir) -and -not $ClaudeDir) {
    $newPath = if ([string]::IsNullOrWhiteSpace($userPath)) { $targetToolsDir } else { "$userPath;$targetToolsDir" }
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "      --> ĐÃ BỔ SUNG $targetToolsDir VÀO PATH USER THÀNH CÔNG!" -ForegroundColor Yellow
} else {
    Write-Host "      --> Đã có sẵn trong PATH." -ForegroundColor Gray
}

# 5. Cấu hình CLAUDE.md chuẩn hoá
Write-Host "[5/5] Cấu hình quy tắc và công cụ vào CLAUDE.md..." -ForegroundColor Green
$claudeMdPath = Join-Path $targetClaudeDir "CLAUDE.md"
$hubSnippet = @'

&nbsp;

## Global Agentic Super Tools Suite

&nbsp;

The system is equipped with global agentic tools located in `%USERPROFILE%\.claude\tools\` for browser automation, process management, and visual inspection:
- `cdp-browse <url>`: Chrome/Edge CDP inspection & UI freeze detector.
- `daemon-mgr <start|list|kill> [args]`: Background daemon process manager & port checker.
- `pkg-backup exe <file.js>`: Package your Node.js app into a standalone .exe.
- `repo-store <list|install|update|remove>`: Browse, install and update repos from the maintainer's store (read-only).
- `visual-diff <img1.png> <img2.png>`: Visual regression testing.
- `knowledge-hub <save|search> [args]`: Long-term solution persistence.
- `prompt-hub`: Opens Prompt Hub UI (default port 3900).

&nbsp;

Khởi chạy giao diện Prompt Hub (cổng mặc định 3900): gõ lệnh `prompt-hub` hoặc mở `%USERPROFILE%\.claude\tools\prompt-hub.html`.
Khi thực hiện giải pháp kỹ thuật, luôn đề xuất ý tưởng và hỏi lại 2 đợt để trao đổi, xác nhận.
'@

if (Test-Path $claudeMdPath) {
    $existing = Get-Content -Path $claudeMdPath -Raw -Encoding UTF8
    if (-not ($existing -match "prompt-hub")) {
        $updated = $existing + "`n" + $hubSnippet
        [System.IO.File]::WriteAllText($claudeMdPath, $updated, [System.Text.Encoding]::UTF8)
    }
} else {
    [System.IO.File]::WriteAllText($claudeMdPath, $hubSnippet.Trim(), [System.Text.Encoding]::UTF8)
}

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "   🎉 CÀI ĐẶT THÀNH CÔNG RỰC RỠ TRÊN MÁY TÍNH CỦA BẠN!" -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "Bây giờ bạn có thể:" -ForegroundColor White
Write-Host "1. Mở Prompt Hub bất cứ lúc nào bằng lệnh: prompt-hub" -ForegroundColor Yellow
Write-Host "2. Dùng cdp-browse, daemon-mgr, pkg-backup, knowledge-hub trực tiếp từ terminal." -ForegroundColor Yellow
Write-Host "3. Tự động mở giao diện Prompt Hub trong 2 giây..." -ForegroundColor Gray


Write-Host ""
Write-Host "SIEU CONG CU CLAUDE CODE (popup khong chiem con tro/focus van ban)" -ForegroundColor Magenta
# Don file cua ban cu (Edge/HTA da bo)
foreach ($old in "popup-ui.html", "Chay-Popup-Edge.cmd", "Chay-Popup-HTA.cmd", "Chay-Popup-WPF.cmd", "repo-store.cjs") {
    Remove-Item (Join-Path $targetToolsDir $old) -Force -ErrorAction SilentlyContinue
}
if (-not $NoPopup) {
    $startup = [Environment]::GetFolderPath("Startup")
    Get-ChildItem $startup -Filter "SieuCongCuClaudeCode*.lnk" -ErrorAction SilentlyContinue | Remove-Item -Force
    $ws = New-Object -ComObject WScript.Shell
    $lnk = $ws.CreateShortcut((Join-Path $startup "SieuCongCuClaudeCode.lnk"))
    $lnk.TargetPath = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
    $lnk.Arguments = "-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$(Join-Path $targetToolsDir 'popup-host.ps1')`""
    $lnk.WorkingDirectory = $targetToolsDir
    $lnk.WindowStyle = 7
    $lnk.Save()
    Write-Host "Da bat tu khoi dong cung Windows (tat bang icon tray -> Khoi dong cung Windows)." -ForegroundColor Green
    Start-Process (Join-Path $targetToolsDir "Chay-Popup.cmd")
    Write-Host "Da chay popup. Nhan Alt+Z de mo; dong cua so thi thu nho ve tray. Doi phim tat: nut 'Phim tat' trong popup hoac menu tray." -ForegroundColor Green
} else {
    if (-not $Update) {
        Start-Sleep -Seconds 2
        Start-Process (Join-Path $targetToolsDir "prompt-hub.html")
    }
}
