#!/usr/bin/env node
const { execSync } = require('child_process');
const path = require('path');

const action = process.argv[2] || 'help';

if (action === 'exe') {
  const entry = process.argv[3];
  if (!entry) {
    console.error('Cách dùng: pkg-backup exe <file_vao.js> [ten_ung_dung.exe]');
    process.exit(1);
  }
  const out = process.argv[4] || path.basename(entry, path.extname(entry)) + '.exe';
  console.log(`📦 Đang đóng gói ${entry} thành ứng dụng: ${out}`);
  try {
    execSync(`npx -y @yao-pkg/pkg "${entry}" --targets node18-win-x64 --output "${out}"`, { stdio: 'inherit' });
    console.log(`✅ Đã tạo ứng dụng: ${out}`);
  } catch (err) {
    console.error('❌ Lỗi đóng gói:', err.message);
    process.exit(1);
  }
} else {
  console.log(`
Đóng gói ứng dụng Node.js của bạn thành file .exe chạy độc lập:
  pkg-backup exe <file_vao.js> [ten_ung_dung.exe]
`);
}