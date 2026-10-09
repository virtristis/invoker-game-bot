param([string]$Frames = "$env:TEMP\igb-shots\gif", [string]$Out = "", [int]$DelayMs = 80, [double]$Scale = 1.0,
      [int]$Margin = 24, [string]$Frame = "8B5CF6")
# Animated GIF from PNG frames (f0001.png, f0002.png, ...) without extra tools (encoder: tools\GifWriter.cs).
# Each frame is drawn on a dark background with a
# glowing frame in the theme colour, like the other images in docs/.
#   AutoHotkey64.exe invoker_bot.ahk --selftest drill-gif     (practice run, 80 ms per frame)
#   powershell -File tools\make-gif.ps1 -Out docs\practice-run.gif
Add-Type -AssemblyName System.Drawing
if (-not $Out) { $Out = Join-Path (Split-Path $PSScriptRoot) "docs\practice-run.gif" }
$files = Get-ChildItem $Frames -Filter "f*.png" | Sort-Object Name
if (-not $files) { throw "no frames in $Frames" }

$first = [Drawing.Image]::FromFile($files[0].FullName)
$fw = [int]($first.Width * $Scale); $fh = [int]($first.Height * $Scale); $first.Dispose()
$W = $fw + 2 * $Margin; $H = $fh + 2 * $Margin
$col = [Drawing.ColorTranslator]::FromHtml("#$Frame")

function RoundRect($x, $y, $w, $h, $r) {
  $p = New-Object Drawing.Drawing2D.GraphicsPath
  $p.AddArc($x, $y, 2*$r, 2*$r, 180, 90); $p.AddArc($x + $w - 2*$r, $y, 2*$r, 2*$r, 270, 90)
  $p.AddArc($x + $w - 2*$r, $y + $h - 2*$r, 2*$r, 2*$r, 0, 90); $p.AddArc($x, $y + $h - 2*$r, 2*$r, 2*$r, 90, 90); $p.CloseFigure(); $p
}
# the background with the glowing frame is the same for every frame
$bg = New-Object Drawing.Bitmap $W, $H
$g = [Drawing.Graphics]::FromImage($bg); $g.SmoothingMode = 'AntiAlias'
$br = New-Object Drawing.Drawing2D.LinearGradientBrush (New-Object Drawing.Point 0, 0), (New-Object Drawing.Point $W, $H), ([Drawing.Color]::FromArgb(255, 20, 16, 34)), ([Drawing.Color]::FromArgb(255, 44, 26, 64))
$g.FillRectangle($br, 0, 0, $W, $H)
for ($k = 18; $k -ge 2; $k -= 4) {
  $pen = New-Object Drawing.Pen ([Drawing.Color]::FromArgb([int](120 / $k * 2.2), $col.R, $col.G, $col.B)), $k
  $g.DrawPath($pen, (RoundRect ($Margin - 2) ($Margin - 2) ($fw + 4) ($fh + 4) 10))
}
$g.DrawPath((New-Object Drawing.Pen $col, 2), (RoundRect ($Margin - 1) ($Margin - 1) ($fw + 2) ($fh + 2) 9))
$g.Dispose()

$tmp = Join-Path $env:TEMP "igb-gif-frames"            # framed copies; overwritten on every run
New-Item -ItemType Directory -Force $tmp | Out-Null
$list = @()
foreach ($f in $files) {
  $bmp = $bg.Clone(); $g = [Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = 'HighQualityBicubic'; $g.SmoothingMode = 'AntiAlias'
  $img = [Drawing.Image]::FromFile($f.FullName)
  $g.SetClip((RoundRect $Margin $Margin $fw $fh 8)); $g.DrawImage($img, $Margin, $Margin, $fw, $fh); $g.Dispose(); $img.Dispose()
  $p = Join-Path $tmp $f.Name; $bmp.Save($p, [Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose(); $list += $p
}
$bg.Dispose()
if (-not ('GifWriter' -as [type])) { Add-Type -Path "$PSScriptRoot\GifWriter.cs" -ReferencedAssemblies System.Drawing }
# delays.txt next to the frames (one value in ms per frame) overrides -DelayMs
$cs = if (Test-Path "$Frames\delays.txt") { [int[]](Get-Content "$Frames\delays.txt" | Where-Object { $_ } | ForEach-Object { [Math]::Max(2, [Math]::Round([int]$_ / 10)) }) } else { [int[]]@([Math]::Round($DelayMs / 10)) }
$info = [GifWriter]::Write([string[]]$list, $Out, $cs)
"saved $Out  ($info, $([Math]::Round((Get-Item $Out).Length / 1MB, 2)) MB)"