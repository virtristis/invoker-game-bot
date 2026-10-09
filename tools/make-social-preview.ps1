param([string]$Repo = (Split-Path $PSScriptRoot), [string]$Shots = "$env:TEMP\igb-shots", [string]$Out = "$Repo\docs\social-preview.png")
# Social preview 1280x640 in the style of docs/banner.png (same artwork: tools/art/banner-art.jpg) (Settings -> Social preview on GitHub).
# Screenshots first:  AutoHotkey64.exe invoker_bot.ahk --selftest shot-main-drill
#                     AutoHotkey64.exe invoker_bot.ahk --selftest drill-shots
Add-Type -AssemblyName System.Drawing
$W = 1280; $H = 640
$banner = [Drawing.Image]::FromFile("$Repo\tools\art\banner-art.jpg")   # artwork without text and windows
$main = [Drawing.Image]::FromFile("$Shots\main-shot-main-drill.png")
$drill = [Drawing.Image]::FromFile("$Shots\3-hint.png")

$bmp = New-Object Drawing.Bitmap $W, $H
$g = [Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'; $g.InterpolationMode = 'HighQualityBicubic'; $g.TextRenderingHint = 'AntiAliasGridFit'

# 1) background: the artwork, heavily blurred (downscale/upscale) and darkened
$small = New-Object Drawing.Bitmap 40, 22
$gs = [Drawing.Graphics]::FromImage($small); $gs.InterpolationMode = 'HighQualityBilinear'
$gs.DrawImage($banner, (New-Object Drawing.Rectangle 0, 0, 40, 22)); $gs.Dispose()
$g.DrawImage($small, (New-Object Drawing.Rectangle -30, -30, ($W + 60), ($H + 110)))
$shade = New-Object Drawing.Drawing2D.LinearGradientBrush (New-Object Drawing.Point 0, 0), (New-Object Drawing.Point $W, 0), ([Drawing.Color]::FromArgb(200, 10, 8, 20)), ([Drawing.Color]::FromArgb(90, 10, 8, 20))
$g.FillRectangle($shade, 0, 0, $W, $H)

# sharp Quas / Wex / Exort orbs from the artwork's top-right corner, soft edges
$ow = 442; $oh = 230
$orbBmp = New-Object Drawing.Bitmap $ow, $oh, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
$go = [Drawing.Graphics]::FromImage($orbBmp)
$go.DrawImage($banner, (New-Object Drawing.Rectangle 0, 0, $ow, $oh), (New-Object Drawing.Rectangle 1230, 40, $ow, $oh), 'Pixel'); $go.Dispose()
for ($yy = 0; $yy -lt $oh; $yy++) { for ($xx = 0; $xx -lt $ow; $xx++) {
  $ex = [Math]::Min(1.0, [Math]::Min($xx, $ow - 1 - $xx) / 110.0); $ey = [Math]::Min(1.0, [Math]::Min($yy, $oh - 1 - $yy) / 70.0)
  $c = $orbBmp.GetPixel($xx, $yy); $orbBmp.SetPixel($xx, $yy, [Drawing.Color]::FromArgb([int](255 * $ex * $ey), $c.R, $c.G, $c.B)) } }
$g.DrawImage($orbBmp, 860, -40, $ow, $oh)

# 2) title: golden gradient lettering with a warm glow (like the app header)
$tp = New-Object Drawing.Drawing2D.GraphicsPath
$tp.AddString("INVOKER BOT", (New-Object Drawing.FontFamily "Georgia"), 1, 80, (New-Object Drawing.Point 56, 100), [Drawing.StringFormat]::GenericTypographic)
foreach ($wd in 22, 14, 8, 4) {
  $pen = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(38, 245, 158, 11)), $wd; $pen.LineJoin = 'Round'; $g.DrawPath($pen, $tp) }
$gb = New-Object Drawing.Drawing2D.LinearGradientBrush (New-Object Drawing.Point 0, 106), (New-Object Drawing.Point 0, 176), ([Drawing.Color]::FromArgb(255, 254, 243, 199)), ([Drawing.Color]::FromArgb(255, 217, 119, 6))
$g.FillPath($gb, $tp)
$g.DrawPath((New-Object Drawing.Pen ([Drawing.Color]::FromArgb(160, 120, 53, 15)), 1.2), $tp)

