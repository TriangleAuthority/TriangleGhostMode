# Send key presses to the foreground window as hardware scan codes (games often ignore virtual-key events):
#   powershell -File tools\send_key.ps1 <key> [count] [delayMs]      key: space, esc, enter, tilde, e, backspace,
#                                                                     up, down, left, right (menus: arrows + enter)
#   powershell -File tools\send_key.ps1 type <text>                   type text as scan codes (US layout keys)
#   powershell -File tools\send_key.ps1 paste <text>                  put text on the clipboard and press Ctrl+V
param([Parameter(Mandatory)][string]$Key, [string]$Count = '1', [int]$DelayMs = 300)
Add-Type @'
using System; using System.Runtime.InteropServices;
public static class Kbd {
  [StructLayout(LayoutKind.Sequential)] struct KEYBDINPUT { public ushort wVk, wScan; public uint dwFlags, time; public IntPtr extra; }
  [StructLayout(LayoutKind.Explicit, Size = 40)] struct INPUT { [FieldOffset(0)] public uint type; [FieldOffset(8)] public KEYBDINPUT ki; }
  [DllImport("user32.dll")] static extern uint SendInput(uint n, INPUT[] inputs, int size);
  static void Send(ushort scan, bool up) {
    var i = new INPUT[1];
    bool ext = (scan & 0xE000) == 0xE000;                                       // 0xE0xx = extended key (arrows)
    i[0].type = 1; i[0].ki.wScan = (ushort)(scan & 0xFF);
    i[0].ki.dwFlags = 8u | (ext ? 1u : 0u) | (up ? 2u : 0u);   // KEYEVENTF_SCANCODE | KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP
    SendInput(1, i, Marshal.SizeOf(typeof(INPUT)));
  }
  [DllImport("user32.dll")] static extern short VkKeyScan(char c);
  [DllImport("user32.dll")] static extern uint MapVirtualKey(uint code, uint mapType);
  public static void Type(string text) {                              // each character as its scan code, with Shift if needed
    foreach (char c in text) {
      short vk = VkKeyScan(c);
      ushort scan = (ushort)MapVirtualKey((uint)(vk & 0xFF), 0);      // MAPVK_VK_TO_VSC
      Press(scan, (vk & 0x100) != 0 ? (ushort)0x2A : (ushort)0);      // 0x2A = left Shift
      System.Threading.Thread.Sleep(30);
    }
  }
  public static void Press(ushort scan, ushort modifier = 0) {
    if (modifier != 0) { Send(modifier, false); System.Threading.Thread.Sleep(50); }
    Send(scan, false); System.Threading.Thread.Sleep(50); Send(scan, true);
    if (modifier != 0) { System.Threading.Thread.Sleep(50); Send(modifier, true); }
  }
}
'@
if ($Key -eq 'type') { [Kbd]::Type($Count); exit }
if ($Key -eq 'paste') {
  Set-Clipboard -Value $Count
  [Kbd]::Press(0x2F, 0x1D)   # Ctrl+V
  exit
}
$scan = @{ space = 0x39; esc = 0x01; enter = 0x1C; tilde = 0x29; e = 0x12; backspace = 0x0E;
           up = 0xE048; down = 0xE050; left = 0xE04B; right = 0xE04D }[$Key.ToLower()]
if (-not $scan) { throw "unknown key $Key" }
for ($n = 0; $n -lt [int]$Count; $n++) { [Kbd]::Press($scan); Start-Sleep -Milliseconds $DelayMs }
