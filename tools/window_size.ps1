param([int]$W = 1280, [int]$H = 720)
Add-Type @"
using System; using System.Runtime.InteropServices;
public class SZ {
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
if ($pH) { $w1 = [SZ]::Find([uint32]$pH.Id); [SZ]::ShowWindow($w1, 9) | Out-Null; [SZ]::SetWindowPos($w1, [IntPtr]::Zero, 0, 0, $W, $H, 0x0040) | Out-Null; "host  $($pH.Id) -> ${W}x${H} at 0,0" }
if ($pG) { $w2 = [SZ]::Find([uint32]$pG.Id); [SZ]::ShowWindow($w2, 9) | Out-Null; [SZ]::SetWindowPos($w2, [IntPtr]::Zero, $W, 0, $W, $H, 0x0040) | Out-Null; "guest $($pG.Id) -> ${W}x${H} at $W,0" }
