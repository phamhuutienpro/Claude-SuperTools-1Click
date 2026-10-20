#!/usr/bin/env node
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const os = require('os');

function findBrowserBinary() {
  const customPaths = [
    process.env.CHROME_BIN,
    process.env.EDGE_BIN
  ].filter(Boolean);
  for (const cp of customPaths) {
    if (fs.existsSync(cp)) return cp;
  }

  const baseDirs = [
    process.env['ProgramFiles'],
    process.env['ProgramFiles(x86)'],
    process.env['LOCALAPPDATA']
  ].filter(Boolean);

  const subPaths = [
    path.join('Google', 'Chrome', 'Application', 'chrome.exe'),
    path.join('Microsoft', 'Edge', 'Application', 'msedge.exe')
  ];

  for (const base of baseDirs) {
    for (const sub of subPaths) {
      const full = path.join(base, sub);
      if (fs.existsSync(full)) return full;
    }
  }

  // Check fallback drive letters C:, D:, E:
  const drives = ['C:', 'D:', 'E:', 'F:'];
  for (const drive of drives) {
    for (const rel of [
      'Program Files\\Google\\Chrome\\Application\\chrome.exe',
      'Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
      'Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
      'Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe'
    ]) {
      const full = path.join(drive, rel);
      if (fs.existsSync(full)) return full;
    }
  }
  return null;
}

const delay = ms => new Promise(r => setTimeout(r, ms));

class CDPClient {
  constructor(wsUrl) {
    this.wsUrl = wsUrl;
    this.ws = null;
    this.idCounter = 1;
    this.pending = new Map();
    this.eventListeners = new Map();
  }

  async connect() {
    return new Promise((resolve, reject) => {
      this.ws = new globalThis.WebSocket(this.wsUrl);
      this.ws.onopen = () => resolve();
      this.ws.onerror = (err) => reject(err);
      this.ws.onmessage = (event) => {
        try {
          const msg = JSON.parse(event.data);
          if (msg.id && this.pending.has(msg.id)) {
            const { resolve, reject } = this.pending.get(msg.id);
            this.pending.delete(msg.id);
            if (msg.error) reject(new Error(msg.error.message || JSON.stringify(msg.error)));
            else resolve(msg.result);
          } else if (msg.method) {
            const listeners = this.eventListeners.get(msg.method) || [];
            listeners.forEach(fn => fn(msg.params));
          }
        } catch (e) {}
      };
    });
  }

  on(method, callback) {
    if (!this.eventListeners.has(method)) this.eventListeners.set(method, []);
    this.eventListeners.get(method).push(callback);
  }

  send(method, params = {}, timeoutMs = 10000) {
    const id = this.idCounter++;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        if (this.pending.has(id)) {
          this.pending.delete(id);
          reject(new Error(`CDP command '${method}' timed out after ${timeoutMs}ms (Main Thread bị đơ/freeze)`));
        }
      }, timeoutMs);

      this.pending.set(id, {
        resolve: (res) => { clearTimeout(timer); resolve(res); },
        reject: (err) => { clearTimeout(timer); reject(err); }
      });

      this.ws.send(JSON.stringify({ id, method, params }));
    });
  }

  close() {
    if (this.ws) {
      try { this.ws.close(); } catch {}
    }
  }
}

