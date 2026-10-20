#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const os = require("os");
const DB_FILE = path.join(os.homedir(), ".claude", "knowledge", "lessons.jsonl");

const action = process.argv[2] || 'search';

if (action === 'save') {
  const title = process.argv[3];
  const solution = process.argv[4];
  if (!title || !solution) {
    console.error('Cách dùng: knowledge-hub save "<Tên lỗi/bài học>" "<Cách khắc phục chi tiết>"');
    process.exit(1);
  }
  const item = {
    title,
    solution,
    timestamp: new Date().toISOString(),
    cwd: process.cwd()
  };
  const dir = path.dirname(DB_FILE);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.appendFileSync(DB_FILE, JSON.stringify(item) + '\n', 'utf8');
  console.log(`✅ Đã lưu bài học vào kho tri thức toàn cầu: "${title}"`);
} else if (action === 'search' || action === 'list') {
  const query = (process.argv[3] || '').toLowerCase();
  if (!fs.existsSync(DB_FILE)) {
    console.log('Kho tri thức hiện chưa có mục nào.');
    process.exit(0);
  }
  const lines = fs.readFileSync(DB_FILE, 'utf8').trim().split('\n').filter(Boolean);
  const items = lines.map(l => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
  const matched = query ? items.filter(it => it.title.toLowerCase().includes(query) || it.solution.toLowerCase().includes(query)) : items;

  console.log(`📚 Tìm thấy ${matched.length} bài học kinh nghiệm trong kho:`);
  matched.forEach((it, i) => {
    console.log(`\n[${i + 1}] ${it.title} (${it.timestamp.slice(0, 10)})`);
    console.log(`    💡 Giải pháp: ${it.solution.slice(0, 180)}...`);
  });
}
