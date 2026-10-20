# ⚡ PROMPT & SKILL HUB - THƯ VIỆN PROMPT TỔNG QUÁT CHO CLAUDE CODE
*Cổng mạng mặc định 3900 · 3 Tùy chọn ngôn ngữ (VI / EN / Song Ngữ) · Tự động kèm 2 đợt hỏi xác nhận*

---

## 🎯 CÁC THAM SỐ NGỮ CẢNH TOÀN CỤC (GLOBAL CONTEXT VARIABLES)
Mọi prompt đều có thể tự động tiếp nhận hoặc thay thế 5 tham số động sau:
* `{port}`: Cổng mạng dịch vụ (mặc định: `3900`)
* `{status}`: Tình trạng hiện tại (ví dụ: `Đang chạy trên cổng 3900`, `Server khởi động nhưng lỗi EADDRINUSE`)
* `{requirement}`: Yêu cầu kỹ thuật (ví dụ: `Khắc phục triệt để và giữ nguyên logic code`)
* `{error}`: Mô tả lỗi (ví dụ: `Chưa thấy cửa sổ chat popup, lỗi cookie session`)
* `{purpose}`: Mục đích mong muốn (ví dụ: `Ứng dụng hoạt động mượt mà, ổn định`)

Mọi prompt xuất ra đều có cam kết đợt hỏi xác nhận cuối câu:
> **ĐỀ XUẤT Ý TƯỞNG, GIẢI PHÁP.**  
> **HỎI LẠI 2 đợt , mỗi đợt hỏi TÔI VÀI CÂU ĐỂ TRAO ĐỔI VÀ XÁC NHẬN.**

---

## 📑 BẢNG TRA CỨU NHANH THEO TRIỆU CHỨNG & TÌNH HUỐNG

| Tình huống / Triệu chứng gặp phải | Nhóm công cụ | Lệnh CLI tương ứng | Tên Prompt |
| :--- | :--- | :--- | :--- |
| **Giao diện bị đơ, không bấm được, CPU cao** | 🌐 Trình Duyệt | `cdp-browse <url>` | Chẩn đoán UI Freeze |
| **Trang trắng xoá, lỗi đỏ trong Console** | 🌐 Trình Duyệt | `cdp-browse <url>` | Bắt sạch Exceptions & Logs |
| **Kiểm tra giao diện mới & Chụp ảnh nghiệm thu** | 🌐 Trình Duyệt | `cdp-browse <url>` | Chụp ảnh màn hình nghiệm thu |
| **Chạy server ngầm không lo treo terminal** | ⚡ Tiến Trình Ngầm | `daemon-mgr start` | Khởi động Daemon Server |
| **Xung đột cổng mạng (EADDRINUSE / Port kẹt)** | ⚡ Tiến Trình Ngầm | `daemon-mgr list/kill`| Quét & Giải phóng cổng |
| **Đóng gói ứng dụng Node.js thành file .exe** | 📦 Đóng Gói | `pkg-backup exe <file.js>` | Tạo file .exe chạy độc lập |
| **Sợ sửa code làm vỡ bố cục giao diện** | 🖼️ So Sánh Thị Giác| `visual-diff` | So sánh ảnh trước/sau |
| **Giải quyết xong bug khó, muốn ghi nhớ vĩnh viễn**| 📚 Bộ Nhớ Dài Hạn | `knowledge-hub save` | Lưu bài học kinh nghiệm |
| **Muốn tìm lại cách giải quyết lỗi cũ** | 📚 Bộ Nhớ Dài Hạn | `knowledge-hub search`| Tra cứu giải pháp cũ |
| **Muốn tối ưu code sạch sẽ, giữ nguyên chú thích**| 🚀 Lập Trình Cặp | Core Refactor | Refactor mã nguồn an toàn |
| **Muốn sinh test tự chạy kiểm chứng logic** | 🚀 Lập Trình Cặp | Node Assert Test | Tự sinh Unit Test ca biên |

---

## 🌐 1. TRÌNH DUYỆT & BẮT BỆNH GIAO DIỆN (BROWSER CDP & UI FREEZE)

