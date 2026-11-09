# Really press a key in ONE game window (SendInput, not PostMessage): the game reads GetAsyncKeyState,
# so a posted message does nothing. Brings the window to the front first.
#   .\tools\realkey.ps1 -Seat 0 -Vk 0x78      (0x78 = F9)
param([int]$Seat = 0, [int]$Vk = 0x78)
Add-Type @"
using System; using System.Runtime.InteropServices;
public class RK {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  public static IntPtr Find(uint pid) { IntPtr f = IntPtr.Zero; EnumWindows((h, l) => { uint p; GetWindowThreadProcessId(h, out p); RECT r; if (p == pid && IsWindowVisible(h) && GetClientRect(h, out r) && r.R > 200) { f = h; return false; } return true; }, IntPtr.Zero); return f; }
}
"@
$q = Get-CimInstance Win32_Process -Filter "Name='G1R-Win64-Shipping.exe'" | Where-Object { $_.CommandLine -match "-CoopSeat=$Seat(\s|$)" } | Select-Object -First 1
if (-not $q) { throw "no game with seat $Seat" }
$h = [RK]::Find([uint32]$q.ProcessId); if ($h -eq [IntPtr]::Zero) { throw "no window" }
[RK]::ShowWindow($h, 9) | Out-Null
[RK]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 400
[RK]::keybd_event([byte]$Vk, 0, 0, [UIntPtr]::Zero)
Start-Sleep -Milliseconds 90
[RK]::keybd_event([byte]$Vk, 0, 2, [UIntPtr]::Zero)
"pressed vk 0x{0:X} in seat {1} (pid {2})" -f $Vk, $Seat, $q.ProcessId
