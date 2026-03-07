Add-Type -AssemblyName System.Drawing

$size = 1024
$bmp = New-Object System.Drawing.Bitmap $size, $size
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'
$g.Clear([System.Drawing.Color]::FromArgb(233, 233, 233))

function New-RoundedRectPath($x, $y, $w, $h, $r) {
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $path.AddArc($x, $y, $r, $r, 180, 90)
  $path.AddArc($x + $w - $r, $y, $r, $r, 270, 90)
  $path.AddArc($x + $w - $r, $y + $h - $r, $r, $r, 0, 90)
  $path.AddArc($x, $y + $h - $r, $r, $r, 90, 90)
  $path.CloseFigure()
  return $path
}

$shadowPath = New-RoundedRectPath 142 132 740 740 150
$shadowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(50, 0, 0, 0))
$g.FillPath($shadowBrush, $shadowPath)

$cardPath = New-RoundedRectPath 132 120 760 760 150
$startPoint = [System.Drawing.PointF]::new(132, 120)
$endPoint = [System.Drawing.PointF]::new(892, 880)
$startColor = [System.Drawing.Color]::FromArgb(15, 98, 255)
$endColor = [System.Drawing.Color]::FromArgb(84, 28, 189)
$cardGradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush (
  $startPoint,
  $endPoint,
  $startColor,
  $endColor
)
$g.FillPath($cardGradient, $cardPath)

$whiteBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$blueBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(26, 112, 255))
$glowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(110, 152, 255, 255))

$g.FillEllipse($whiteBrush, 245, 230, 340, 340)
$g.FillEllipse($blueBrush, 297, 282, 236, 236)
$g.FillEllipse($glowBrush, 300, 290, 220, 220)

$handlePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White, 26)
$handlePen.StartCap = 'Round'
$handlePen.EndCap = 'Round'
$g.DrawLine($handlePen, 520, 545, 673, 695)
$g.FillEllipse($whiteBrush, 607, 652, 102, 102)

$g.FillRectangle($whiteBrush, 400, 310, 22, 160)
$g.FillRectangle($whiteBrush, 331, 379, 160, 22)

$diagPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White, 12)
$diagPen.StartCap = 'Round'
$diagPen.EndCap = 'Round'
$g.DrawLine($diagPen, 355, 335, 466, 446)
$g.DrawLine($diagPen, 466, 335, 355, 446)

$g.FillEllipse($whiteBrush, 500, 290, 18, 18)
$sparklePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White, 4)
$sparklePen.StartCap = 'Round'
$sparklePen.EndCap = 'Round'
$g.DrawLine($sparklePen, 509, 272, 509, 326)
$g.DrawLine($sparklePen, 482, 299, 536, 299)

$outputPath = Join-Path (Resolve-Path 'assets/images').Path 'w.png'
$bmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

$sparklePen.Dispose()
$diagPen.Dispose()
$handlePen.Dispose()
$blueBrush.Dispose()
$glowBrush.Dispose()
$whiteBrush.Dispose()
$cardGradient.Dispose()
$cardPath.Dispose()
$shadowBrush.Dispose()
$shadowPath.Dispose()
$g.Dispose()
$bmp.Dispose()