### Prompt 1.1: Chẩn đoán giao diện bị đơ cứng, không bấm được (UI Freeze)
* **Khi nào cần dùng:** Khi click vào nút bấm không ăn, trang web bị đơ, trình duyệt treo cứng hoặc nghi ngờ vòng lặp vô hạn, re-render liên tục.
* **Để làm gì:** Đo độ trễ Main Thread qua Chrome DevTools Protocol (CDP), định vị chính xác vị trí vòng lặp JavaScript gây nghẽn Event Loop và yêu cầu sửa dứt điểm.
* **Công cụ gọi:** `cdp-browse {url}`
* **🇻🇳 Phiên bản Tiếng Việt:**
```text
Giao diện web của tôi tại {url} đang bị đơ cứng, không click được nút nào cả. Tình trạng: {status}. Lỗi: {error}. Mục đích: {purpose}. Hãy dùng công cụ cdp-browse kiểm tra địa chỉ {url}, đọc file browser_diagnostic_report.md để tìm xem Main Thread bị kẹt ở file/hàm nào (như vòng lặp vô hạn, re-render liên tục hay bão MutationObserver) và sửa dứt điểm lỗi giúp tôi.

ĐỀ XUẤT Ý TƯỞNG, GIẢI PHÁP.
HỎI LẠI 2 đợt , mỗi đợt hỏi TÔI VÀI CÂU ĐỂ TRAO ĐỔI VÀ XÁC NHẬN.
```
* **⚡ Phiên bản Tiếng Anh (Tiết kiệm Token):**
```text
The web app at {url} is frozen and unresponsive. Current status: {status}. Error: {error}. Expected outcome: {purpose}. Run cdp-browse on {url}, inspect browser_diagnostic_report.md to diagnose event loop blockages (infinite loops or excessive re-renders), and fix the root cause.

PROPOSE IDEAS AND SOLUTIONS.
ASK ME IN 2 ROUNDS, EACH ROUND WITH A FEW QUESTIONS TO DISCUSS AND CONFIRM.
```
* **🌐 Phiên bản Song Ngữ:**
```text
Giao diện web tại {url} đang bị đơ cứng không phản hồi. Tình trạng: {status}. Lỗi: {error}. Mục đích: {purpose}. Hãy dùng cdp-browse kiểm tra {url}, đọc browser_diagnostic_report.md để xác định nguyên nhân nghẽn Event Loop và khắc phục triệt để.

[ENGLISH TOKEN SAVER]
The web app at {url} is frozen. Run cdp-browse, inspect browser_diagnostic_report.md for event loop blocks and fix the root cause.

ĐỀ XUẤT Ý TƯỞNG, GIẢI PHÁP.
HỎI LẠI 2 đợt , mỗi đợt hỏi TÔI VÀI CÂU ĐỂ TRAO ĐỔI VÀ XÁC NHẬN.
```

---

### Prompt 1.2: Bắt sạch ngoại lệ JavaScript & Lỗi đỏ Console
* **Khi nào cần dùng:** Khi trang web bị trắng trang, dữ liệu không hiển thị, hoặc sau khi code tính năng mới nghi ngờ có lỗi runtime (TypeError, ReferenceError...).
* **Để làm gì:** Thu thập toàn bộ Console Logs, Warnings và Uncaught Exceptions trực tiếp từ trình duyệt Chrome/Edge thật, chỉ ra đúng tên file và số dòng bị lỗi.
* **Công cụ gọi:** `cdp-browse {url}`
* **🇻🇳 Phiên bản Tiếng Việt:**
```text
Ứng dụng web tại {url} đang bị lỗi hiển thị hoặc trắng trang. Tình trạng: {status}. Lỗi: {error}. Hãy chạy chẩn đoán trình duyệt cdp-browse trên {url}, kiểm tra toàn bộ Exceptions và Console Logs trong báo cáo, sau đó định vị file code gây lỗi và sửa lại giúp tôi.

ĐỀ XUẤT Ý TƯỞNG, GIẢI PHÁP.
HỎI LẠI 2 đợt , mỗi đợt hỏi TÔI VÀI CÂU ĐỂ TRAO ĐỔI VÀ XÁC NHẬN.
```
* **⚡ Phiên bản Tiếng Anh (Tiết kiệm Token):**
```text
The app at {url} shows blank page or visual glitches. Status: {status}. Error: {error}. Run cdp-browse on {url}, check uncaught exceptions and console error logs, locate the offending source file, and fix it.

PROPOSE IDEAS AND SOLUTIONS.
ASK ME IN 2 ROUNDS, EACH ROUND WITH A FEW QUESTIONS TO DISCUSS AND CONFIRM.
```

---

