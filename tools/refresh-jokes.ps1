<#
.SYNOPSIS
  Calls Google Gemini Flash (AI Studio) to generate shop jokes and bakes them
  into the SHOP_JOKES[] array in okuma.cps, between the SHOP_JOKES_BEGIN /
  SHOP_JOKES_END marker comments.

.WHY
  Fusion post processors (.cps) run in a sandbox with no network access, so the
  post itself can't call Gemini. This script is the "online" half: it makes the
  API call and rewrites the post's joke pool in place. The post just picks one
  at random per program.

.SETUP
  1. Get a free API key from https://aistudio.google.com/apikey
  2. Set it (PowerShell, persists for your user):
       setx GEMINI_API_KEY "your-key-here"
     ...then open a NEW terminal so $env:GEMINI_API_KEY is populated.

.USAGE
  pwsh ./tools/refresh-jokes.ps1                 # 30 jokes, default model
  pwsh ./tools/refresh-jokes.ps1 -Count 50
  pwsh ./tools/refresh-jokes.ps1 -Model gemini-2.0-flash
  pwsh ./tools/refresh-jokes.ps1 -DryRun        # print jokes, don't touch the post

.SCHEDULE (optional, refresh weekly)
  $action  = New-ScheduledTaskAction -Execute "pwsh.exe" `
             -Argument '-File "C:\Users\Derek\AppData\Roaming\Autodesk\Fusion 360 CAM\Posts\tools\refresh-jokes.ps1"'
  $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 6am
  Register-ScheduledTask -TaskName "Refresh shop jokes" -Action $action -Trigger $trigger
#>

[CmdletBinding()]
param(
  [int]    $Count   = 30,
  [string] $Model   = "gemini-2.5-flash",
  [string] $PostPath = (Join-Path $PSScriptRoot ".." | Join-Path -ChildPath "okuma.cps"),
  [switch] $DryRun
)

$ErrorActionPreference = "Stop"

$apiKey = $env:GEMINI_API_KEY
if (-not $apiKey) {
  throw "GEMINI_API_KEY is not set. Get a key at https://aistudio.google.com/apikey then run: setx GEMINI_API_KEY ""your-key"" (and open a new terminal)."
}

$PostPath = (Resolve-Path $PostPath).Path

# ---- The prompt. THIS is the knob to tune the flavor. -----------------------
# Audience: Paul, 60yo machinist, wild/crude sense of humor, + shop coworkers.
# Goal: blue-collar, innuendo-heavy machine-shop ribbing. Crude but not hateful.
$prompt = @"
You write one-line jokes that get printed as a comment in the header of CNC
machine programs at a small machine shop.

Audience: a 60-year-old machinist named Paul who has a wild, filthy, locker-room
sense of humor, plus his coworkers. They trade crude ribbing on the shop floor
all day. Make Paul laugh.

Voice: blue-collar machine-shop humor. Crude, cheeky, innuendo-heavy. Lean HARD
into machining double-entendres -- tight tolerances, deep holes, boring bars,
running it balls out, feeds and speeds, tapping, chucks and collets, hard vs
soft jaws, deflection, backlash, chip load, lubrication and coolant, finishing
passes, getting chips everywhere. Dry one-liners and dad-joke puns both welcome.
Funny first, filthy second.

Hard limits (do NOT cross -- these keep us out of HR trouble):
- Innuendo and crude, yes; explicit/graphic sex acts, no.
- NO slurs or bigotry of any kind. Nothing about race, religion, nationality,
  sexual orientation, gender identity, disability, or body-shaming.
- Nothing sexual involving minors. Nothing about violence, weapons, or self-harm.
- No politics. No naming or mocking real public figures. Keep it good-natured
  ribbing among buddies, never mean-spirited.

Format rules (strict):
- Return ONLY a JSON array of exactly $Count strings.
- Each string is one complete, standalone joke or one-liner.
- Max 68 characters each.
- Plain ASCII only. Allowed punctuation: . , - : / and spaces. NO apostrophes,
  NO quotation marks, NO emoji, NO numbering, NO question/exclamation marks.
  (Write "thats" and "aint" instead of using apostrophes.)
- Make all $Count distinct from each other.
"@

# Gemini structured-output: force a JSON array of strings so parsing is trivial.
$body = @{
  contents = @(
    @{ role = "user"; parts = @(@{ text = $prompt }) }
  )
  generationConfig = @{
    temperature        = 1.2
    responseMimeType   = "application/json"
    responseSchema     = @{
      type  = "ARRAY"
      items = @{ type = "STRING" }
    }
  }
} | ConvertTo-Json -Depth 12

$uri = "https://generativelanguage.googleapis.com/v1beta/models/${Model}:generateContent"

Write-Host "Calling $Model for $Count jokes..." -ForegroundColor Cyan
$resp = Invoke-RestMethod -Method Post -Uri $uri -Headers @{ "x-goog-api-key" = $apiKey } `
                          -ContentType "application/json" -Body $body

