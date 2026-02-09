param (
    [string]$InputFile,
    [string]$OutputFile = $InputFile+".enriched"
)

$ErrorActionPreference = "Stop"

function Invoke-RestMethodWithRetry {
    param(
        [string]$Uri,
        [string]$Method = "Get",
        [hashtable]$Headers = @{},
        [object]$Body = $null,
        [int]$MaxRetries = 5
    )

    $attempt = 0
    while ($attempt -lt $MaxRetries) {
        try {
            return Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Headers -Body $Body
        } catch [System.Net.WebException]{
            if ($_.Exception.Response.StatusCode.Value__ -ne 429) {
                throw $_
            }       
            
            $retryAfterHeader = $_.Exception.Response.Headers["Retry-After"]
            Write-Host "Received 429 Too Many Requests. Retry-After header: $retryAfterHeader"

            $retryAfter = $retryAfterHeader ?? 5
            Write-Host "Retrying after $retryAfter seconds..."
            Start-Sleep -Seconds $retryAfter
        }
    }

    throw "Failed after $MaxRetries attempts due to rate limits."
}

function Get-IgdbAccessToken {
    if (!$env:IGDB_CLIENT_ID -or !$env:IGDB_CLIENT_SECRET) {
        throw "Environment variables IGDB_CLIENT_ID and IGDB_CLIENT_SECRET must be set."
    }

    $response = Invoke-RestMethod -Method Post -Uri "https://id.twitch.tv/oauth2/token" -Body @{
        client_id     = $env:IGDB_CLIENT_ID
        client_secret = $env:IGDB_CLIENT_SECRET
        grant_type    = "client_credentials"
    }

    return $response.access_token
}

function Get-IgdbGameData ([string]$GameName, [string]$AccessToken) {
    $cleanGameName = Convert-GameName -Name $GameName
    Write-Host "Querying IGDB for '$cleanGameName'..."
    return Invoke-RestMethodWithRetry -Method Post -Uri "https://api.igdb.com/v4/games" `
        -Headers @{
            "Client-ID" = $env:IGDB_CLIENT_ID
            "Authorization" = "Bearer $AccessToken"
        } `
        -Body @"
search "$cleanGameName";
fields name, first_release_date, genres.name;
limit 1;
"@
}

function Convert-GameLine ([string]$line) {
    return ($line -replace "PC only", "").Trim()
}

function Convert-GameName([string]$Name) {
    #remove: "[2023]" or similar year tags, " Deluxe Ed." or similar edition tags, "(U)" Ultimate exclusive tags, "(ESS)" Game Pass Essential tags
    return $Name `
        -replace '\[\d{4}\]', '' `
        -replace "\(U\)", "" `
        -replace "\(ESS\)", "" `
        -replace '[^a-zA-Z0-9 ]', '' `
        -replace '\s\w+\sEd\b', ''
}

function Get-ReleaseDate ([int]$UnixTimestamp) {
    return (Get-Date "1970-01-01").AddSeconds($UnixTimestamp).ToString("yyyy-MM-dd")
}

$token = Get-IgdbAccessToken

Write-Host "Enriching game data from '$InputFile' and saving to '$OutputFile'..."
"MC_Score`tGame_Name`tRelease_Date`tGenres" | Out-File $OutputFile -Encoding UTF8

$games = Get-Content -LiteralPath $InputFile | Where-Object { ![string]::IsNullOrWhiteSpace($_) } | Foreach-Object { Convert-GameLine $_ }
foreach ($line in $games) {
    Write-Host "Processing: $line"
    $parts = $line -split "`t", 2
    if ($parts.Count -ne 2) {
        throw "Invalid line format: '$line'. Expected format: 'MC_Score<TAB>Game_Name'"     
    }

    $mcScore = $parts[0].Trim()
    $gameName = $parts[1].Trim()

    $response = Get-IgdbGameData -GameName $gameName -AccessToken $token
    if ($response.Count -eq 0) {
        Write-Warning "No data found for '$gameName'. Writing placeholders."
        "$mcScore`t$gameName`tTBD`tTBD" | Out-File $OutputFile -Append -Encoding UTF8
        continue
    } 

    $game = $response[0]
    $releaseDate = Get-ReleaseDate -UnixTimestamp $game.first_release_date
    $resolvedName = $game.name
    $genres = ($game.genres | ForEach-Object { $_.name }) -join ", "
    
    if ($resolvedName -ne $gameName) {
        Write-Warning "Resolved name '$resolvedName' differs from original '$gameName'"
    }
    "$mcScore`t$gameName`t$resolvedName`t$releaseDate`t$genres" | Out-File $OutputFile -Append -Encoding UTF8
}

Write-Host "Finished. Output saved to $OutputFile"