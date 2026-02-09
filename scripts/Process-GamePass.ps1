# Read the TSV file
$inputFile = "C:\Users\ohad1\Downloads\GamePass-initial.tsv"
$lines = Get-Content $inputFile

Write-Host "Initial count: $($lines.Count) entries" -ForegroundColor Cyan
Write-Host ""

# Parse all entries
$games = @()
foreach ($line in $lines) {
    if ($line -match '^\s*(\d+|TBD)\s+(.+?)\s*$') {
        $score = $Matches[1]
        $nameAndTags = $Matches[2].Trim()
        
        # Extract tags (looking for patterns like "console only", "cloud only", "Game Preview", etc.)
        $name = $nameAndTags
        $tags = @()
        
        # Check for "console only" tag
        if ($nameAndTags -match '\bconsole only\b') {
            $tags += "console only"
            $name = $nameAndTags -replace '\s*console only\s*', ' '
        }
        
        # Check for "cloud only" tag
        if ($nameAndTags -match '\bcloud only\b') {
            $tags += "cloud only"
            $name = $nameAndTags -replace '\s*cloud only\s*', ' '
        }
        
        # Check for "cloud/console only" tag
        if ($nameAndTags -match '\bcloud/console only\b') {
            $tags += "cloud/console only"
            $name = $nameAndTags -replace '\s*cloud/console only\s*', ' '
        }
        
        # Check for "Game Preview" or "preview"
        if ($nameAndTags -match '\bGame Preview\b' -or $nameAndTags -match '\bpreview\b') {
            $tags += "preview"
            $name = $nameAndTags -replace '\s*Game Preview\s*', ' '
            $name = $name -replace '\s*preview\s*', ' '
        }
        
        # Check for "PC only" tag (keep this for reference but don't filter it)
        if ($nameAndTags -match '\bPC only\b') {
            $tags += "PC only"
            $name = $nameAndTags -replace '\s*PC only\s*', ' '
        }
        
        $name = $name.Trim()
        
        $games += [PSCustomObject]@{
            Score = $score
            Name = $name
            Tags = $tags
            OriginalLine = $line
        }
    }
}

Write-Host "Parsed: $($games.Count) games" -ForegroundColor Green
Write-Host ""

# Filter 1: Remove "console only" entries
Write-Host "Filter 1: Removing 'console only' entries..." -ForegroundColor Yellow
$beforeCount = $games.Count
$games = $games | Where-Object { $_.Tags -notcontains "console only" }
$afterCount = $games.Count
Write-Host "  Before: $beforeCount | After: $afterCount | Removed: $($beforeCount - $afterCount)" -ForegroundColor Magenta
Write-Host ""

# Filter 2: Remove "cloud only" and "cloud/console only" entries
Write-Host "Filter 2: Removing 'cloud only' entries..." -ForegroundColor Yellow
$beforeCount = $games.Count
$games = $games | Where-Object { 
    $_.Tags -notcontains "cloud only" -and $_.Tags -notcontains "cloud/console only"
}
$afterCount = $games.Count
Write-Host "  Before: $beforeCount | After: $afterCount | Removed: $($beforeCount - $afterCount)" -ForegroundColor Magenta
Write-Host ""

# Filter 3: Remove games in preview
Write-Host "Filter 3: Removing games with 'preview' tag..." -ForegroundColor Yellow
$beforeCount = $games.Count
$games = $games | Where-Object { $_.Tags -notcontains "preview" }
$afterCount = $games.Count
Write-Host "  Before: $beforeCount | After: $afterCount | Removed: $($beforeCount - $afterCount)" -ForegroundColor Magenta
Write-Host ""

# Filter 4: Remove games without MC score (TBD or missing)
Write-Host "Filter 4: Removing games without MC score (TBD/missing)..." -ForegroundColor Yellow
$beforeCount = $games.Count
$games = $games | Where-Object { 
    $_.Score -ne "TBD" -and $_.Score -match '^\d+$'
}
$afterCount = $games.Count
Write-Host "  Before: $beforeCount | After: $afterCount | Removed: $($beforeCount - $afterCount)" -ForegroundColor Magenta
Write-Host ""

# Convert scores to integers and sort by score descending
$games = $games | ForEach-Object {
    [PSCustomObject]@{
        mc_score = [int]$_.Score
        game_name = $_.Name
    }
} | Sort-Object -Property mc_score -Descending

# Create JSON output
Write-Host "Final count: $($games.Count) games" -ForegroundColor Green
Write-Host ""
Write-Host "Generating JSON..." -ForegroundColor Cyan

$jsonOutput = $games | ConvertTo-Json -Depth 10
$outputFile = "C:\Dev\GitHub\igdb-enricher\GamePass-Filtered.json"
$jsonOutput | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "JSON saved to: $outputFile" -ForegroundColor Green
Write-Host ""
Write-Host "Preview of top 10 games:" -ForegroundColor Cyan
$games | Select-Object -First 10 | Format-Table -AutoSize

# Also output to console
Write-Host ""
Write-Host "Full JSON:" -ForegroundColor Cyan
$jsonOutput
