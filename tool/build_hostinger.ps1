param(
    [string]$BaseHref = '/projects/VoxLingo/'
)

# Builds a deployable archive with PHP, Apache rules and Flutter Web, NEVER keys.env.
$ErrorActionPreference = 'Stop'
if (-not ($BaseHref.StartsWith('/') -and $BaseHref.EndsWith('/'))) {
    throw 'BaseHref must start and end with /, for example /apps/voxlingo/.'
}
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    # Web uses the sibling backend/ on the same origin. Keep provider keys server-side.
    & flutter build web --release "--base-href=$BaseHref" --no-web-resources-cdn
    if ($LASTEXITCODE -ne 0) { throw 'Flutter Web build failed' }
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $webRoot = Join-Path $projectRoot 'build/web'
    # Flutter tree-shakes the icon font. Publish it with UI-only updates too,
    # under a content-specific URL so a new glyph cannot use an old cached font.
    $fontRelative = 'assets/fonts/MaterialIcons-Regular.otf'
    $fontPath = Join-Path $webRoot $fontRelative
    $fontHash = (Get-FileHash -LiteralPath $fontPath -Algorithm SHA256).Hash.Substring(0, 16).ToLowerInvariant()
    $versionedFont = "assets/fonts/MaterialIcons-Regular.$fontHash.otf"
    Copy-Item -LiteralPath $fontPath -Destination (Join-Path $webRoot $versionedFont)
    $fontManifestPath = Join-Path $webRoot 'assets/FontManifest.json'
    $fontManifest = [IO.File]::ReadAllText($fontManifestPath)
    if (-not $fontManifest.Contains('fonts/MaterialIcons-Regular.otf')) {
        throw 'Unexpected Flutter font manifest; cannot version the icon font safely.'
    }
    $fontManifest = $fontManifest.Replace('fonts/MaterialIcons-Regular.otf', "fonts/MaterialIcons-Regular.$fontHash.otf")
    [IO.File]::WriteAllText($fontManifestPath, $fontManifest, [Text.UTF8Encoding]::new($false))
    # Content-addressed entrypoints prevent old browser/CDN copies from being
    # mixed with a new deployment. Only generated build output is rewritten.
    $mainPath = Join-Path $webRoot 'main.dart.js'
    $mainName = 'main.' + (Get-FileHash -LiteralPath $mainPath -Algorithm SHA256).Hash.Substring(0, 16).ToLowerInvariant() + '.dart.js'
    $bootstrapPath = Join-Path $webRoot 'flutter_bootstrap.js'
    $bootstrap = [IO.File]::ReadAllText($bootstrapPath)
    if (-not $bootstrap.Contains('"mainJsPath":"main.dart.js"')) {
        throw 'Unexpected Flutter loader format; cannot version the entrypoint safely.'
    }
    $bootstrap = $bootstrap.Replace('"mainJsPath":"main.dart.js"', ('"mainJsPath":"' + $mainName + '"'))
    $utf8 = [Text.UTF8Encoding]::new($false)
    [IO.File]::WriteAllText($bootstrapPath, $bootstrap, $utf8)
    $bootstrapName = 'flutter_bootstrap.' + (Get-FileHash -LiteralPath $bootstrapPath -Algorithm SHA256).Hash.Substring(0, 16).ToLowerInvariant() + '.js'
    Copy-Item -LiteralPath $mainPath -Destination (Join-Path $webRoot $mainName)
    Copy-Item -LiteralPath $bootstrapPath -Destination (Join-Path $webRoot $bootstrapName)
    $indexPath = Join-Path $webRoot 'index.html'
    $index = [IO.File]::ReadAllText($indexPath)
    if (-not $index.Contains('src="flutter_bootstrap.js"')) {
        throw 'Unexpected Flutter index format; cannot version the bootstrap safely.'
    }
    $index = $index.Replace('src="flutter_bootstrap.js"', ('src="' + $bootstrapName + '"'))
    [IO.File]::WriteAllText($indexPath, $index, $utf8)
    $archivePath = Join-Path $projectRoot 'build/VoxLingo-hostinger.zip'
    $stream = [IO.File]::Open($archivePath, [IO.FileMode]::Create)
    $archive = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($file in Get-ChildItem -LiteralPath $webRoot -Recurse -File -Force) {
            $relative = $file.FullName.Substring($webRoot.Length + 1).Replace('\','/')
            if ($relative -match '(^|/)(keys\.env.*|\.htaccess|\.last_build_id)$' -or $relative -match '\.(env|zip)$' -or $relative.StartsWith('backend/')) { continue }
            if ($relative -match '^(?:main\.[a-f0-9]+\.dart\.js|flutter_bootstrap\.[a-f0-9]+\.js)$' -and $relative -notin @($mainName, $bootstrapName)) { continue }
            [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $relative)
        }
        foreach ($relative in @('.htaccess','backend/index.php','backend/.htaccess')) {
            [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, (Join-Path $projectRoot $relative), $relative)
        }
    } finally { $archive.Dispose(); $stream.Dispose() }
    Write-Output "Ready: $archivePath (no keys.env or credentials)."
    # Small recovery upload for an already deployed site. No PHP, env or DB.
    $updatePath = Join-Path $projectRoot 'build/VoxLingo-web-update.zip'
    $stream = [IO.File]::Open($updatePath, [IO.FileMode]::Create)
    $archive = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($relative in @('index.html', $mainName, $bootstrapName, 'manifest.json', 'favicon.png', 'favicon-round-v2.png', 'icons/Icon-round-192.png', 'icons/Icon-round-512.png', 'assets/FontManifest.json', $fontRelative, $versionedFont)) {
            [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, (Join-Path $webRoot $relative), $relative)
        }
    } finally { $archive.Dispose(); $stream.Dispose() }
    Write-Output "Web-only update: $updatePath"
} finally { Pop-Location }
