Add-Type -AssemblyName System.Drawing

$src = (Resolve-Path 'ios/Runner/Assets.xcassets/AppIcon.appiconset/1024.png').Path
$img = [System.Drawing.Image]::FromFile($src)

$targets = @(
  @('ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png', 168, 185),
  @('ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png', 336, 370),
  @('ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png', 504, 555)
)

foreach ($target in $targets) {
  $relativePath = $target[0]
  $width = [int]$target[1]
  $height = [int]$target[2]
  $fullPath = Join-Path (Get-Location) $relativePath

  $bmp = New-Object System.Drawing.Bitmap $width, $height
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear([System.Drawing.Color]::Transparent)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

  $iconSize = [Math]::Min([int]($width * 0.55), [int]($height * 0.55))
  $x = [int](($width - $iconSize) / 2)
  $y = [int](($height - $iconSize) / 2)

  $g.DrawImage($img, $x, $y, $iconSize, $iconSize)
  $bmp.Save($fullPath, [System.Drawing.Imaging.ImageFormat]::Png)

  $g.Dispose()
  $bmp.Dispose()
}

$img.Dispose()
