Add-Type -AssemblyName System.Drawing

$srcPath = (Resolve-Path 'assets/images/logopt.png').Path
$destPath = Join-Path (Get-Location) 'assets/images/app_icon_source.png'

$src = [System.Drawing.Image]::FromFile($srcPath)
$size = 1024
$bmp = New-Object System.Drawing.Bitmap $size, $size
$graphics = [System.Drawing.Graphics]::FromImage($bmp)

$graphics.Clear([System.Drawing.Color]::FromArgb(255, 79, 70, 229))
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

$maxSize = 760
$scale = [Math]::Min($maxSize / $src.Width, $maxSize / $src.Height)
$width = [int]($src.Width * $scale)
$height = [int]($src.Height * $scale)
$x = [int](($size - $width) / 2)
$y = [int](($size - $height) / 2)

$graphics.DrawImage($src, $x, $y, $width, $height)
$bmp.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)

$graphics.Dispose()
$bmp.Dispose()
$src.Dispose()
