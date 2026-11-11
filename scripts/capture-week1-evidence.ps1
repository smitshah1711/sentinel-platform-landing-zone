<#
  Runs the four Week 1 verification checks and saves each result as a PNG
  in docs/screenshots/week-1/. The images show the real command and its real
  output, rendered as a terminal window. No emails are printed by these commands.

  Usage (from the repo root, after `aws sso login --sso-session sentinel`):
    powershell -ExecutionPolicy Bypass -File .\scripts\capture-week1-evidence.ps1
#>
param([string]$OutDir = "docs/screenshots/week-1")

$ErrorActionPreference = "Continue"
Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$checks = @(
  @{ File = "01-sso-identity.png"
     Title = "Check 1 - SSO sign-in: PlatformAdmin in the dev account"
     Cmd = 'aws sts get-caller-identity --profile sentinel-dev' },
  @{ File = "02-scp-region-deny.png"
     Title = "Check 2 - SCP blocks a non-approved region (eu-west-1), even for an admin"
     Cmd = 'aws ec2 describe-vpcs --region eu-west-1 --profile sentinel-dev' },
  @{ File = "03-allowed-region.png"
     Title = "Check 3 - Approved region (ca-central-1) still works"
     Cmd = 'aws ec2 describe-vpcs --region ca-central-1 --profile sentinel-dev --query "Vpcs[].[VpcId,CidrBlock,IsDefault]" --output table' },
  @{ File = "04-org-cloudtrail-logs.png"
     Title = "Check 4 - Organization CloudTrail: every account logging to log-archive"
     Cmd = 'aws s3 ls s3://sentinel-org-cloudtrail-573472276804-ca-central-1/AWSLogs/o-vswb9g6eug/ --profile sentinel-log-archive' }
)

function Split-Line([string]$s, [int]$width) {
  # Wrap at spaces where possible so words are not cut in half.
  $parts = @()
  while ($s.Length -gt $width) {
    $cut = $s.LastIndexOf(" ", $width)
    if ($cut -lt [int]($width / 2)) { $cut = $width }
    $parts += $s.Substring(0, $cut)
    $s = "  " + $s.Substring($cut).TrimStart()
  }
  $parts += $s
  return $parts
}

function Save-TerminalImage($title, $cmd, $lines, $path) {
  $font      = New-Object System.Drawing.Font("Consolas", 13)
  $titleFont = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
  $smallFont = New-Object System.Drawing.Font("Segoe UI", 9)

  $green = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(106, 200, 120))
  $red   = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(244, 135, 113))
  $grey  = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(220, 220, 220))

  # Colour is decided per original line, then kept for every wrapped piece of it.
  $text = @("PS> $cmd", "") + $lines
  $wrapped = @(); $brushes = @()
  foreach ($l in $text) {
    $line = ([string]$l).TrimEnd()
    $brush = $grey
    if ($line.StartsWith("PS> ")) { $brush = $green }
    elseif ($line -match "error|explicit deny|not authorized") { $brush = $red }
    foreach ($piece in (Split-Line $line 110)) { $wrapped += $piece; $brushes += $brush }
  }

  $probe = New-Object System.Drawing.Bitmap 1, 1
  $pg = [System.Drawing.Graphics]::FromImage($probe)
  $maxW = ($wrapped | ForEach-Object { $pg.MeasureString($_, $font).Width } | Measure-Object -Maximum).Maximum
  $lineH = [int]($font.GetHeight($pg) + 3)
  $pg.Dispose(); $probe.Dispose()

  $width  = [int][Math]::Max(960, $maxW + 56)
  $height = 64 + ($lineH * $wrapped.Count) + 40

  $bmp = New-Object System.Drawing.Bitmap $width, $height
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $g.Clear([System.Drawing.Color]::FromArgb(30, 30, 30))
  $g.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(45, 45, 48))), 0, 0, $width, 42)
  foreach ($dot in @(@(16, 237, 106, 94), @(36, 245, 191, 79), @(56, 98, 197, 84))) {
    $g.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($dot[1], $dot[2], $dot[3]))), $dot[0], 15, 12, 12)
  }
  $g.DrawString($title, $titleFont, [System.Drawing.Brushes]::White, 80, 11)

  $y = 56
  for ($i = 0; $i -lt $wrapped.Count; $i++) {
    $g.DrawString($wrapped[$i], $font, $brushes[$i], 24, $y)
    $y += $lineH
  }
  $stamp = "Captured " + (Get-Date -Format "yyyy-MM-dd HH:mm zzz") + "  |  Sentinel / platform-landing-zone  |  real CLI output"
  $g.DrawString($stamp, $smallFont, [System.Drawing.Brushes]::Gray, 24, $height - 26)

  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
}

# Make sure the SSO session is valid before capturing.
aws sts get-caller-identity --profile sentinel-dev 1>$null 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "SSO session expired - opening browser to sign in..." -ForegroundColor Yellow
  aws sso login --sso-session sentinel
}

foreach ($c in $checks) {
  Write-Host "Running: $($c.Cmd)" -ForegroundColor Cyan
  # 2>&1 wraps native stderr in RemoteException records; keep only the message text.
  $out = Invoke-Expression "$($c.Cmd) 2>&1" | ForEach-Object { "$_" } |
    Where-Object { $_ -ne "System.Management.Automation.RemoteException" }
  $out | ForEach-Object { Write-Host $_ }
  $path = Join-Path $OutDir $c.File
  Save-TerminalImage $c.Title $c.Cmd $out $path
  Write-Host "Saved $path" -ForegroundColor Green
  Write-Host ""
}
