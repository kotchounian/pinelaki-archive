$pagesDir = "C:\Users\User\Documents\Antigravity\pinelaki-content-backup\pages"
$mediaDir = "C:\Users\User\Documents\Antigravity\pinelaki-content-backup\media"
$mapFile  = "C:\Users\User\Documents\Antigravity\pinelaki-content-backup\media-map.json"

New-Item -ItemType Directory -Force -Path $mediaDir | Out-Null

$imgPattern = [regex]'!\[.*?\]\((https?://[^\)]+)\)'
$srcPattern = [regex]'src="(https?://pinelaki\.com[^"]+)"'
$wpUpload   = [regex]'(https?://pinelaki\.com/wp-content/uploads/[^\s\)\]"'']+)'

$mediaMap  = @{}
$allImages = [System.Collections.Generic.Dictionary[string,string]]::new()  # url -> localPath

$files = Get-ChildItem -Path $pagesDir -Filter "*.md"

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName)
    $pageUrl = ""
    if ($content -match "url: (.+)") { $pageUrl = $Matches[1].Trim() }

    $urls = [System.Collections.Generic.List[string]]::new()
    foreach ($m in $imgPattern.Matches($content)) { $urls.Add($m.Groups[1].Value.Trim()) }
    foreach ($m in $srcPattern.Matches($content)) { $urls.Add($m.Groups[1].Value.Trim()) }
    foreach ($m in $wpUpload.Matches($content))   { $urls.Add($m.Groups[1].Value.Trim()) }

    $filtered = $urls | Where-Object { $_ -match 'pinelaki\.com/wp-content/uploads/' } | Sort-Object -Unique

    $pageImages = [System.Collections.Generic.List[object]]::new()
    foreach ($imgUrl in $filtered) {
        $imgUrl = $imgUrl.TrimEnd('"', "'", ')', ']', ' ')
        try {
            $uri     = [System.Uri]$imgUrl
            $relPath = $uri.AbsolutePath.TrimStart('/')
            $safe    = $relPath -replace '[\\:*?"<>|]', '_'
            $localRel = "media/" + $safe
            $localAbs = "C:\Users\User\Documents\Antigravity\pinelaki-content-backup\" + ($safe -replace '/', '\')

            $pageImages.Add([PSCustomObject]@{ url = $imgUrl; localPath = $localRel })

            if (-not $allImages.ContainsKey($imgUrl)) {
                $allImages[$imgUrl] = $localAbs
            }
        } catch {}
    }

    if ($pageImages.Count -gt 0 -and $pageUrl) {
        $mediaMap[$pageUrl] = $pageImages
    }
}

Write-Host "Found $($allImages.Count) unique images to download"

$headers = @{
    "User-Agent"      = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    "Accept"          = "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8"
    "Accept-Language" = "en-US,en;q=0.9"
    "Referer"         = "https://pinelaki.com/"
    "sec-ch-ua"       = '"Chromium";v="122", "Not(A:Brand";v="24", "Google Chrome";v="122"'
}

$ok   = 0
$fail = 0
$i    = 0

foreach ($kv in $allImages.GetEnumerator()) {
    $imgUrl  = $kv.Key
    $localAbs = $kv.Value
    $i++

    $dir = Split-Path $localAbs -Parent
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    try {
        $response = Invoke-WebRequest -Uri $imgUrl -Headers $headers -OutFile $localAbs -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
        $ok++
        $filename = Split-Path $imgUrl -Leaf
        Write-Host "[$i/$($allImages.Count)] OK  $filename" -ForegroundColor Green
    } catch {
        $fail++
        $filename = Split-Path $imgUrl -Leaf
        Write-Host "[$i/$($allImages.Count)] ERR $filename — $($_.Exception.Message)" -ForegroundColor Red
    }

    Start-Sleep -Milliseconds 200
}

# Save media-map.json
$jsonStr = $mediaMap | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($mapFile, $jsonStr, [System.Text.Encoding]::UTF8)

Write-Host ""
Write-Host "=== Complete ==="
Write-Host "Unique images : $($allImages.Count)"
Write-Host "Downloaded OK : $ok"
Write-Host "Failed        : $fail"
Write-Host "Map file      : $mapFile"
