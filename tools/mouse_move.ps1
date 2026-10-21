# Move the game's menu cursor to screen pixel (X, Y), optionally left-click: powershell -ExecutionPolicy Bypass -File tools\mouse_move.ps1 <X> <Y> [-Click]
# The game reads raw mouse input: SetCursorPos does not move its cursor. Relative mouse_event moves do: the cursor is
# first pushed into the top-left corner, then moved by (X, Y) in steps. The game window must be in front (focus_game.ps1).
param([int]$X, [int]$Y, [switch]$Click)
Add-Type @'
using System; using System.Runtime.InteropServices;
public static class M {
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, int dx, int dy, uint d, UIntPtr e);
}
'@
for ($i = 0; $i -lt 80; $i++) { [M]::mouse_event(1, -60, -60, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 5 }
$cx = 0; $cy = 0
while ($cx -lt $X -or $cy -lt $Y) {
  $dx = [Math]::Min(40, $X - $cx); $dy = [Math]::Min(40, $Y - $cy)
  [M]::mouse_event(1, $dx, $dy, 0, [UIntPtr]::Zero); $cx += $dx; $cy += $dy
  Start-Sleep -Milliseconds 10
}
Start-Sleep -Milliseconds 200
if ($Click) { [M]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 80; [M]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero) }
