using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Windows.Forms;

[assembly: AssemblyTitle("Siêu Công Cụ Claude Code - Setup")]
[assembly: AssemblyProduct("Siêu Công Cụ Claude Code")]
[assembly: AssemblyDescription("Trình cài đặt 1-Click / One-click installer")]
[assembly: AssemblyVersion("0.0.0.0")]

static class Setup {
    const string Title = "Siêu Công Cụ Claude Code";

    [STAThread]
    static int Main(string[] args) {
        bool silent = false, noPopup = false; string claudeDir = "";
        foreach (string a in args) {
            string u = a.ToUpperInvariant();
            if (u == "/S" || u == "/SILENT") silent = true;
            else if (u == "/NOPOPUP") noPopup = true;
            else if (u.StartsWith("/CLAUDEDIR=")) claudeDir = a.Substring(11).Trim('"');
        }
        string ver = Assembly.GetExecutingAssembly().GetName().Version.ToString(3);
        if (!silent) {
            DialogResult r = MessageBox.Show(
                "Cài đặt " + Title + " v" + ver + " vào máy này?\n\nInstall " + Title + " v" + ver + " on this PC?\n\n• Chỉ ghi vào thư mục .claude của bạn và thư mục Startup.\n• Tự chạy khi mở máy, nhấn Alt+Z để mở.",
                Title, MessageBoxButtons.YesNo, MessageBoxIcon.Question);
            if (r != DialogResult.Yes) return 2;
        }
        string work = Path.Combine(Path.GetTempPath(), "SCC-Setup-" + Guid.NewGuid().ToString("N").Substring(0, 8));
        string log = Path.Combine(Path.GetTempPath(), "SCC-Setup.log");
        try {
            Directory.CreateDirectory(work);
            string zip = Path.Combine(work, "payload.zip");
            using (Stream s = Assembly.GetExecutingAssembly().GetManifestResourceStream("payload.zip"))
            using (FileStream f = File.Create(zip)) { s.CopyTo(f); }
            ZipFile.ExtractToDirectory(zip, Path.Combine(work, "x"));
            string ps1 = Path.Combine(work, "x", "Cai-Dat-1-Click.ps1");
            if (!File.Exists(ps1)) throw new FileNotFoundException("Thiếu Cai-Dat-1-Click.ps1 trong gói cài đặt.");
            string extra = (noPopup ? " -NoPopup" : "") + (claudeDir.Length > 0 ? " -ClaudeDir \"" + claudeDir + "\"" : "");
            ProcessStartInfo psi = new ProcessStartInfo("cmd.exe",
                "/c powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"" + ps1 + "\"" + extra + " > \"" + log + "\" 2>&1");
            psi.WorkingDirectory = Path.Combine(work, "x");
            psi.CreateNoWindow = true; psi.UseShellExecute = false;
            using (Process p = Process.Start(psi)) {
                p.WaitForExit();
                if (p.ExitCode != 0) {
                    if (!silent) MessageBox.Show("Cài đặt gặp lỗi (mã " + p.ExitCode + ").\nXem chi tiết: " + log, Title, MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return p.ExitCode;
                }
            }
            if (!silent) MessageBox.Show("Cài đặt xong! / Done!\n\nNhấn Alt+Z để mở popup. Popup tự cập nhật nền khi có bản mới.\nPress Alt+Z to open the popup; it updates itself in the background.", Title, MessageBoxButtons.OK, MessageBoxIcon.Information);
            return 0;
        } catch (Exception ex) {
            if (!silent) MessageBox.Show("Lỗi: " + ex.Message, Title, MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        } finally {
            try { Directory.Delete(work, true); } catch { }
        }
    }
}
