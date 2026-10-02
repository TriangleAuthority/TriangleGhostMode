# Save a screenshot of the primary screen as PNG:
#   powershell -File tools\screenshot.ps1 <out.png> [-Region x,y,width,height]   (screen pixels)
param([Parameter(Mandatory)][string]$Out, [string]$Region)
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type 'using System.Runtime.InteropServices; public static class Dpi { [DllImport("user32.dll")] public static extern bool SetProcessDPIAware(); }'
[Dpi]::SetProcessDPIAware() | Out-Null
$b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
if ($Region) { $r = [int[]]($Region -split ","); $b = New-Object System.Drawing.Rectangle $r[0], $r[1], $r[2], $r[3] }
$bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
