#!/usr/bin/env node
// repo-hub: quan ly nhieu repo GitHub (them moi, dong bo, doi hien thi, doi ten, cai tu link).
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const home = process.env.USERPROFILE || os.homedir();
const regPath = path.join(home, '.claude', 'repos.json');
const ghCandidates = ['gh', path.join(process.env.ProgramFiles || 'C:\\Program Files', 'GitHub CLI', 'gh.exe')];

function run(cmd, args, cwd, opts = {}) {
  const r = spawnSync(cmd, args, { cwd, encoding: 'utf8', shell: false, ...opts });
  return { ok: r.status === 0, out: ((r.stdout || '') + (r.stderr || '')).trim(), code: r.status };
}
function git(args, cwd) { return run('git', args, cwd); }
function gh(args, cwd) {
  for (const c of ghCandidates) {
    const r = run(c, args, cwd);
    if (r.code !== null && !(r.out.includes('ENOENT'))) return r;
  }
  return { ok: false, out: 'Khong tim thay gh (GitHub CLI). Cai bang: winget install GitHub.cli' };
}

function load() {
  try { return JSON.parse(fs.readFileSync(regPath, 'utf8')); } catch { return { repos: [] }; }
}
function save(reg) {
  fs.mkdirSync(path.dirname(regPath), { recursive: true });
  fs.writeFileSync(regPath, JSON.stringify(reg, null, 2), 'utf8');
}
function flag(args, name) { const i = args.indexOf(name); if (i < 0) return null; const v = args[i + 1]; args.splice(i, v && !v.startsWith('--') ? 2 : 1); return v && !v.startsWith('--') ? v : true; }
function find(reg, key) {
  const abs = path.resolve(key || '.');
  return reg.repos.find((r) => r.name === key || path.resolve(r.path) === abs);
}
function register(reg, p) {
  const abs = path.resolve(p);
  const remote = git(['remote', 'get-url', 'origin'], abs).out;
  const name = path.basename(abs);
  const ex = reg.repos.find((r) => path.resolve(r.path) === abs);
  if (ex) { ex.remote = remote.startsWith('http') || remote.startsWith('git@') ? remote : ex.remote; return ex; }
  const item = { name, path: abs, remote: remote.startsWith('http') || remote.startsWith('git@') ? remote : '' };
  reg.repos.push(item);
  return item;
}
function ensureIdentity(cwd) {
  if (!git(['config', '--get-all', 'credential.https://github.com.helper'], cwd).out.includes('gh')) gh(['auth', 'setup-git'], cwd);
  if (!git(['config', 'user.name'], cwd).out) {
    const login = gh(['api', 'user', '--jq', '.login'], cwd);
    if (login.ok) git(['config', 'user.name', login.out], cwd);
  }
  if (!git(['config', 'user.email'], cwd).out) {
    const mail = gh(['api', 'user', '--jq', '.email // empty'], cwd);
    git(['config', 'user.email', mail.ok && mail.out ? mail.out : 'noreply@users.noreply.github.com'], cwd);
  }
}
function say(s) { console.log(s); }
function fail(s) { console.error('[LOI] ' + s); process.exit(1); }

const [, , cmd = 'help', ...rest] = process.argv;
const args = rest.slice();
const reg = load();

function statusLine(r) {
  if (!fs.existsSync(r.path)) return `${r.name.padEnd(28)} (khong con ton tai: ${r.path})`;
  const st = git(['status', '-sb', '--porcelain'], r.path).out.split('\n');
  const head = st[0] || '';
  const dirty = st.slice(1).filter(Boolean).length;
  const vis = r.remote ? '' : ' [chua co remote]';
  return `${r.name.padEnd(28)} ${head.replace('## ', '').padEnd(34)} thay doi: ${dirty}${vis}`;
}

