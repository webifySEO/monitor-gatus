# New Site Script for Gatus Monitoring
# Usage: .\scripts\new-site.ps1 -type woocommerce -url "https://shop.example.com" -name "Example Shop"

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("woocommerce", "wordpress", "static-site")]
    [string]$Type,
    
    [Parameter(Mandatory=$true)]
    [string]$Url,
    
    [Parameter(Mandatory=$true)]
    [string]$Name,
    
    [Parameter(Mandatory=$false)]
    [string]$SlackWebhookVar = ""
)

# Validate URL format
if ($Url -notmatch "^https?://") {
    Write-Error "URL must start with http:// or https://"
    exit 1
}

# Extract domain from URL
$Domain = ([System.Uri]$Url).Host

# Generate slug from domain (remove subdomain if present, clean up special chars)
$Slug = $Domain -replace "^www\.", "" -replace "\.", "-" -replace "[^a-zA-Z0-9-]", ""

# If no Slack webhook variable provided, generate one
if ([string]::IsNullOrEmpty($SlackWebhookVar)) {
    $SlackWebhookVar = "CLIENT_" + $Slug.ToUpper() + "_SLACK"
}

# Clean URL (remove trailing slash)
$CleanUrl = $Url.TrimEnd('/')

Write-Host "Creating new monitoring configuration..." -ForegroundColor Green
Write-Host "  Type: $Type" -ForegroundColor Cyan
Write-Host "  Name: $Name" -ForegroundColor Cyan
Write-Host "  URL: $CleanUrl" -ForegroundColor Cyan
Write-Host "  Domain: $Domain" -ForegroundColor Cyan
Write-Host "  Slug: $Slug" -ForegroundColor Cyan
Write-Host "  Slack Variable: $SlackWebhookVar" -ForegroundColor Cyan

# Check if site config already exists
$ConfigPath = "config\sites\$Slug.yaml"
if (Test-Path $ConfigPath) {
    Write-Warning "Configuration file $ConfigPath already exists!"
    $Overwrite = Read-Host "Do you want to overwrite it? (y/N)"
    if ($Overwrite -ne "y" -and $Overwrite -ne "Y") {
        Write-Host "Aborted." -ForegroundColor Yellow
        exit 0
    }
}

# Load template
$TemplatePath = "templates\$Type.yaml.template"
if (-not (Test-Path $TemplatePath)) {
    Write-Error "Template $TemplatePath not found!"
    exit 1
}

$Template = Get-Content $TemplatePath -Raw

# Replace placeholders
$Config = $Template `
    -replace "\{\{SITE_NAME\}\}", $Name `
    -replace "\{\{SITE_URL\}\}", $CleanUrl `
    -replace "\{\{SITE_DOMAIN\}\}", $Domain `
    -replace "\{\{SITE_SLUG\}\}", $Slug `
    -replace "\{\{SLACK_WEBHOOK_VAR\}\}", $SlackWebhookVar

# Save the new configuration
$Config | Set-Content -Path $ConfigPath -Encoding UTF8

Write-Host "`nCreated: $ConfigPath" -ForegroundColor Green

# Add to main gatus.yaml (append the new site)
$GatusConfig = Get-Content "config\gatus.yaml" -Raw

# Check if this site is already included
if ($GatusConfig -notmatch "CLIENT: " + $Name.ToUpper()) {
    $NewInclude = "`n  # CLIENT: " + $Name.ToUpper() + "`n" + (Get-Content $ConfigPath -Raw)
    
    # Insert before the last endpoint (find a good insertion point)
    $GatusConfig = $GatusConfig -replace "(  - name: .* TLS\s+group: certificates.*?\[CERTIFICATE_EXPIRATION.*?\].*?240h.*?)$", "`$1$NewInclude"
    
    $GatusConfig | Set-Content -Path "config\gatus.yaml" -Encoding UTF8
    Write-Host "Updated: config\gatus.yaml" -ForegroundColor Green
}

# Check if Slack webhook variable exists in .env
$EnvFile = ".env"
if (Test-Path $EnvFile) {
    $EnvContent = Get-Content $EnvFile -Raw
    if ($EnvContent -notmatch $SlackWebhookVar) {
        Write-Host "`nTODO: Add Slack webhook to .env file:" -ForegroundColor Yellow
        Write-Host "$SlackWebhookVar=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK" -ForegroundColor Yellow
    }
}

Write-Host "`nNext steps:" -ForegroundColor Green
Write-Host "1. Add Slack webhook to .env if needed" -ForegroundColor White
Write-Host "2. Run: .\scripts\validate.ps1 to test configuration" -ForegroundColor White
Write-Host "3. Run: .\scripts\deploy.ps1 to push to server" -ForegroundColor White
Write-Host "4. Monitor: https://monitor.webifyseo.com/" -ForegroundColor White