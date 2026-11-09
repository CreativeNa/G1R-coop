Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class WI {
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  public static void Dump(uint pid) {
    EnumWindows((h, l) => {
      uint p; GetWindowThreadProcessId(h, out p);
      if (p != pid) return true;
      RECT cr, wr; if (!IsWindowVisible(h) || !GetClientRect(h, out cr) || cr.R < 200) return true;
      GetWindowRect(h, out wr);
      var sb = new StringBuilder(256); GetWindowTextW(h, sb, 256);
      Console.WriteLine("{0}  client {1}x{2}  window {3}x{4} at {5},{6}", pid, cr.R, cr.B, wr.R-wr.L, wr.B-wr.T, wr.L, wr.T);
      return true;
    }, IntPtr.Zero);
  }
}
"@
[WI]::Dump(39596)
[WI]::Dump(14564)
Add-Type -AssemblyName System.Windows.Forms
$s = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
"screen: $($s.Width)x$($s.Height)"
