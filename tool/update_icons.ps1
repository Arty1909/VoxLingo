# Resize the approved ImageGen master; no redrawing or visual cleanup here.
param([switch]$WebOnly)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path -Parent $PSScriptRoot
$source = [Drawing.Image]::FromFile((Join-Path $projectRoot 'assets/branding/app_icon.png'))
function New-IconPng([int]$size, [double]$scale = 1.0) {
    # Opaque RGB is required for the App Store marketing icon.
    $bitmap = New-Object Drawing.Bitmap($size, $size, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([Drawing.Color]::White)
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $edge = [int][Math]::Round($size * $scale)
    $offset = [int](($size - $edge) / 2)
    $graphics.DrawImage($source, $offset, $offset, $edge, $edge)
    $stream = New-Object IO.MemoryStream
    try {
        $bitmap.Save($stream, [Drawing.Imaging.ImageFormat]::Png)
        return ,$stream.ToArray()
    } finally { $graphics.Dispose(); $bitmap.Dispose(); $stream.Dispose() }
}
function Write-Icon([string]$relativePath, [int]$size, [double]$scale = 1.0) {
    $target = Join-Path $projectRoot $relativePath
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
    [IO.File]::WriteAllBytes($target, (New-IconPng $size $scale))
}
function Write-BrowserIcons {
    # The separate circular ImageGen master has genuine alpha. Preserve it;
    # native/App Store icons continue using the existing opaque master.
    $browserSource = [Drawing.Image]::FromFile((Join-Path $projectRoot 'assets/branding/browser_icon_round.png'))
    try {
        $targets = @{ 'web/favicon.png'=32; 'web/favicon-round-v2.png'=64; 'web/icons/Icon-round-192.png'=192; 'web/icons/Icon-round-512.png'=512 }
        foreach ($target in $targets.Keys) {
            $size = $targets[$target]
            $bitmap = [Drawing.Bitmap]::new($size, $size, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $graphics = [Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.Clear([Drawing.Color]::Transparent)
                $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $graphics.DrawImage($browserSource, 0, 0, $size, $size)
                $bitmap.Save((Join-Path $projectRoot $target), [Drawing.Imaging.ImageFormat]::Png)
            } finally { $graphics.Dispose(); $bitmap.Dispose() }
        }
    } finally { $browserSource.Dispose() }
}
try {
    if ($WebOnly) {
        Write-BrowserIcons
        Write-Output 'Updated only browser icons, preserving transparent corners.'
        return
    }
    $densities = @{ mdpi=48; hdpi=72; xhdpi=96; xxhdpi=144; xxxhdpi=192 }
    foreach ($density in $densities.Keys) {
        Write-Icon "android/app/src/main/res/mipmap-$density/ic_launcher.png" $densities[$density]
        Write-Icon "android/app/src/main/res/mipmap-$density/ic_launcher_foreground.png" ([int]($densities[$density] * 2.25)) 0.78
    }
    foreach ($catalog in @('ios/Runner/Assets.xcassets/AppIcon.appiconset', 'macos/Runner/Assets.xcassets/AppIcon.appiconset')) {
        $contents = Get-Content (Join-Path $projectRoot "$catalog/Contents.json") -Raw | ConvertFrom-Json
        foreach ($entry in $contents.images) {
            $points = [double]::Parse(($entry.size -split 'x')[0], [Globalization.CultureInfo]::InvariantCulture)
            $factor = [double]::Parse($entry.scale.TrimEnd('x'), [Globalization.CultureInfo]::InvariantCulture)
            Write-Icon "$catalog/$($entry.filename)" ([int]($points * $factor))
        }
    }
    Write-BrowserIcons
    foreach ($size in @(192,512)) {
        Write-Icon "web/icons/Icon-$size.png" $size
        Write-Icon "web/icons/Icon-maskable-$size.png" $size 0.78
    }
    Write-Icon 'linux/resources/com.example.translator.png' 256
    $sizes = @(16,24,32,48,64,128,256)
    $frames = @($sizes | ForEach-Object { ,(New-IconPng $_) })
    $ico = New-Object IO.MemoryStream
    $writer = New-Object IO.BinaryWriter($ico)
    try {
        $writer.Write([uint16]0)
        $writer.Write([uint16]1)
        $writer.Write([uint16]$sizes.Count)
        $offset = 6 + 16 * $sizes.Count
        for ($i=0; $i -lt $sizes.Count; $i++) {
            $edge = if ($sizes[$i] -eq 256) { 0 } else { $sizes[$i] }
            $writer.Write([byte]$edge); $writer.Write([byte]$edge)
            $writer.Write([byte]0); $writer.Write([byte]0)
            $writer.Write([uint16]1); $writer.Write([uint16]32)
            $writer.Write([uint32]$frames[$i].Length); $writer.Write([uint32]$offset)
            $offset += $frames[$i].Length
        }
        foreach ($frame in $frames) { $writer.Write([byte[]]$frame) }
        [IO.File]::WriteAllBytes((Join-Path $projectRoot 'windows/runner/resources/app_icon.ico'), $ico.ToArray())
    } finally { $writer.Dispose(); $ico.Dispose() }
    Write-Output 'Updated Android, iOS, macOS, Windows, Linux and Web icons.'
} finally { $source.Dispose() }