### Prompt 1.3: Mở tab kiểm tra thị giác & Chụp ảnh nghiệm thu
* **Khi nào cần dùng:** Sau khi tạo mới một trang, route, component hoặc giao diện bất kỳ, cần kiểm tra giao diện mắt thường và lưu bằng chứng nghiệm thu.
* **Để làm gì:** Mở cửa sổ Chrome/Edge thật tại URL chỉ định, kiểm tra độ mượt mà, tự động chụp ảnh màn hình lưu vào `browser_diagnostic_screenshot.png` để nghiệm thu giao diện.
* **Công cụ gọi:** `cdp-browse {url}`
* **🇻🇳 Phiên bản Tiếng Việt:**
```text
Hãy mở trình duyệt kiểm tra trang {url} bằng cdp-browse. Yêu cầu: {requirement}. Hãy xem trang có phản hồi mượt mà không, chụp lại ảnh màn hình và báo cáo lại kết quả cho tôi nhé.

ĐỀ XUẤT Ý TƯỞNG, GIẢI PHÁP.
HỎI LẠI 2 đợt , mỗi đợt hỏi TÔI VÀI CÂU ĐỂ TRAO ĐỔI VÀ XÁC NHẬN.
```
* **⚡ Phiên bản Tiếng Anh (Tiết kiệm Token):**
```text
Open browser and inspect {url} using cdp-browse. Requirement: {requirement}. Verify smooth rendering, capture a screenshot to browser_diagnostic_screenshot.png, and report verification results.

PROPOSE IDEAS AND SOLUTIONS.
ASK ME IN 2 ROUNDS, EACH ROUND WITH A FEW QUESTIONS TO DISCUSS AND CONFIRM.
```

---

## ⚡ 2. SERVER & TIẾN TRÌNH NGẦM (DAEMON & PORT MONITORING)

### Prompt 2.1: Khởi động Server ngầm không lo treo terminal
* **Khi nào cần dùng:** Khi cần chạy dev server (như `npm run dev`, `npm start`, `vite`, `python app.py`) mà không muốn terminal của Claude Code bị chiếm dụng hoặc bị dừng khi tắt session.
* **Để làm gì:** Khởi chạy một lệnh server dưới dạng daemon tiến trình ngầm, lưu PID và ghi log, giúp terminal rảnh tay để tiếp tục gõ lệnh khác.
* **Công cụ gọi:** `daemon-mgr start "{command}"`
* **🇻🇳 Phiên bản Tiếng Việt:**
```text
Hãy dùng daemon-mgr chạy ngầm lệnh "{command}", sau đó kiểm tra xem cổng {port} đã lắng nghe thành công hay chưa và báo lại cho tôi. Yêu cầu: {requirement}.

ĐỀ XUẤT Ý TƯỞNG, GIẢI PHÁP.
HỎI LẠI 2 đợt , mỗi đợt hỏi TÔI VÀI CÂU ĐỂ TRAO ĐỔI VÀ XÁC NHẬN.
```
* **⚡ Phiên bản Tiếng Anh (Tiết kiệm Token):**
```text
Start background daemon for command "{command}" using daemon-mgr. Verify port {port} is actively listening. Requirement: {requirement}.

PROPOSE IDEAS AND SOLUTIONS.
ASK ME IN 2 ROUNDS, EACH ROUND WITH A FEW QUESTIONS TO DISCUSS AND CONFIRM.
```

---

### Prompt 2.2: Kiểm tra cổng mạng xung đột & Giải phóng cổng kẹt
* **Khi nào cần dùng:** Khi gặp lỗi `EADDRINUSE: address already in use` trên cổng `{port}` (mặc định: 3900, hoặc 5173, 8080...).
* **Để làm gì:** Liệt kê danh sách các tiến trình ngầm đang chạy, quét các cổng mạng thông dụng và giải phóng cổng (kill PID) nếu bị xung đột.
* **Công cụ gọi:** `daemon-mgr list`
* **🇻🇳 Phiên bản Tiếng Việt:**
```text
Cổng {port} đang có vẻ bị xung đột hoặc đã có tiến trình khác chiếm dụng (lỗi EADDRINUSE). Tình trạng: {status}. Hãy dùng daemon-mgr kiểm tra danh sách cổng đang mở, nếu cổng {port} bị kẹt thì hãy giải phóng cổng giúp tôi.

ĐỀ XUẤT Ý TƯỞNG, GIẢI PHÁP.
HỎI LẠI 2 đợt , mỗi đợt hỏi TÔI VÀI CÂU ĐỂ TRAO ĐỔI VÀ XÁC NHẬN.
```
* **⚡ Phiên bản Tiếng Anh (Tiết kiệm Token):**
```text
Port {port} is occupied or conflicting (EADDRINUSE). Status: {status}. Use daemon-mgr list to inspect active ports/PIDs and release port {port} cleanly.

PROPOSE IDEAS AND SOLUTIONS.
ASK ME IN 2 ROUNDS, EACH ROUND WITH A FEW QUESTIONS TO DISCUSS AND CONFIRM.
```

