#!/usr/bin/env node
// repo-store: Kho repo cua Tien danh cho khach. CHI DOC + cai + cap nhat. Khong co quyen sua/xoa GitHub cua ai.
const fs = require('fs');
const os = require('os');
const path = require('path');
const https = require('https');
const { spawnSync } = require('child_process');

const home = process.env.USERPROFILE || os.homedir();
const CATALOG_URL = 'https://raw.githubusercontent.com/phamhuutienpro/Claude-SuperTools-1Click/main/tools/repo-catalog.json';
const installedDir = path.join(home, '.claude', 'installed');
const localCatalog = path.join(__dirname, 'repo-catalog.json');
const ALLOWED = /^https:\/\/github\.com\/phamhuutienpro\/[A-Za-z0-9._-]+(\.git)?$/;

function run(cmd, args, cwd, opts) {
  const r = spawnSync(cmd, args, { cwd, encoding: 'utf8', shell: false, ...(opts || {}) });
  return { ok: r.status === 0, out: ((r.stdout || '') + (r.stderr || '')).trim() };
}
const git = (a, c) => run('git', a, c);
function fetchText(url) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { 'User-Agent': 'repo-store' } }, (res) => {
      if (res.statusCode !== 200) { res.resume(); return reject(new Error('HTTP ' + res.statusCode)); }
      let d = ''; res.setEncoding('utf8'); res.on('data', (x) => (d += x)); res.on('end', () => resolve(d));
    }).on('error', reject).setTimeout(8000, function () { this.destroy(new Error('timeout')); });
  });
}
async function loadCatalog() {
  if (process.env.REPO_STORE_CATALOG) { try { return { list: JSON.parse(fs.readFileSync(process.env.REPO_STORE_CATALOG, 'utf8')), src: 'file thu nghiem' }; } catch {} }
  try { return { list: JSON.parse(await fetchText(CATALOG_URL)), src: 'GitHub' }; } catch (e) {
    try { return { list: JSON.parse(fs.readFileSync(localCatalog, 'utf8')), src: 'ban kem theo (khong ket noi duoc GitHub)' }; } catch { return { list: [], src: 'trong' }; }
  }
}
const say = (s) => console.log(s);
const fail = (s) => { console.error('[LOI] ' + s); process.exit(1); };
const dirOf = (e) => path.join(installedDir, e.id);
const isInstalled = (e) => fs.existsSync(path.join(dirOf(e), '.git'));
function checkUrl(e) { if (!ALLOWED.test(e.url || '')) fail(`Link khong hop le trong kho: ${e.url}`); }

function behind(dir) {
  git(['fetch', '--quiet'], dir);
  const r = git(['rev-list', '--count', 'HEAD..@{u}'], dir);
  return r.ok ? parseInt(r.out, 10) || 0 : -1;
}
function runSetup(e, dir) {
  const inst = e.installer ? path.join(dir, e.installer) : '';
  if (inst && fs.existsSync(inst)) {
    say(`Chay trinh cai dat: ${inst}`);
    const r = spawnSync('powershell', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', inst], { cwd: dir, stdio: 'inherit' });
    return r.status || 0;
  }
  let code = 0;
  for (const s of e.setup || []) {
    if (s.type === 'pip') {
      say(`Cai thu vien Python: ${s.packages.join(' ')}`);
      const r = spawnSync('python', ['-m', 'pip', 'install', '--user', ...s.packages], { cwd: dir, stdio: 'inherit' });
      if (r.status) { code = r.status; say('Cai thu vien that bai. Kiem tra da cai Python chua (python.org).'); }
    } else if (s.type === 'npm') {
      say('Chay npm install');
      const r = spawnSync('npm', ['install'], { cwd: dir, stdio: 'inherit', shell: true });
      if (r.status) code = r.status;
    }
  }
  if (!inst && !(e.setup || []).length) say('Repo nay khong co trinh cai dat; chi tai ve. Xem README trong ' + dir);
  if (e.launch) say(`Cach chay: cd "${dir}" ; ${e.launch}`);
  return code;
}
(async () => {
  const [, , cmd = 'help', ...args] = process.argv;
  const noRun = args.includes('--no-run');
  const key = args.find((a) => !a.startsWith('--'));
  const cat = await loadCatalog();
  const find = (k) => cat.list.find((e) => e.id === k || e.name === k);

  switch (cmd) {
    case 'list': {
      say(`Kho repo (${cat.list.length}) - nguon: ${cat.src}\n`);
      cat.list.forEach((e) => {
        let st = 'chua cai';
        if (isInstalled(e)) { const b = behind(dirOf(e)); st = b > 0 ? `da cai - CO BAN MOI (${b} cap nhat)` : b === 0 ? 'da cai - moi nhat' : 'da cai'; }
        say(`${e.id.padEnd(26)} ${st}\n   ${e.name_vi || e.name} - ${e.desc_vi || ''}\n   ${e.url}`);
      });
      break;
    }
    case 'install': {
      const e = find(key); if (!e) fail('Khong co trong kho. Xem: repo-store list'); checkUrl(e);
      fs.mkdirSync(installedDir, { recursive: true });
      const dir = dirOf(e);
      if (isInstalled(e)) say('Da co ban cai; dung "repo-store update ' + e.id + '" de cap nhat.');
      else { const c = git(['clone', '--depth', '1', e.url, dir], process.cwd()); say(c.out); if (!c.ok) fail('Tai ve that bai.'); }
      say('Da tai ve ' + dir);
      if (!noRun) process.exit(runSetup(e, dir));
      break;
    }
    case 'update': {
      const targets = args.includes('--all') ? cat.list.filter(isInstalled) : [find(key)].filter(Boolean);
      if (!targets.length) { if (args.includes('--all')) { say('Chua cai repo nao tu kho, khong co gi de cap nhat.'); break; } fail('Khong co repo nao de cap nhat. Dung: repo-store update <id> hoac --all'); }
      for (const e of targets) {
        checkUrl(e);
        const dir = dirOf(e);
        if (!isInstalled(e)) { say(`${e.id}: chua cai, bo qua.`); continue; }
        if (git(['status', '--porcelain'], dir).out) { say(`${e.id}: ban da sua file trong thu muc cai, khong cap nhat de tranh mat du lieu: ${dir}`); continue; }
        const b = behind(dir);
        if (b === 0) { say(`${e.id}: da la ban moi nhat.`); continue; }
        const p = git(['pull', '--ff-only'], dir); say(`${e.id}: ${p.out.split('\n').pop()}`);
        if (p.ok && !noRun) runSetup(e, dir);
      }
      break;
    }
    case 'remove': {
      const e = find(key); if (!e) fail('Khong co trong kho.');
      if (!args.includes('--yes')) fail(`Se xoa thu muc cai ${dirOf(e)} (khong dung vao GitHub, khong go cong cu da chep vao .claude\\tools). Chay lai kem --yes.`);
      fs.rmSync(dirOf(e), { recursive: true, force: true }); say('Da xoa ' + dirOf(e));
      break;
    }
    default:
      say(`repo-store - kho repo cua Tien (chi doc, cai va cap nhat)
  repo-store list                  Xem repo trong kho va trang thai cai/cap nhat
  repo-store install <id> [--no-run]  Tai ve va chay trinh cai dat cua repo
  repo-store update <id>|--all [--no-run]  Lay ban moi (chi khi ban khong sua file)
  repo-store remove <id> --yes     Xoa ban tai ve tren may ban
Cai dat vao: ${installedDir}`);
  }
})();
