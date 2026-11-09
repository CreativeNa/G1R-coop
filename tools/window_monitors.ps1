Add-Type @"
using System; using System.Runtime.InteropServices;
public class MON {
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
Add-Type -AssemblyName System.Windows.Forms
$screens = [System.Windows.Forms.Screen]::AllScreens
$main = ($screens | Where-Object { $_.Primary } | Select-Object -First 1).Bounds
$second = ($screens | Where-Object { -not $_.Primary } | Select-Object -First 1).Bounds
$procs = Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue
$pH = $procs | Where-Object { $_.MainWindowTitle -match 'HOST' } | Select-Object -First 1
$pG = $procs | Where-Object { $_.MainWindowTitle -match 'GUEST' } | Select-Object -First 1
if ($pH) { $w = [MON]::Find([uint32]$pH.Id); [MON]::ShowWindow($w, 9) | Out-Null; [MON]::SetWindowPos($w, [IntPtr]::Zero, $main.X, $main.Y, $main.Width, $main.Height, 0x0040) | Out-Null; "host  -> main screen $($main.Width)x$($main.Height)" }
if ($pG -and $second) { $w2 = [MON]::Find([uint32]$pG.Id); [MON]::ShowWindow($w2, 9) | Out-Null; [MON]::SetWindowPos($w2, [IntPtr]::Zero, $second.X, $second.Y, $second.Width, $second.Height, 0x0040) | Out-Null; "guest -> second screen $($second.Width)x$($second.Height) at $($second.X),$($second.Y)" }