---

## 📦 3. ĐÓNG GÓI ỨNG DỤNG THÀNH FILE EXE

### Prompt 3.1: Đóng gói ứng dụng Node.js thành file .exe
* **Khi nào cần dùng:** Khi muốn gửi ứng dụng Node.js của mình cho người khác chạy mà không cần cài Node.js.
* **Công cụ gọi:** `pkg-backup exe "{entry}" "{out_file}"`

Hãy dùng pkg-backup exe {entry} {out_file} để đóng gói ứng dụng thành file .exe, kiểm tra file chạy được. Tình trạng: {status}. Mục đích: {purpose}.

---

## 🖼️ 4. SO SÁNH THỊ GIÁC & REGRESSION (VISUAL DIFF)

### Prompt 4.1: So sánh ảnh màn hình UI trước và sau khi sửa lỗi
* **Khi nào cần dùng:** Sau khi sửa code CSS, HTML, nâng cấp component hoặc refactor giao diện trong bất kỳ dự án web nào, cần xác nhận giao diện không bị lệch pixel, không bị vỡ bố cục.
* **Để làm gì:** So sánh 2 ảnh chụp màn hình UI (trước vs sau), tính toán tỷ lệ chênh lệch phần trăm kích thước khung hình và cảnh báo nếu có biến dạng bố cục.
* **Công cụ gọi:** `visual-diff "{before_img}" "{after_img}"`
* **🇻🇳 Phiên bản Tiếng Việt:**
```text
Hãy dùng visual-diff so sánh ảnh trước khi sửa ({before_img}) và ảnh sau khi sửa ({after_img}) để kiểm tra xem bố cục giao diện có bị vỡ hay thay đổi bất thường không.

ĐỀ XUẤT Ý TƯỞNG, GIẢI PHÁP.
HỎI LẠI 2 đợt , mỗi đợt hỏi TÔI VÀI CÂU ĐỂ TRAO ĐỔI VÀ XÁC NHẬN.
```
* **⚡ Phiên bản Tiếng Anh (Tiết kiệm Token):**
```text
Compare baseline UI screenshot {before_img} with modified screenshot {after_img} using visual-diff to verify visual layout integrity without regressions.

PROPOSE IDEAS AND SOLUTIONS.
ASK ME IN 2 ROUNDS, EACH ROUND WITH A FEW QUESTIONS TO DISCUSS AND CONFIRM.
```

---

## 📚 5. KHO TRI THỨC & BỘ NHỚ DÀI HẠN (KNOWLEDGE PERSISTENCE)

### Prompt 5.1: Lưu lại bài học sửa bug vào bộ nhớ dài hạn vĩnh viễn
* **Khi nào cần dùng:** Sau khi giải quyết xong bất kỳ bug khó, lỗi kiến trúc hoặc bài học kinh nghiệm nào trên bất kỳ dự án nào, muốn Claude Code ghi nhớ vĩnh viễn cho mọi dự án sau.
* **Để làm gì:** Lưu bài học kèm cách khắc phục vào kho tri thức toàn cầu `%USERPROFILE%\.claude\knowledge\lessons.jsonl` để tự động tái sử dụng.
* **Công cụ gọi:** `knowledge-hub save "{bug_title}" "{solution}"`
* **🇻🇳 Phiên bản Tiếng Việt:**
```text
Hãy dùng knowledge-hub lưu lại bài học kinh nghiệm: Lỗi "{bug_title}" và cách khắc phục: "{solution}" để ghi nhớ và tái sử dụng cho các dự án sau.

ĐỀ XUẤT Ý TƯỞNG, GIẢI PHÁP.
HỎI LẠI 2 đợt , mỗi đợt hỏi TÔI VÀI CÂU ĐỂ TRAO ĐỔI VÀ XÁC NHẬN.
```
* **⚡ Phiên bản Tiếng Anh (Tiết kiệm Token):**
```text
Save post-mortem lesson into global knowledge-hub: Issue "{bug_title}", Resolution: "{solution}".

PROPOSE IDEAS AND SOLUTIONS.
ASK ME IN 2 ROUNDS, EACH ROUND WITH A FEW QUESTIONS TO DISCUSS AND CONFIRM.
```

---

