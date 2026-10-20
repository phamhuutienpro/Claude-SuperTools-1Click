# Prompt cài đặt tự động bằng AI IDE / One-shot install prompt

Copy toàn bộ khối bên dưới, dán vào AI IDE (Claude Code, Cursor, Windsurf, Antigravity, Copilot Chat...), thay dòng `LINK GITHUB` bằng link repo, rồi gửi.

Copy the whole block below into your AI IDE, replace the `LINK GITHUB` line with the repo link, and send.

---

```text
Bạn là trợ lý cài đặt. Hãy cài đặt giúp tôi dự án từ link GitHub dưới đây, tự làm hết các bước, không hỏi lại trừ khi gặp rủi ro được nêu trong phần "Giới hạn".

LINK GITHUB: https://github.com/phamhuutienpro/Claude-SuperTools-1Click

YÊU CẦU CHUNG
- Máy chạy Windows + PowerShell 5.1 (không dùng && hoặc ||, nối lệnh bằng ;).
- Cần có sẵn: git. Nếu thiếu git, cài bằng: winget install --id Git.Git -e. Nếu cần gh: winget install --id GitHub.cli -e.

CÁC BƯỚC
1. Kiểm tra môi trường: phiên bản Windows, PowerShell, git. Báo thiếu gì và tự cài phần thiếu.
2. Tải mã nguồn: clone link trên vào %USERPROFILE%\.claude\installed\<tên_repo>. Nếu thư mục đã tồn tại thì chạy git pull --rebase thay vì clone lại.
3. Đọc README.md của repo để biết cách cài chính thức. Nếu có file Cai-Dat-1-Click.ps1 thì chạy:
   powershell -NoProfile -ExecutionPolicy Bypass -File "<thư_mục_repo>\Cai-Dat-1-Click.ps1"
   Nếu không có, làm đúng theo README.
4. Nếu trình cài đặt có hỏi lựa chọn, chọn mặc định được khuyến nghị.
5. Kiểm tra sau khi cài, không chỉ tin vào thông báo thành công:
   - Các file công cụ đã có trong %USERPROFILE%\.claude\tools.
   - Nếu có popup / tiến trình nền: xác nhận tiến trình đang chạy và phím tắt mặc định hoạt động.
   - Nếu repo có Test-Tu-Dong.ps1: chạy powershell -NoProfile -ExecutionPolicy Bypass -File Test-Tu-Dong.ps1 và đọc kết quả.
6. Nếu có lỗi: đọc thông báo lỗi, tìm nguyên nhân gốc, sửa (ví dụ file đang bị khóa thì tắt tiến trình cũ rồi cài lại), chạy lại. Thử tối đa 3 lần rồi báo cáo rõ phần còn lỗi.

GIỚI HẠN (an toàn)
- Chỉ ghi vào %USERPROFILE%\.claude, thư mục Startup của Windows (shortcut khởi động cùng máy) và PATH của người dùng nếu README yêu cầu. Không đụng đến thư mục khác.
- Không commit, không push, không sửa mã nguồn của repo, không cài hook hay MCP server bên thứ ba.
- Trước khi chạy bất kỳ script nào, đọc nhanh nội dung để chắc nó đúng như mô tả trong README. Nếu thấy lệnh lạ (tải file từ nơi khác, gửi dữ liệu ra ngoài, xóa dữ liệu) thì DỪNG và báo tôi.
- Hỏi tôi trước khi xóa bất kỳ file nào của tôi.

BÁO CÁO CUỐI (song ngữ: một câu tiếng Anh, rồi câu tiếng Việt tương ứng)
- Đã cài những gì và ở đâu.
- Cách dùng nhanh (phím tắt, lệnh) theo README.
- Cách gỡ cài đặt.
- Những gì đã kiểm tra thật và những gì chưa kiểm tra.
```

---

## Bản tiếng Anh / English version

```text
You are an installation assistant. Install the project from the GitHub link below end to end, without asking me again unless you hit one of the risks listed under "Limits".

GITHUB LINK: https://github.com/phamhuutienpro/Claude-SuperTools-1Click

Environment: Windows + PowerShell 5.1 (no && or ||; chain with ;). Install git with winget if missing.

Steps:
1. Check Windows, PowerShell and git; install what is missing.
2. Clone the repo into %USERPROFILE%\.claude\installed\<repo>; if it exists, run git pull --rebase.
3. Read README.md. If Cai-Dat-1-Click.ps1 exists, run it with: powershell -NoProfile -ExecutionPolicy Bypass -File "<repo>\Cai-Dat-1-Click.ps1". Otherwise follow the README.
4. Accept recommended defaults in any prompt.
5. Verify for real: tools exist in %USERPROFILE%\.claude\tools; if a background app/hotkey exists, confirm it runs; if Test-Tu-Dong.ps1 exists, run it and read the result.
6. On error find the root cause, fix, re-run (max 3 attempts), then report what is still broken.

Limits: write only to %USERPROFILE%\.claude, the Windows Startup folder, and the user PATH if the README says so. Do not commit, push, edit the repo's source, or install third-party hooks/MCP servers. Read any script before running it; STOP and tell me if it downloads from elsewhere, sends data out, or deletes data. Ask before deleting any of my files.

Final report (one English sentence, then its Vietnamese equivalent): what was installed and where, quick usage, how to uninstall, and what was verified vs. not verified.
```
