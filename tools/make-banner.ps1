param([string]$Repo = (Split-Path $PSScriptRoot), [string]$Shots = "$env:TEMP\igb\banner", [string]$Out = "$Repo\docs\banner.png",
      [string]$Version = "", [string]$Art = "$Repo\tools\art\banner-art.jpg", [string]$OldBanner = "")
# Showcase banner 1672x941: four app windows (3 themes, 4 languages) on the project's artwork.
# Screenshots first (any way you like, e.g. on a hidden desktop), into $Shots:
#   w1.png  theme=violet lang=en  (Bot)        w2.png  theme=blue lang=ru  (Coach)
#   w3.png  theme=gold   lang=es  (Practice)   w4.png  theme=violet lang=zh (Bot)
# made with:  AutoHotkey64.exe invoker_bot.ahk --selftest shot-main-timed|shot-main-coach|shot-main-drill
# after writing theme= / lang= into %TEMP%\InvokerGameBot-selftest\invoker_bot.ini
# tools\art\banner-art.jpg is the background without text and windows; -OldBanner rebuilds it from a banner image
Add-Type -AssemblyName System.Drawing
if (-not $Version) { $Version = ([regex]'VERSION\s*:=\s*"([\d.]+)"').Match((Get-Content "$Repo\invoker_bot.ahk" -Raw)).Groups[1].Value }

if ($OldBanner) {
  # background: the banner blurred (downscale/upscale), a little darker, plus its sharp corners with soft edges:
  # Invoker (top-left) and the Quas/Wex/Exort orbs (top-right; make-social-preview.ps1 takes them from there)
  $src = [Drawing.Image]::FromFile($OldBanner)
  $W = $src.Width; $H = $src.Height
  $ab = New-Object Drawing.Bitmap $W, $H
  $g = [Drawing.Graphics]::FromImage($ab); $g.InterpolationMode = 'HighQualityBicubic'
  $small = New-Object Drawing.Bitmap 140, 79
  $gs = [Drawing.Graphics]::FromImage($small); $gs.InterpolationMode = 'HighQualityBilinear'
  $gs.DrawImage($src, (New-Object Drawing.Rectangle 0, 0, 140, 79)); $gs.Dispose()
  $g.DrawImage($small, (New-Object Drawing.Rectangle -12, -12, ($W + 24), ($H + 24))); $small.Dispose()
  $g.FillRectangle((New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(70, 8, 6, 18))), 0, 0, $W, $H)
  # the old title blurred into a smudge: darken the middle of the top
  $band = New-Object Drawing.Drawing2D.GraphicsPath; $band.AddEllipse(380, 20, 912, 260)
  $pb = New-Object Drawing.Drawing2D.PathGradientBrush $band
  $pb.CenterColor = [Drawing.Color]::FromArgb(150, 12, 8, 26); $pb.SurroundColors = @([Drawing.Color]::FromArgb(0, 12, 8, 26))
  $g.FillPath($pb, $band)
  function SoftPiece($sx, $sy, $w, $h, $fx, $fy, $edges) {
    $pc = New-Object Drawing.Bitmap $w, $h, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $gp = [Drawing.Graphics]::FromImage($pc)
    $gp.DrawImage($src, (New-Object Drawing.Rectangle 0, 0, $w, $h), (New-Object Drawing.Rectangle $sx, $sy, $w, $h), 'Pixel'); $gp.Dispose()
    for ($yy = 0; $yy -lt $h; $yy++) { for ($xx = 0; $xx -lt $w; $xx++) {
      $l = if ($edges -match 'l') { $xx } else { 1e9 }; $r = if ($edges -match 'r') { $w - 1 - $xx } else { 1e9 }
      $t = if ($edges -match 't') { $yy } else { 1e9 }; $b = if ($edges -match 'b') { $h - 1 - $yy } else { 1e9 }
      $a = [Math]::Min(1.0, [Math]::Min($l, $r) / $fx) * [Math]::Min(1.0, [Math]::Min($t, $b) / $fy)
      $c = $pc.GetPixel($xx, $yy); $pc.SetPixel($xx, $yy, [Drawing.Color]::FromArgb([int](255 * $a), $c.R, $c.G, $c.B)) } }
    $g.DrawImage($pc, $sx, $sy, $w, $h); $pc.Dispose()
  }
  SoftPiece 0 0 430 300 120 90 'rb'
  SoftPiece 1230 40 442 230 110 70 'lrtb'
  $g.Dispose(); $src.Dispose()
  New-Item -ItemType Directory -Force (Split-Path $Art) | Out-Null
  $enc = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
  $ep = New-Object Drawing.Imaging.EncoderParameters 1
  $ep.Param[0] = New-Object Drawing.Imaging.EncoderParameter ([Drawing.Imaging.Encoder]::Quality), 92L
  $ab.Save($Art, $enc, $ep); $ab.Dispose()
  "saved $Art"
}

