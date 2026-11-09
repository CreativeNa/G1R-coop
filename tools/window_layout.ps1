param([string]$Mode = 'overlap')
Add-Type @"
using System; using System.Runtime.InteropServices;
public class OW {
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
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$hHost = [OW]::Find(45324)
$hGuest = [OW]::Find(51820)
if ($Mode -eq 'overlap') {
    if ($hHost -ne [IntPtr]::Zero) { [OW]::ShowWindow($hHost, 9) | Out-Null; [OW]::SetWindowPos($hHost, [IntPtr]::Zero, 0, 0, $screen.Width, $screen.Height, 0x0040) | Out-Null }
    if ($hGuest -ne [IntPtr]::Zero) { [OW]::ShowWindow($hGuest, 9) | Out-Null; [OW]::SetWindowPos($hGuest, [IntPtr]::Zero, 0, 0, $screen.Width, $screen.Height, 0x0040) | Out-Null }
    "windows overlapped (guest on top)"
} else {
    $half = [int]($screen.Width / 2)
    if ($hHost -ne [IntPtr]::Zero) { [OW]::SetWindowPos($hHost, [IntPtr]::Zero, 0, 0, $half, $screen.Height, 0x0040) | Out-Null }
    if ($hGuest -ne [IntPtr]::Zero) { [OW]::SetWindowPos($hGuest, [IntPtr]::Zero, $half, 0, $screen.Width - $half, $screen.Height, 0x0040) | Out-Null }
    "windows tiled side by side"
}
