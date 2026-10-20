#!/usr/bin/env node
const { execSync, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const os = require("os");
const DAEMON_FILE = path.join(os.homedir(), ".claude", "daemon_registry.json");

function getRegistry() {
  try {
    if (fs.existsSync(DAEMON_FILE)) return JSON.parse(fs.readFileSync(DAEMON_FILE, 'utf8'));
  } catch {}
  return [];
}

function saveRegistry(reg) {
  const dir = path.dirname(DAEMON_FILE);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(DAEMON_FILE, JSON.stringify(reg, null, 2), 'utf8');
}

const action = process.argv[2] || 'list';

if (action === 'start') {
  const cmd = process.argv.slice(3).join(' ');
  if (!cmd) {
    console.error('Cách dùng: daemon-mgr start <lệnh>');
    process.exit(1);
  }
  console.log(`🚀 Đang khởi động ngầm: ${cmd}`);
  const child = spawn(cmd, { shell: true, detached: true, stdio: 'ignore' });
  child.unref();

  const reg = getRegistry();
  reg.push({ pid: child.pid, command: cmd, startTime: new Date().toISOString(), cwd: process.cwd() });
  saveRegistry(reg);
  console.log(`✅ Tiến trình đã khởi động trong nền (PID: ${child.pid})`);
} else if (action === 'list') {
  const reg = getRegistry();
  console.log('📋 Danh sách tiến trình ngầm đã đăng ký:');
  reg.forEach((item, idx) => {
    console.log(`  [${idx + 1}] PID: ${item.pid} | Lệnh: ${item.command} | Thư mục: ${item.cwd}`);
  });
  console.log('\n🔌 Kiểm tra các cổng thông dụng:');
  try {
    const netstat = execSync('netstat -ano | findstr "LISTENING"', { encoding: 'utf8' });
    ['3900', '7878', '8787', '3000', '5173'].forEach(port => {
      const line = netstat.split('\n').find(l => l.includes(`:${port}`));
      if (line) console.log(`  🟢 Port ${port} ĐANG LẮNG NGHE: ${line.trim()}`);
      else console.log(`  ⚪ Port ${port} Trống`);
    });
  } catch {}
} else if (action === 'kill') {
  const target = process.argv[3];
  if (!target) {
    console.error('Cách dùng: daemon-mgr kill <PID hoặc Port>');
    process.exit(1);
  }
  try {
    if (target.length < 6 && Number(target) > 0 && Number(target) < 65535) {
      // Tìm PID theo port
      const out = execSync(`netstat -ano | findstr ":${target}"`, { encoding: 'utf8' });
      const pids = new Set(out.split('\n').map(l => l.trim().split(/\s+/).pop()).filter(p => p && Number(p) > 0));
      pids.forEach(pid => {
        execSync(`taskkill /F /PID ${pid} /T`, { stdio: 'ignore' });
        console.log(`✅ Đã dừng PID ${pid} trên port ${target}`);
      });
    } else {
      execSync(`taskkill /F /PID ${target} /T`, { stdio: 'ignore' });
      console.log(`✅ Đã dừng PID ${target}`);
    }
  } catch (e) {
    console.log('⚠️ Không thể dừng tiến trình (có thể đã tắt):', e.message);
  }
}