### Prompt 5.2: Tra cứu giải pháp cũ từ kho bài học kinh nghiệm
* **Khi nào cần dùng:** Khi gặp một lỗi lạ hoặc quen quen trong dự án mới, muốn kiểm tra xem trước đây mình hoặc Claude Code đã từng giải quyết lỗi tương tự chưa.
* **Để làm gì:** Tìm kiếm giải pháp nhanh trong kho bài học toàn cầu theo từ khóa, áp dụng ngay cách sửa đã được kiểm chứng thành công.
* **Công cụ gọi:** `knowledge-hub search "{keyword}"`
* **🇻🇳 Phiên bản Tiếng Việt:**
```text
Hãy tra cứu trong kho tri thức knowledge-hub xem trước đây chúng ta đã từng xử lý lỗi liên quan đến "{keyword}" chưa, và đưa ra giải pháp áp dụng cho dự án hiện tại.

ĐỀ XUẤT Ý TƯỞNG, GIẢI PHÁP.
HỎI LẠI 2 đợt , mỗi đợt hỏi TÔI VÀI CÂU ĐỂ TRAO ĐỔI VÀ XÁC NHẬN.
```
* **⚡ Phiên bản Tiếng Anh (Tiết kiệm Token):**
```text
Search knowledge-hub for existing resolutions matching keyword "{keyword}" and apply the verified solution to this current project.

PROPOSE IDEAS AND SOLUTIONS.
ASK ME IN 2 ROUNDS, EACH ROUND WITH A FEW QUESTIONS TO DISCUSS AND CONFIRM.
```

---

## 🚀 6. LẬP TRÌNH CẶP & CODE REFACTOR

### Prompt 6.1: Refactor mã nguồn an toàn & Giữ nguyên bình luận
* **Khi nào cần dùng:** Khi muốn làm sạch code trong bất kỳ dự án nào (TypeScript, JavaScript, Python, C++, Go...), code dài dòng hoặc trùng lặp mà không làm mất comment của tác giả.
* **Để làm gì:** Viết lại code sạch sẽ, tuân thủ nguyên tắc YAGNI, tối ưu hiệu năng, bảo toàn nguyên vẹn mọi comments và docstrings của tác giả.
* **🇻🇳 Phiên bản Tiếng Việt:**
```text
Hãy kiểm tra và refactor file {file}. Yêu cầu: {requirement}. Tối ưu hóa logic, giữ nguyên toàn bộ bình luận hiện có, không thêm abstraction dư thừa, đảm bảo mã nguồn chạy ổn định và ngắn gọn nhất.

ĐỀ XUẤT Ý TƯỞNG, GIẢI PHÁP.
HỎI LẠI 2 đợt , mỗi đợt hỏi TÔI VÀI CÂU ĐỂ TRAO ĐỔI VÀ XÁC NHẬN.
```
* **⚡ Phiên bản Tiếng Anh (Tiết kiệm Token):**
```text
Refactor {file}. Requirement: {requirement}. Optimize logic, preserve all existing developer comments and docstrings, avoid unnecessary abstractions, and keep code minimal and clean.

PROPOSE IDEAS AND SOLUTIONS.
ASK ME IN 2 ROUNDS, EACH ROUND WITH A FEW QUESTIONS TO DISCUSS AND CONFIRM.
```

---

### Prompt 6.2: Sinh kiểm thử tự động (Unit Test / Smoke Test) tự chạy
* **Khi nào cần dùng:** Khi vừa hoàn thành một hàm tính toán hoặc module logic quan trọng trong dự án, cần kiểm thử tất cả các ca biên (edge-cases) tự động.
* **Để làm gì:** Tạo một file test assert-based runnable cực nhẹ, chạy thử và kiểm chứng tất cả các case biên để đảm bảo không có bug ngầm.
* **🇻🇳 Phiên bản Tiếng Việt:**
```text
Hãy tạo một file kiểm thử runnable test độc lập cho file {file}. Viết các trường hợp test ca biên quan trọng dùng assert tiêu chuẩn (không cần cài framework nặng) và chạy thử ngay cho tôi xem kết quả. Yêu cầu: {requirement}.

ĐỀ XUẤT Ý TƯỞNG, GIẢI PHÁP.
HỎI LẠI 2 đợt , mỗi đợt hỏi TÔI VÀI CÂU ĐỂ TRAO ĐỔI VÀ XÁC NHẬN.
```
* **⚡ Phiên bản Tiếng Anh (Tiết kiệm Token):**
```text
Generate a standalone assert-based runnable test for {file} covering critical edge cases without external heavy frameworks. Execute it immediately and report results. Requirement: {requirement}.

PROPOSE IDEAS AND SOLUTIONS.
ASK ME IN 2 ROUNDS, EACH ROUND WITH A FEW QUESTIONS TO DISCUSS AND CONFIRM.
```

---
*Tài liệu này được đồng bộ tự động giữa `%USERPROFILE%\.claude\PROMPT_HUB.md` và dự án hiện tại.*