$raw = $resp.candidates[0].content.parts[0].text
if (-not $raw) {
  throw "Empty response from Gemini. Full payload: $($resp | ConvertTo-Json -Depth 12)"
}

$jokes = $raw | ConvertFrom-Json

# ---- Sanitize to exactly what the post's permittedCommentChars allows --------
# permittedCommentChars in okuma.cps: " abcdefghijklmnopqrstuvwxyz0123456789.,=_-:+/*#[]"
# Anything else (apostrophes, quotes, !, ?, backslashes...) the post would strip
# anyway -- we strip here too so the baked array reads clean and is safe to embed.
$allowed = '[^ A-Za-z0-9\.\,\=\-\:\+\/\*\#\[\]]'
$clean = foreach ($j in $jokes) {
  $s = ([string]$j).Trim()
  $s = $s -replace "`r?`n", " "      # no newlines inside an entry
  $s = $s -replace $allowed, ""       # drop disallowed chars
  $s = ($s -replace '\s+', ' ').Trim()
  if ($s.Length -gt 68) { $s = $s.Substring(0, 68).Trim() }
  if ($s) { $s }
}
$clean = $clean | Select-Object -Unique
if (-not $clean -or $clean.Count -eq 0) {
  throw "No usable jokes after sanitizing. Raw response was:`n$raw"
}

Write-Host "Got $($clean.Count) jokes:" -ForegroundColor Green
$clean | ForEach-Object { Write-Host "  - $_" }

if ($DryRun) {
  Write-Host "`n-DryRun set: okuma.cps not modified." -ForegroundColor Yellow
  return
}

# ---- Rebuild the JS array literal and splice it between the markers ----------
$indent = "  "
$lines  = $clean | ForEach-Object { "$indent`"$_`"," }
if ($lines.Count -gt 0) {
  $lines[-1] = $lines[-1].TrimEnd(',')   # no trailing comma on last element
}
$arrayBlock = "var SHOP_JOKES = [`n" + ($lines -join "`n") + "`n];"

$beginMarker = "// >>> SHOP_JOKES_BEGIN"
$endMarker   = "// <<< SHOP_JOKES_END"

$content = Get-Content -Raw -Path $PostPath
$pattern = "(?s)(" + [regex]::Escape($beginMarker) + ".*?\r?\n)(.*?)(\r?\n" + [regex]::Escape($endMarker) + ")"
if ($content -notmatch $pattern) {
  throw "Could not find the SHOP_JOKES markers in $PostPath. Was the post block removed?"
}

$newContent = [regex]::Replace($content, $pattern, {
  param($m)
  $m.Groups[1].Value + $arrayBlock + $m.Groups[3].Value
})

Set-Content -Path $PostPath -Value $newContent -NoNewline -Encoding UTF8
Write-Host "`nUpdated SHOP_JOKES in $PostPath ($($clean.Count) jokes)." -ForegroundColor Green
