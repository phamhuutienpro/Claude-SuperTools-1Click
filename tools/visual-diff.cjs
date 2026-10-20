#!/usr/bin/env node
const fs = require('fs');

const img1Path = process.argv[2];
const img2Path = process.argv[3];

if (!img1Path || !img2Path || !fs.existsSync(img1Path) || !fs.existsSync(img2Path)) {
  console.log('Cách dùng: visual-diff <anh_truoc.png> <anh_sau.png>');
  process.exit(1);
}

const s1 = fs.statSync(img1Path).size;
const s2 = fs.statSync(img2Path).size;
const sizeDiff = Math.abs(s1 - s2);
const percentDiff = ((sizeDiff / Math.max(s1, s2)) * 100).toFixed(2);

console.log('🖼️ So Sánh Khung Hình Trực Quan (Visual Diff):');
console.log(`  - Ảnh 1: ${img1Path} (${s1} bytes)`);
console.log(`  - Ảnh 2: ${img2Path} (${s2} bytes)`);
console.log(`  - Chênh lệch kích thước khung hình: ${sizeDiff} bytes (${percentDiff}%)`);

if (percentDiff < 1) {
  console.log('✅ Khung hình gần như đồng nhất (Không bị nhảy layout hoặc vỡ giao diện).');
} else {
  console.log(`ℹ️ Có sự thay đổi giao diện (${percentDiff}% chênh lệch). Hãy kiểm tra trực tiếp ảnh chụp.`);
}
