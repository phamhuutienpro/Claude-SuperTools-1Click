# 🌸 Siêu Công Cụ Claude Code · Quà 20/10

Bộ công cụ cho Claude Code trên Windows: một **popup nổi** chứa thư viện prompt, dán thẳng vào vị trí con trỏ đang gõ, kèm các công cụ dòng lệnh và trình quản lý repo GitHub.

A Windows toolkit for Claude Code: a **floating popup** with a prompt library that pastes right at your text cursor, plus CLI tools and a GitHub repo manager.

## ⚡ Cài đặt bằng AI (khuyên dùng) / Install with your AI IDE

Một dòng, không cần tải file trước (dán vào AI IDE):

```text
Đọc https://raw.githubusercontent.com/phamhuutienpro/Claude-SuperTools-1Click/main/INSTALL_PROMPT.md rồi làm đúng hướng dẫn trong đó để cài dự án https://github.com/phamhuutienpro/Claude-SuperTools-1Click cho tôi. Tự làm hết các bước, đọc script trước khi chạy, báo cáo song ngữ khi xong.
```

Hoặc Mở file [INSTALL_PROMPT.md](INSTALL_PROMPT.md), copy khối lệnh, dán vào AI IDE (Claude Code, Cursor, Windsurf, Antigravity...) kèm link repo này, AI sẽ tự cài, kiểm tra và báo cáo.

Open [INSTALL_PROMPT.md](INSTALL_PROMPT.md), copy the block into your AI IDE with the repo link, and it installs, verifies and reports by itself.

## 🖱️ Cài đặt thủ công / Manual install

```powershell
git clone https://github.com/phamhuutienpro/Claude-SuperTools-1Click.git
cd Claude-SuperTools-1Click
.\Cai-Dat-1-Click.cmd
```

Trình cài đặt sao chép công cụ vào `%USERPROFILE%\.claude\tools`, tạo shortcut khởi động cùng Windows và chạy popup. Cài không bật popup: `Cai-Dat-1-Click.ps1 -NoPopup`.

## ✨ Popup "Siêu Công Cụ Claude Code"

| Tính năng | Chi tiết |
|---|---|
| Mở / đóng | `Alt+Z` (mặc định, đổi được ở nút **Phím tắt** hoặc menu icon khay) |
| Dán vào con trỏ | Nhấp đôi một prompt: tự copy, đóng popup, trả focus và dán |
| Không chiếm con trỏ | Cửa sổ không giành focus; chỉ lấy focus khi bạn bấm vào ô nhập |
| Tham số | 5 ô dùng chung: Cổng, Tình trạng, Yêu cầu, Mô tả lỗi, Mục đích (được ghi nhớ) |
| Thư viện | 22 prompt chia tab: trình duyệt, server, so sánh giao diện, kho tri thức, lập trình, đóng gói, kho repo |
| Giao diện | Hồng (nhân vật nữ) / xanh (nhân vật nam) đổi bằng nút 🌈; chibi riêng cho từng prompt |
| Banner | 100 câu động lực VI/EN, đổi mỗi 120 giây |
| Hiệu ứng chuột | Vệt lấp lánh, nổ hạt khi bấm, thẻ phát sáng; tắt được ở ô **Hiệu ứng** |
| Khay hệ thống | Đóng cửa sổ chỉ thu nhỏ về khay; tự chạy khi mở máy; nhắc phím tắt mỗi giờ |

## 🛠️ Công cụ dòng lệnh / CLI tools

| Lệnh | Việc làm |
|---|---|
| `cdp-browse <url>` | Chẩn đoán trang web đơ, chụp ảnh, đọc lỗi console |
| `daemon-mgr start/list/kill` | Chạy server ngầm, xem cổng |
| `pkg-backup exe <file.js>` | Đóng gói app Node.js thành `.exe` |
| `visual-diff a.png b.png` | So sánh ảnh giao diện trước/sau |
| `knowledge-hub save/search` | Lưu và tra cứu bài học sửa lỗi |
| `repo-store ...` | Kho repo: xem, cài, cập nhật (xem bên dưới) |

## 🐙 Kho repo & cập nhật (cho người dùng)

Kho repo là danh sách các dự án của tác giả để bạn tự chọn cài và cập nhật. **Chỉ đọc**: bạn không có và không cần quyền sửa/xóa gì trên GitHub của tác giả. Cần `git` (không cần đăng nhập GitHub).

```powershell
repo-store list                       # repo trong kho + đã cài / có bản mới chưa
repo-store install <id>               # tải về và chạy trình cài đặt của repo đó
repo-store update <id>                # lấy bản mới (bỏ qua nếu bạn đã sửa file, không ghi đè)
repo-store update --all               # cập nhật tất cả repo đã cài
repo-store remove <id> --yes          # xóa bản tải về trên máy bạn
```

Trong popup có tab **Kho Repo & Cập Nhật** với 3 prompt tương ứng để nhờ AI làm giúp. Repo được tải về `%USERPROFILE%\.claude\installed\<id>`. Kho chỉ chấp nhận link thuộc `github.com/phamhuutienpro`.
## 📁 Cấu trúc

```
Cai-Dat-1-Click.cmd/.ps1   trình cài đặt
INSTALL_PROMPT.md          prompt cài đặt bằng AI
Test-Tu-Dong.ps1           kiểm thử tự động popup
tools/popup-host.ps1       popup WPF + phím tắt + khay hệ thống
tools/prompts_library.json thư viện prompt
tools/quotes.json          100 câu động lực
tools/repo-catalog.json     danh sách repo trong kho
tools/repo-store.cjs       kho repo (cài và cập nhật)
tools/chibi-*.png          nhân vật (nguồn SVG trong tools/chibi-src)
```

## 🧪 Kiểm thử

```powershell
powershell -ExecutionPolicy Bypass -File Test-Tu-Dong.ps1
```

Kiểm tra: popup hiện bằng phím tắt, giữ focus ô nhập, nhấp đôi dán đúng nội dung.

## 🗑️ Gỡ cài đặt

Chuột phải icon khay → **Thoát**; xóa shortcut `SieuCongCuClaudeCode.lnk` trong `shell:startup`; xóa các file trong `%USERPROFILE%\.claude\tools` nếu muốn.

## Lưu ý / Notes

- Nhân vật chibi vẽ bằng SVG, con trỏ chibi chỉ đổi trong cửa sổ popup.
- `Win+Z` do Windows chiếm nên không dùng làm phím tắt mặc định.
