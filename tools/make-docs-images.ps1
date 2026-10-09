param([string]$Repo = (Split-Path $PSScriptRoot), [string]$Shots = "$env:TEMP\igb\docs", [string]$Docs = "$Repo\docs")
# README images from screenshots in $Shots, on a dark background with a glowing frame in the theme colour:
#   horizontal.png     <- h.png               (main window, layout=h; --selftest shot-main-timed)
#   coach-overlay.png  <- stage-0..4.png      (--selftest shot-stages)
#   practice.png       <- p1.png p2.png p3.png (--selftest drill-shots / drill-old-weak-shots: 3-hint, 3-hint, 4-done)
Add-Type -AssemblyName System.Drawing

function NewCanvas($w, $h, $c1, $c2) {
  $bmp = New-Object Drawing.Bitmap $w, $h
  $g = [Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'; $g.InterpolationMode = 'HighQualityBicubic'; $g.TextRenderingHint = 'AntiAliasGridFit'
  $br = New-Object Drawing.Drawing2D.LinearGradientBrush (New-Object Drawing.Point 0, 0), (New-Object Drawing.Point $w, $h), $c1, $c2
  $g.FillRectangle($br, 0, 0, $w, $h)
  @{ bmp = $bmp; g = $g }
}
function RoundRect($x, $y, $w, $h, $r) {
  $p = New-Object Drawing.Drawing2D.GraphicsPath
  $p.AddArc($x, $y, 2*$r, 2*$r, 180, 90); $p.AddArc($x + $w - 2*$r, $y, 2*$r, 2*$r, 270, 90)
  $p.AddArc($x + $w - 2*$r, $y + $h - 2*$r, 2*$r, 2*$r, 0, 90); $p.AddArc($x, $y + $h - 2*$r, 2*$r, 2*$r, 90, 90); $p.CloseFigure(); $p
}
function Framed($g, $file, $x, $y, $col, $r = 10) {
  $img = [Drawing.Image]::FromFile($file); $w = $img.Width; $h = $img.Height
  for ($k = 22; $k -ge 2; $k -= 4) {
    $pen = New-Object Drawing.Pen ([Drawing.Color]::FromArgb([int](120 / $k * 2.2), $col.R, $col.G, $col.B)), $k
    $g.DrawPath($pen, (RoundRect ($x - 2) ($y - 2) ($w + 4) ($h + 4) ($r + 2)))
  }
  $g.SetClip((RoundRect $x $y $w $h $r)); $g.DrawImage($img, $x, $y, $w, $h); $g.ResetClip()
  $g.DrawPath((New-Object Drawing.Pen $col, 2), (RoundRect ($x - 1) ($y - 1) ($w + 2) ($h + 2) ($r + 1)))
  $img.Dispose()
}
function Save($cv, $name) { $cv.g.Dispose(); $cv.bmp.Save("$Docs\$name", [Drawing.Imaging.ImageFormat]::Png); $cv.bmp.Dispose(); "saved docs\$name" }

$violet = [Drawing.Color]::FromArgb(255, 139, 92, 246)
$gold = [Drawing.Color]::FromArgb(255, 245, 158, 11)
$dark1 = [Drawing.Color]::FromArgb(255, 20, 16, 34)
$dark2 = [Drawing.Color]::FromArgb(255, 44, 26, 64)

# horizontal layout
if (Test-Path "$Shots\h.png") {
  $cv = NewCanvas 840 504 ([Drawing.Color]::FromArgb(255, 38, 26, 10)) $dark2
  Framed $cv.g "$Shots\h.png" 60 50 $gold
  Save $cv "horizontal.png"
}

# coach overlay: stages 0/4 ... 4/4
if (Test-Path "$Shots\stage-0.png") {
  $img = [Drawing.Image]::FromFile("$Shots\stage-0.png"); $sw = $img.Width; $sh = $img.Height; $img.Dispose()
  $gap = 36; $m = 48
  $cv = NewCanvas ($m * 2 + 5 * $sw + 4 * $gap) ($sh + 110) ([Drawing.Color]::FromArgb(255, 16, 30, 52)) ([Drawing.Color]::FromArgb(255, 58, 38, 18))
  $font = New-Object Drawing.Font "Segoe UI", 17, ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel)
  $muted = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(255, 160, 165, 185))
  for ($i = 0; $i -le 4; $i++) {
    $x = $m + $i * ($sw + $gap)
    Framed $cv.g "$Shots\stage-$i.png" $x 30 $violet 8
    $t = "$i / 4"; $tw = $cv.g.MeasureString($t, $font).Width
    $cv.g.DrawString($t, $font, $muted, $x + ($sw - $tw) / 2, $sh + 54)
  }
  Save $cv "coach-overlay.png"
}

# practice: NEW hint, OLD hint, result
if (Test-Path "$Shots\p1.png") {
  $img = [Drawing.Image]::FromFile("$Shots\p1.png"); $pw = $img.Width; $ph = $img.Height; $img.Dispose()
  $gap = 28; $m = 28
  $cv = NewCanvas ($m * 2 + 3 * $pw + 2 * $gap) ($ph + 2 * $m) $dark1 $dark2
  for ($i = 1; $i -le 3; $i++) { Framed $cv.g "$Shots\p$i.png" ($m + ($i - 1) * ($pw + $gap)) $m $violet 6 }
  Save $cv "practice.png"
}