$artImg = [Drawing.Image]::FromFile($Art)
$W = $artImg.Width; $H = $artImg.Height       # 1672 x 941
$bmp = New-Object Drawing.Bitmap $W, $H
$g = [Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'; $g.InterpolationMode = 'HighQualityBicubic'; $g.TextRenderingHint = 'AntiAliasGridFit'
$g.DrawImage($artImg, 0, 0, $W, $H); $artImg.Dispose()

# 2) title: golden gradient lettering with a warm glow (like the app header)
$ff = New-Object Drawing.FontFamily "Georgia"
$sf = [Drawing.StringFormat]::GenericTypographic
$tp = New-Object Drawing.Drawing2D.GraphicsPath
$tp.AddString("INVOKER BOT", $ff, 1, 96, (New-Object Drawing.Point 0, 0), $sf)
$tb = $tp.GetBounds()
$m = New-Object Drawing.Drawing2D.Matrix; $m.Translate(($W - $tb.Width) / 2 - $tb.X, 52 - $tb.Y); $tp.Transform($m)
foreach ($wd in 30, 20, 12, 6) {
  $pen = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(34, 245, 158, 11)), $wd; $pen.LineJoin = 'Round'; $g.DrawPath($pen, $tp) }
$tb = $tp.GetBounds()
$gb = New-Object Drawing.Drawing2D.LinearGradientBrush (New-Object Drawing.PointF 0, $tb.Top), (New-Object Drawing.PointF 0, $tb.Bottom), ([Drawing.Color]::FromArgb(255, 254, 243, 199)), ([Drawing.Color]::FromArgb(255, 217, 119, 6))
$g.FillPath($gb, $tp)
$g.DrawPath((New-Object Drawing.Pen ([Drawing.Color]::FromArgb(170, 120, 53, 15)), 1.5), $tp)