# 3) subtitle lines
function Spaced($text, $font, $brush, $x, $y, $spacing) {
  foreach ($ch in $text.ToCharArray()) {
    $s = [string]$ch
    $g.DrawString($s, $font, $brush, $x, $y)
    $x += $g.MeasureString($s, $font, 1000, [Drawing.StringFormat]::GenericTypographic).Width + $spacing
  }
}
$lav = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(255, 196, 181, 253))
$muted = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(255, 210, 213, 226))
$gold = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(255, 251, 191, 36))
$f1 = New-Object Drawing.Font "Segoe UI Semibold", 22, ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel)
Spaced "BOT  ·  COACH  ·  PRACTICE" $f1 $lav 62 202 5
$f2 = New-Object Drawing.Font "Segoe UI", 23, ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel)
$g.DrawString("Learn Invoker's combos for invoker-game.com.", $f2, $muted, 60, 258)
$g.DrawString("New and Old Invoker, live hints, timed practice", $f2, $muted, 60, 290)
$g.DrawString("with spell icons, and a progress chart.", $f2, $muted, 60, 322)

$line = New-Object Drawing.Drawing2D.LinearGradientBrush (New-Object Drawing.Point 60, 0), (New-Object Drawing.Point 560, 0), ([Drawing.Color]::FromArgb(220, 167, 139, 250)), ([Drawing.Color]::FromArgb(0, 167, 139, 250))
$g.FillRectangle($line, 62, 382, 500, 2)
$f3 = New-Object Drawing.Font "Segoe UI Semibold", 17, ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel)
$x = 62; $y = 404
foreach ($p in "AutoHotkey v2", "Windows 10 / 11", "EN · RU · ES · 中文", "MIT") {
  $sz = $g.MeasureString($p, $f3)
  $rect = New-Object Drawing.RectangleF $x, $y, ($sz.Width + 22), 34
  $path = New-Object Drawing.Drawing2D.GraphicsPath
  $r = 17; $path.AddArc($rect.X, $rect.Y, 2*$r, 2*$r, 90, 180); $path.AddArc($rect.Right - 2*$r, $rect.Y, 2*$r, 2*$r, 270, 180); $path.CloseFigure()
  $g.FillPath((New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(160, 30, 27, 48))), $path)
  $g.DrawPath((New-Object Drawing.Pen ([Drawing.Color]::FromArgb(140, 139, 92, 246)), 1.5), $path)
  $g.DrawString($p, $f3, $muted, $x + 11, $y + 6)
  $x += $rect.Width + 10
}
$f4 = New-Object Drawing.Font "Segoe UI Semibold", 19, ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel)
$g.DrawString("github.com/virtristis/invoker-game-bot", $f4, $gold, 60, 566)

# 4) app windows on the right, with a themed glow frame
function Framed($img, $x, $y, $w, $h, $col) {
  for ($k = 14; $k -ge 2; $k -= 3) {
    $pen = New-Object Drawing.Pen ([Drawing.Color]::FromArgb([int](110 / $k * 2), $col.R, $col.G, $col.B)), $k
    $g.DrawRectangle($pen, $x - $k / 2, $y - $k / 2, $w + $k, $h + $k)
  }
  $g.DrawImage($img, (New-Object Drawing.Rectangle $x, $y, $w, $h))
  $g.DrawRectangle((New-Object Drawing.Pen $col, 2), $x - 1, $y - 1, $w + 1, $h + 1)
}
$violet = [Drawing.Color]::FromArgb(255, 139, 92, 246)
$amber = [Drawing.Color]::FromArgb(255, 245, 158, 11)
$mw = 290; $mh = [int]($mw * $main.Height / $main.Width)
Framed $main 790 ([int](($H - $mh) / 2) + 24) $mw $mh $violet
$dw = 360; $dh = [int]($dw * $drill.Height / $drill.Width)
Framed $drill 892 ([int]($H - $dh - 56)) $dw $dh $amber

$g.Dispose()
$bmp.Save($Out, [Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose(); $banner.Dispose(); $main.Dispose(); $drill.Dispose(); $small.Dispose(); $orbBmp.Dispose()
"saved $Out"