switch (cmd) {
  case 'list': {
    if (!reg.repos.length) say('Chua co repo nao. Dung: repo-hub add <thu_muc>  hoac  repo-hub new <thu_muc>');
    reg.repos.forEach((r) => say(statusLine(r)));
    break;
  }
  case 'add': {
    const p = args[0] || '.';
    if (!fs.existsSync(path.join(p, '.git'))) fail('Thu muc nay chua phai repo git. Dung: repo-hub new <thu_muc>');
    const it = register(reg, p); save(reg);
    say(`Da dang ky: ${it.name} (${it.path}) ${it.remote}`);
    break;
  }
  case 'remove': {
    const r = find(reg, args[0]); if (!r) fail('Khong thay repo da dang ky.');
    reg.repos = reg.repos.filter((x) => x !== r); save(reg);
    say(`Da bo dang ky ${r.name} (khong xoa file, khong xoa tren GitHub).`);
    break;
  }
  case 'status': {
    const r = find(reg, args[0]) || { name: path.basename(path.resolve('.')), path: path.resolve('.'), remote: 'x' };
    say(statusLine(r));
    say(git(['status', '--short'], r.path).out || '(sach)');
    break;
  }
  case 'new': {
    const dir = path.resolve(args[0] || '.');
    const pub = !!flag(args, '--public');
    const name = flag(args, '--name') || path.basename(dir);
    const msg = flag(args, '-m') || 'Khoi tao repo';
    if (!fs.existsSync(dir)) fail('Thu muc khong ton tai: ' + dir);
    if (!fs.existsSync(path.join(dir, '.git'))) { const i = git(['init', '-b', 'main'], dir); if (!i.ok) fail(i.out); }
    ensureIdentity(dir);
    git(['add', '-A'], dir);
    const c = git(['commit', '-m', msg], dir);
    if (!c.ok && !/nothing to commit/.test(c.out)) fail(c.out);
    const r = gh(['repo', 'create', String(name), pub ? '--public' : '--private', '--source', dir, '--remote', 'origin', '--push'], dir);
    say(r.out);
    if (!r.ok) fail('Tao repo that bai.');
    register(reg, dir); save(reg);
    say(`Xong: ${pub ? 'PUBLIC' : 'PRIVATE'} - da dang ky ${name}`);
    break;
  }
  case 'sync': {
    const m = flag(args, '-m');
    const r = find(reg, args[0]) || { name: path.basename(path.resolve('.')), path: path.resolve('.') };
    ensureIdentity(r.path);
    git(['add', '-A'], r.path);
    const c = git(['commit', '-m', m || `Cap nhat ${new Date().toISOString().slice(0, 16).replace('T', ' ')}`], r.path);
    say(c.ok ? 'Da commit.' : 'Khong co thay doi moi de commit.');
    const pl = git(['pull', '--rebase'], r.path); if (!pl.ok && !/no tracking|up to date/i.test(pl.out)) say('pull: ' + pl.out);
    const ps = git(['push'], r.path); say(ps.ok ? 'Da push.' : 'push: ' + ps.out);
    break;
  }
  case 'visibility': {
    const r = find(reg, args[0]); const v = args[1];
    if (!r || !['public', 'private'].includes(v)) fail('Cach dung: repo-hub visibility <ten> public|private --yes');
    if (!args.includes('--yes')) fail(`Doi sang ${v.toUpperCase()} anh huong ai xem duoc code. Chay lai kem --yes de xac nhan.`);
    const out = gh(['repo', 'edit', '--visibility', v, '--accept-visibility-change-consequences'], r.path);
    say(out.out || `Da doi ${r.name} sang ${v}`);
    break;
  }
  case 'rename': {
    const r = find(reg, args[0]); const n = args[1];
    if (!r || !n) fail('Cach dung: repo-hub rename <ten> <ten_moi> --yes');
    if (!args.includes('--yes')) fail('Doi ten se doi link repo. Chay lai kem --yes de xac nhan.');
    const out = gh(['repo', 'rename', n, '--yes'], r.path); say(out.out);
    if (out.ok) { r.name = n; r.remote = git(['remote', 'get-url', 'origin'], r.path).out; save(reg); }
    break;
  }
  case 'clone': {
    const url = args[0]; if (!url) fail('Cach dung: repo-hub clone <link_github> [thu_muc]');
    const dir = path.resolve(args[1] || path.basename(url.replace(/\.git$/, '')));
    const r = git(['clone', url, dir], process.cwd()); say(r.out); if (!r.ok) fail('Clone that bai.');
    register(reg, dir); save(reg);
    break;
  }
  case 'install': {
    const url = args[0]; if (!url) fail('Cach dung: repo-hub install <link_github>');
    const dir = path.join(home, '.claude', 'installed', path.basename(url.replace(/\.git$/, '')));
    if (fs.existsSync(path.join(dir, '.git'))) { say('Da co ban cai, cap nhat...'); say(git(['pull', '--rebase'], dir).out); }
    else { fs.mkdirSync(path.dirname(dir), { recursive: true }); const c = git(['clone', url, dir], process.cwd()); say(c.out); if (!c.ok) fail('Clone that bai.'); }
    const inst = path.join(dir, 'Cai-Dat-1-Click.ps1');
    if (!fs.existsSync(inst)) { say('Khong co Cai-Dat-1-Click.ps1; xem README trong ' + dir); break; }
    const r = spawnSync('powershell', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', inst], { cwd: dir, stdio: 'inherit' });
    process.exit(r.status || 0);
  }
  default:
    say(`repo-hub - quan ly cac repo GitHub cua ban
  repo-hub list                              Liet ke repo da dang ky + trang thai
  repo-hub add [thu_muc]                     Dang ky repo da co
  repo-hub new <thu_muc> [--public] [--name N] [-m "noi dung"]
                                             Tao repo GitHub moi (mac dinh PRIVATE), commit va push
  repo-hub sync [ten] [-m "noi dung"]        add + commit + pull --rebase + push
  repo-hub status [ten]                      Xem thay doi chua commit
  repo-hub visibility <ten> public|private --yes
  repo-hub rename <ten> <ten_moi> --yes
  repo-hub clone <link> [thu_muc]            Clone va dang ky
  repo-hub install <link>                    Clone vao ~/.claude/installed va chay Cai-Dat-1-Click.ps1
  repo-hub remove <ten>                      Bo dang ky (khong xoa gi tren GitHub)
Danh sach luu o: ${regPath}`);
}
