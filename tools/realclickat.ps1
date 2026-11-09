# Click at exact coordinates in ONE game window (real mouse, window brought to front).
#   .\tools\realklickat.ps1 -Seat 0 -X 285 -Y 352
param([int]$Seat = 0, [int]$X = 0, [int]$Y = 0)
Add-Type @"
using System; using System.Runtime.InteropServices;
public class RCA {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, int dx, int dy, uint d, UIntPtr e);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  public static IntPtr Find(uint pid) { IntPtr f = IntPtr.Zero; EnumWindows((h, l) => { uint p; GetWindowThreadProcessId(h, out p); RECT r; if (p == pid && IsWindowVisible(h) && GetWindowRect(h, out r) && r.R - r.L > 300) { f = h; return false; } return true; }, IntPtr.Zero); return f; }
}
"@
$q = Get-CimInstance Win32_Process -Filter "Name='G1R-Win64-Shipping.exe'" | Where-Object { $_.CommandLine -match "-CoopSeat=$Seat(\s|$)" } | Select-Object -First 1
if (-not $q) { throw "no game with seat $Seat" }
$h = [RCA]::Find([uint32]$q.ProcessId); if ($h -eq [IntPtr]::Zero) { throw "no window" }
$r = New-Object RCA+RECT; [void][RCA]::GetWindowRect($h, [ref]$r)
[void][RCA]::ShowWindow($h, 9)
[void][RCA]::SetForegroundWindow($h)
Start-Sleep -Milliseconds 400
[void][RCA]::SetCursorPos($r.L + $X, $r.T + $Y)
Start-Sleep -Milliseconds 200
[RCA]::mouse_event(0x0002, 0, 0, 0, [UIntPtr]::Zero)
Start-Sleep -Milliseconds 120
[RCA]::mouse_event(0x0004, 0, 0, 0, [UIntPtr]::Zero)
"clicked seat $Seat at window +$X,+$Y (pid $($q.ProcessId))"