async function main() {
  const args = process.argv.slice(2);
  const targetUrl = args.find(a => !a.startsWith('--')) || 'http://127.0.0.1:3900';
  const isHeadless = args.includes('--headless'); // Mặc định mở cửa sổ trực quan, chỉ headless khi có cờ

  const binary = findBrowserBinary();
  if (!binary) {
    console.error('❌ Không tìm thấy Chrome hoặc Edge trên máy.');
    process.exit(1);
  }

  const port = 9333 + Math.floor(Math.random() * 500);
  const userDataDir = path.join(os.tmpdir(), '.tmp_cdp_profile_' + port);

  console.log(`🚀 Trình duyệt: ${path.basename(binary)} (${isHeadless ? 'Headless' : 'Cửa sổ hiển thị trực tiếp'})`);
  console.log(`🌐 Mục tiêu: ${targetUrl}`);
  console.log(`🔌 Cổng CDP: ${port}`);

  const browserArgs = [
    `--remote-debugging-port=${port}`,
    '--disable-gpu',
    '--no-first-run',
    '--no-default-browser-check',
    `--user-data-dir=${userDataDir}`,
    targetUrl
  ];
  if (isHeadless) browserArgs.push('--headless=new');

  const browserProc = spawn(binary, browserArgs, { stdio: 'ignore', detached: false });

  const cleanup = () => {
    try { browserProc.kill(); } catch {}
    try { fs.rmSync(userDataDir, { recursive: true, force: true }); } catch {}
  };

  process.on('exit', cleanup);
  process.on('SIGINT', () => { cleanup(); process.exit(0); });

  // Đợi cổng CDP mở
  let versionData = null;
  for (let i = 0; i < 30; i++) {
    await delay(300);
    try {
      const res = await fetch(`http://127.0.0.1:${port}/json/version`);
      if (res.ok) {
        versionData = await res.json();
        break;
      }
    } catch {}
  }

  if (!versionData) {
    console.error('❌ Không thể kết nối CDP.');
    cleanup();
    process.exit(1);
  }

  const listRes = await fetch(`http://127.0.0.1:${port}/json/list`);
  const pages = await listRes.json();
  const page = pages.find(p => p.type === 'page') || pages[0];

  const cdp = new CDPClient(page.webSocketDebuggerUrl);
  await cdp.connect();

  const report = {
    url: targetUrl,
    browser: versionData.Browser,
    timestamp: new Date().toISOString(),
    consoleLogs: [],
    exceptions: [],
    isFrozen: false,
    freezeReason: null,
    metrics: {}
  };

  cdp.on('Runtime.consoleAPICalled', (params) => {
    const text = (params.args || []).map(a => a.value || a.description || '').join(' ');
    report.consoleLogs.push({ type: params.type, text });
    console.log(`  [Console ${params.type.toUpperCase()}] ${text.slice(0, 150)}`);
  });

  cdp.on('Runtime.exceptionThrown', (params) => {
    const desc = params.exceptionDetails?.exception?.description || params.exceptionDetails?.text || 'Unknown Error';
    report.exceptions.push(desc);
    console.log(`  [Exception] ⚠️ ${desc.slice(0, 150)}`);
  });

  await cdp.send('Page.enable');
  await cdp.send('Runtime.enable');
  await delay(2000);

  console.log('🔍 Kiểm tra độ trễ Main Thread (UI Freeze Starvation Test)...');
  const freezeStart = Date.now();
  try {
    const testResult = await cdp.send('Runtime.evaluate', {
      expression: `(() => ({
        title: document.title,
        url: window.location.href,
        elementsCount: document.querySelectorAll('*').length
      }))()`,
      returnByValue: true
    }, 4000);

    const latency = Date.now() - freezeStart;
    report.metrics = testResult.result?.value || {};
    report.metrics.roundtripLatencyMs = latency;

    if (latency > 1500) {
      report.isFrozen = true;
      report.freezeReason = `Phản hồi chậm: ${latency}ms!`;
      console.log(`⚠️ CẢNH BÁO: Phản hồi quá chậm (${latency}ms)`);
    } else {
      console.log(`✅ Main Thread mượt mà! Độ trễ phản hồi: ${latency}ms.`);
    }
  } catch (err) {
    report.isFrozen = true;
    report.freezeReason = `LỖI ĐƠ CỨNG: Timeout (${err.message}). Vòng lặp đệ quy chiếm 100% CPU.`;
    console.error(`🚨 PHÁT HIỆN LỖI ĐƠ GIAO DIỆN: ${report.freezeReason}`);
  }

  // Chụp ảnh màn hình
  try {
    console.log('📸 Đang chụp ảnh màn hình...');
    const ssRes = await cdp.send('Page.captureScreenshot', { format: 'png' }, 5000);
    if (ssRes.data) {
      const ssPath = path.join(process.cwd(), 'browser_diagnostic_screenshot.png');
      fs.writeFileSync(ssPath, Buffer.from(ssRes.data, 'base64'));
      report.screenshotSaved = ssPath;
      console.log(`✅ Đã lưu ảnh: ${ssPath}`);
    }
  } catch {}

  cdp.close();
  cleanup();

  const reportPath = path.join(process.cwd(), 'browser_diagnostic_report.md');
  const mdContent = `
# 📡 Báo Cáo Chẩn Đoán Trình Duyệt & Giao Diện
- **Thời gian:** ${report.timestamp}
- **URL:** \`${report.url}\`
- **Trạng thái:** ${report.isFrozen ? '🚨 **BỊ ĐƠ / FREEZE**' : '✅ **MƯỢT MÀ / RESPONSIVE**'}
- **Độ trễ Main Thread:** ${report.metrics?.roundtripLatencyMs || 'N/A'} ms

## 1. Ngoại Lệ JavaScript (Exceptions)
${report.exceptions.length === 0 ? '- *Không có ngoại lệ JS.*' : report.exceptions.map(e => `- ⚠️ \`${e}\``).join('\n')}

## 2. Console Logs
${report.consoleLogs.length === 0 ? '- *Không có log.*' : report.consoleLogs.map(c => `- **[${c.type.toUpperCase()}]** ${c.text}`).join('\n')}

## 3. Ảnh Chụp Màn Hình
${report.screenshotSaved ? `Đã lưu tại: \`${report.screenshotSaved}\`` : '*Không chụp được*'}
`.trim();

  fs.writeFileSync(reportPath, mdContent, 'utf-8');
  console.log(`📋 Báo cáo đã lưu: ${reportPath}`);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
