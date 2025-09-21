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

# Additional prompts for WooCommerce sites
$ArchiveUrl = ""
$ProductUrl = ""
$ArchiveElement = ""
$AddToCartElement = ""

if ($Type -eq "woocommerce") {
    Write-Host "`n🛍️ WooCommerce Configuration" -ForegroundColor Yellow
    Write-Host "We need to configure monitoring for key shop pages:" -ForegroundColor White
    
    # Shop/Archive page
    Write-Host "`n📦 SHOP ARCHIVE PAGE:" -ForegroundColor Cyan
    Write-Host "  This is your main shop or category page where products are listed" -ForegroundColor Gray
    Write-Host "  Examples: /shop/, /products/, /category/clothing/, /store/" -ForegroundColor Gray
    $ArchiveUrl = Read-Host "Enter shop/archive page path (include leading slash)"
    if (-not $ArchiveUrl.StartsWith('/')) {
        $ArchiveUrl = '/' + $ArchiveUrl
    }
    
    # Product page
    Write-Host "`n🛒 PRODUCT PAGE:" -ForegroundColor Cyan  
    Write-Host "  Choose a real product page to test add-to-cart functionality" -ForegroundColor Gray
    Write-Host "  Examples: /product/sample-item/, /shop/t-shirt/, /products/123/" -ForegroundColor Gray
    $ProductUrl = Read-Host "Enter a product page path (include leading slash)"
    if (-not $ProductUrl.StartsWith('/')) {
        $ProductUrl = '/' + $ProductUrl
    }
    
    # Archive element
    Write-Host "`n🎯 ARCHIVE ELEMENT:" -ForegroundColor Cyan
    Write-Host "  CSS class/element that proves the product listing loaded correctly" -ForegroundColor Gray
    Write-Host "  Examples: 'products-grid', 'woocommerce-loop', 'product-item', 'shop-products'" -ForegroundColor Gray
    Write-Host "  Look for a wrapper div around your product listings" -ForegroundColor Gray
    $ArchiveElement = Read-Host "Enter archive element (no quotes or dots needed)"
    
    # Add to cart element  
    Write-Host "`n🛒 ADD TO CART ELEMENT:" -ForegroundColor Cyan
    Write-Host "  CSS class/element that proves add-to-cart functionality is working" -ForegroundColor Gray
    Write-Host "  Examples: 'single_add_to_cart_button', 'add-to-cart', 'btn-add-cart'" -ForegroundColor Gray
    Write-Host "  This should be your add-to-cart button class or ID" -ForegroundColor Gray
    $AddToCartElement = Read-Host "Enter add-to-cart element (no quotes or dots needed)"
    
    Write-Host "`n✅ Configuration Summary:" -ForegroundColor Green
    Write-Host "  Archive URL: $CleanUrl$ArchiveUrl" -ForegroundColor White
    Write-Host "  Product URL: $CleanUrl$ProductUrl" -ForegroundColor White  
    Write-Host "  Archive Element: $ArchiveElement" -ForegroundColor White
    Write-Host "  Add to Cart Element: $AddToCartElement" -ForegroundColor White
    
    $Confirm = Read-Host "`nDoes this look correct? (Y/n)"
    if ($Confirm -eq "n" -or $Confirm -eq "N") {
        Write-Host "Aborted. Please run the script again." -ForegroundColor Yellow
        exit 0
    }
}

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

# WooCommerce-specific replacements
if ($Type -eq "woocommerce") {
    $Config = $Config `
        -replace "\{\{ARCHIVE_URL\}\}", $ArchiveUrl `
        -replace "\{\{PRODUCT_URL\}\}", $ProductUrl `
        -replace "\{\{ARCHIVE_ELEMENT\}\}", $ArchiveElement `
        -replace "\{\{ADD_TO_CART_ELEMENT\}\}", $AddToCartElement
}

# Save the new configuration
$Config | Set-Content -Path $ConfigPath -Encoding UTF8

Write-Host "`n✅ Created: $ConfigPath" -ForegroundColor Green

# Check if Slack webhook variable exists in .env
$EnvFile = ".env"
if (Test-Path $EnvFile) {
    $EnvContent = Get-Content $EnvFile -Raw
    if ($EnvContent -notmatch $SlackWebhookVar) {
        Write-Host "`n📋 TODO: Add Slack webhook to .env file:" -ForegroundColor Yellow
        Write-Host "$SlackWebhookVar=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK" -ForegroundColor Yellow
    }
}

Write-Host "`nNext steps:" -ForegroundColor Green
Write-Host "1. Add Slack webhook to .env if needed" -ForegroundColor White
Write-Host "2. Manually add the new endpoints to config\gatus.yaml" -ForegroundColor White
Write-Host "3. Run: .\scripts\validate.ps1 to test configuration" -ForegroundColor White
Write-Host "4. Run: .\scripts\deploy.ps1 to push to server" -ForegroundColor White
Write-Host "5. Monitor: https://monitor.webifyseo.com/" -ForegroundColor White

if ($Type -eq "woocommerce") {
    Write-Host "`nMonitoring Schedule:" -ForegroundColor Cyan
    Write-Host "  - Server Health: Every 60 seconds" -ForegroundColor White
    Write-Host "  - Checkout: Every 180 seconds" -ForegroundColor White
    Write-Host "  - Shop Archive: Every 300 seconds" -ForegroundColor White
    Write-Host "  - Product Engine: Every 300 seconds" -ForegroundColor White
}