# 3) subtitle lines, centred
function Spaced($text, $font, $brush, $y, $spacing) {
  $chars = $text.ToCharArray(); $ws = @(); $total = 0
  foreach ($ch in $chars) { $cw = $g.MeasureString([string]$ch, $font, 1000, $sf).Width + $spacing; $ws += $cw; $total += $cw }
  $x = ($W - $total + $spacing) / 2
  for ($i = 0; $i -lt $chars.Length; $i++) { $g.DrawString([string]$chars[$i], $font, $brush, $x, $y, $sf); $x += $ws[$i] }
}
function Centered($text, $font, $brush, $y) {
  $sz = $g.MeasureString($text, $font, 2000, $sf); $g.DrawString($text, $font, $brush, ($W - $sz.Width) / 2, $y, $sf)
}
$lav = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(255, 196, 181, 253))
$muted = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(255, 214, 217, 230))
$f1 = New-Object Drawing.Font "Segoe UI Semibold", 25, ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel)
Spaced "BOT  ·  COACH  ·  PRACTICE" $f1 $lav 176 9
$f2 = New-Object Drawing.Font "Segoe UI", 18, ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel)
Centered "New & Old Invoker  ·  AutoHotkey v2  ·  3 themes  ·  EN / RU / ES / 中文  ·  v$Version" $f2 $muted 214
$line = New-Object Drawing.Drawing2D.LinearGradientBrush (New-Object Drawing.Point 536, 0), (New-Object Drawing.Point 1137, 0), ([Drawing.Color]::FromArgb(0, 167, 139, 250)), ([Drawing.Color]::FromArgb(0, 167, 139, 250))
$cb = New-Object Drawing.Drawing2D.ColorBlend 3
$cb.Colors = @([Drawing.Color]::FromArgb(0, 167, 139, 250), [Drawing.Color]::FromArgb(230, 196, 181, 253), [Drawing.Color]::FromArgb(0, 167, 139, 250)); $cb.Positions = @(0.0, 0.5, 1.0)
$line.InterpolationColors = $cb
$g.FillRectangle($line, 536, 247, 600, 2)
$g.FillPolygon((New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(255, 221, 214, 254))), [Drawing.PointF[]]@(
  (New-Object Drawing.PointF 836, 242), (New-Object Drawing.PointF 841, 248), (New-Object Drawing.PointF 836, 254), (New-Object Drawing.PointF 831, 248)))

# 4) the four windows with a glowing frame in the window's theme colour
function RoundRect($x, $y, $w, $h, $r) {
  $p = New-Object Drawing.Drawing2D.GraphicsPath
  $p.AddArc($x, $y, 2*$r, 2*$r, 180, 90); $p.AddArc($x + $w - 2*$r, $y, 2*$r, 2*$r, 270, 90)
  $p.AddArc($x + $w - 2*$r, $y + $h - 2*$r, 2*$r, 2*$r, 0, 90); $p.AddArc($x, $y + $h - 2*$r, 2*$r, 2*$r, 90, 90); $p.CloseFigure(); $p
}
function Framed($img, $x, $y, $w, $h, $col) {
  for ($k = 26; $k -ge 2; $k -= 4) {
    $pen = New-Object Drawing.Pen ([Drawing.Color]::FromArgb([int](150 / $k * 2.2), $col.R, $col.G, $col.B)), $k
    $g.DrawPath($pen, (RoundRect ($x - 2) ($y - 2) ($w + 4) ($h + 4) 12))
  }
  $clip = RoundRect $x $y $w $h 10
  $g.SetClip($clip); $g.DrawImage($img, (New-Object Drawing.Rectangle $x, $y, $w, $h)); $g.ResetClip()
  $g.DrawPath((New-Object Drawing.Pen $col, 3), (RoundRect ($x - 2) ($y - 2) ($w + 4) ($h + 4) 12))
  $g.DrawPath((New-Object Drawing.Pen ([Drawing.Color]::FromArgb(150, 255, 255, 255)), 1), (RoundRect ($x - 3) ($y - 3) ($w + 6) ($h + 6) 13))
}
$cols = @([Drawing.Color]::FromArgb(255, 139, 92, 246), [Drawing.Color]::FromArgb(255, 59, 130, 246),
          [Drawing.Color]::FromArgb(255, 245, 158, 11), [Drawing.Color]::FromArgb(255, 168, 85, 247))
$ww = 317; $wh = 592; $gap = 54; $x0 = [int](($W - 4 * $ww - 3 * $gap) / 2); $wy = 282
for ($i = 0; $i -lt 4; $i++) {
  $img = [Drawing.Image]::FromFile("$Shots\w$($i + 1).png")
  Framed $img ($x0 + $i * ($ww + $gap)) $wy $ww $wh $cols[$i]
  $img.Dispose()
}

# 5) footer
$f4 = New-Object Drawing.Font "Segoe UI Semibold", 19, ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel)
Centered "made by virtristis  ·  github.com/virtristis/invoker-game-bot" $f4 $lav 902

$g.Dispose()
$bmp.Save($Out, [Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
"saved $Out"