$iconDir = Resolve-Path 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
$sourceDir = Join-Path $iconDir '_'

if (Test-Path $sourceDir) {
  Copy-Item -Path (Join-Path $sourceDir '*.png') -Destination $iconDir -Force
}

$jsonPath = Join-Path $iconDir 'Contents.json'
$json = Get-Content $jsonPath -Raw | ConvertFrom-Json

foreach ($image in $json.images) {
  if ($image.PSObject.Properties.Name -contains 'folder') {
    $image.PSObject.Properties.Remove('folder')
  }
}

$json | ConvertTo-Json -Depth 10 -Compress | Set-Content $jsonPath -NoNewline
