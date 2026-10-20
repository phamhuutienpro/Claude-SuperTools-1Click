---
name: repo-manager
description: Quản lý các repo GitHub của người dùng bằng repo-hub, git và gh. Dùng khi người dùng muốn thêm repo mới lên GitHub, đồng bộ/sửa/cập nhật repo hiện có, đổi Public/Private, đổi tên, clone, hoặc cài đặt một dự án từ link GitHub. Manage the user's GitHub repos (create, sync, visibility, rename, clone, install from a link).
---

# Repo Manager

Công cụ: `repo-hub` (trong `%USERPROFILE%\.claude\tools`), `git`, `gh` (GitHub CLI). Danh sách repo đã đăng ký lưu ở `%USERPROFILE%\.claude\repos.json`.

## Quy trình

1. **Xem hiện trạng trước**: `repo-hub list` rồi `repo-hub status <tên>`. Không đoán đường dẫn hay tên repo.
2. **Thêm repo mới**: kiểm tra thư mục không chứa bí mật (`.env`, token, khóa API, mật khẩu) bằng `git grep`/tìm file, rồi `repo-hub new <thư_mục>`. Mặc định **Private**.
3. **Cập nhật repo**: `repo-hub status` để xem thay đổi, đọc nhanh diff, rồi `repo-hub sync <tên> -m "mô tả ngắn"`.
4. **Cài từ link**: `repo-hub install <link>` (clone vào `%USERPROFILE%\.claude\installed\<repo>` và chạy `Cai-Dat-1-Click.ps1` nếu có), sau đó kiểm tra kết quả.
5. **Sửa repo hiện có**: sửa file trong thư mục repo, chạy test nếu có, rồi `sync`.

## Quy tắc an toàn

- **Hỏi lại người dùng trước khi**: chuyển sang Public (`repo-hub visibility <tên> public --yes`), đổi tên repo, force-push, xóa repo/nhánh, hoặc push lên repo không phải của họ.
- Không bao giờ commit file bí mật; nếu phát hiện, dừng và báo.
- Không dùng `--force`, `reset --hard`, `--no-verify` trừ khi người dùng yêu cầu rõ.
- Mỗi lần xong, báo cáo ngắn gọn: repo nào, thay đổi gì, link GitHub, và những gì chưa kiểm tra.
- Trả lời song ngữ (một câu tiếng Anh rồi câu tiếng Việt tương ứng) nếu người dùng đang dùng như vậy.

## Lệnh nhanh

```
repo-hub list
repo-hub new <thư_mục> [--public] [--name tên] [-m "nội dung"]
repo-hub sync [tên] [-m "nội dung"]
repo-hub visibility <tên> public|private --yes
repo-hub rename <tên> <tên_mới> --yes
repo-hub clone <link> [thư_mục]
repo-hub install <link>
```
