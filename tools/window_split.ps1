param([int]$HostW = 1280, [int]$GuestW = 640, [int]$H = 1080)
Add-Type @"
using System; using System.Runtime.InteropServices;
public class SZ2 {
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  public static IntPtr Find(uint pid) { IntPtr f = IntPtr.Zero; EnumWindows((h, l) => { uint p; GetWindowThreadProcessId(h, out p); RECT r; if (p == pid && IsWindowVisible(h) && GetClientRect(h, out r) && r.R > 200) { f = h; return false; } return true; }, IntPtr.Zero); return f; }
}
"@
$procs = Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue
$pH = $procs | Where-Object { $_.MainWindowTitle -match 'HOST' } | Select-Object -First 1
$pG = $procs | Where-Object { $_.MainWindowTitle -match 'GUEST' } | Select-Object -First 1
if ($pH) { $w1 = [SZ2]::Find([uint32]$pH.Id); [SZ2]::ShowWindow($w1, 9) | Out-Null; [SZ2]::SetWindowPos($w1, [IntPtr]::Zero, 0, 0, $HostW, $H, 0x0040) | Out-Null; "host  $($pH.Id) -> ${HostW}x${H} at 0,0" }
if ($pG) { $w2 = [SZ2]::Find([uint32]$pG.Id); [SZ2]::ShowWindow($w2, 9) | Out-Null; [SZ2]::SetWindowPos($w2, [IntPtr]::Zero, $HostW, 0, $GuestW, $H, 0x0040) | Out-Null; "guest $($pG.Id) -> ${GuestW}x${H} at $HostW,0" }
