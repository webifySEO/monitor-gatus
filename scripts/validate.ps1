# Validate Gatus Configuration Script
# Usage: .\scripts\validate.ps1 [optional-config-file]

param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = "config\gatus.yaml"
)

Write-Host "Validating Gatus configuration..." -ForegroundColor Green

# Check if config file exists
if (-not (Test-Path $ConfigFile)) {
    Write-Error "Configuration file $ConfigFile not found!"
    exit 1
}

Write-Host "✓ Configuration file exists: $ConfigFile" -ForegroundColor Green

# Basic YAML syntax validation (check for common issues)
$ConfigContent = Get-Content $ConfigFile -Raw

# Check for required sections
$RequiredSections = @("storage:", "endpoints:")
foreach ($Section in $RequiredSections) {
    if ($ConfigContent -notmatch $Section) {
        Write-Error "Missing required section: $Section"
        exit 1
    }
}

Write-Host "✓ Required sections present" -ForegroundColor Green

# Check for common YAML syntax issues
$Lines = Get-Content $ConfigFile
$LineNumber = 0
$HasErrors = $false

foreach ($Line in $Lines) {
    $LineNumber++
    
    # Check for tabs (should use spaces)
    if ($Line -match "`t") {
        Write-Warning "Line $LineNumber contains tabs (should use spaces): $Line"
        $HasErrors = $true
    }
    
    # Check for missing spaces after colons
    if ($Line -match ":\w" -and $Line -notmatch "://") {
        Write-Warning "Line $LineNumber missing space after colon: $Line"
        $HasErrors = $true
    }
}

if (-not $HasErrors) {
    Write-Host "✓ Basic YAML syntax looks good" -ForegroundColor Green
}

# Check for referenced environment variables
$EnvVars = @()
if ($ConfigContent -match '\$\{(\w+)\}') {
    $Matches | ForEach-Object {
        if ($_ -match '\$\{(\w+)\}') {
            $EnvVars += $Matches[1]
        }
    }
}

# Check if .env file exists and contains required variables
if ($EnvVars.Count -gt 0) {
    Write-Host "Checking environment variables..." -ForegroundColor Cyan
    
    if (Test-Path ".env") {
        $EnvContent = Get-Content ".env" -Raw
        
        foreach ($Var in $EnvVars | Sort-Object -Unique) {
            if ($EnvContent -match "^$Var=") {
                Write-Host "✓ Environment variable found: $Var" -ForegroundColor Green
            } else {
                Write-Warning "Missing environment variable: $Var"
                $HasErrors = $true
            }
        }
    } else {
        Write-Warning "No .env file found, but configuration references environment variables"
        $HasErrors = $true
    }
}

# Count endpoints
$EndpointMatches = ([regex]::Matches($ConfigContent, "- name:")).Count
Write-Host "✓ Found $EndpointMatches monitoring endpoints" -ForegroundColor Green

# Check site configs exist
$SiteConfigs = Get-ChildItem "config\sites\*.yaml" -ErrorAction SilentlyContinue
if ($SiteConfigs) {
    Write-Host "✓ Found $($SiteConfigs.Count) site configuration files:" -ForegroundColor Green
    foreach ($Site in $SiteConfigs) {
        Write-Host "  - $($Site.Name)" -ForegroundColor White
    }
}

# Final validation with Docker if available
if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "`nTesting with Docker..." -ForegroundColor Cyan
    
    # Try to validate the config using docker compose
    $Result = docker compose config 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Docker Compose configuration valid" -ForegroundColor Green
    } else {
        Write-Warning "Docker Compose validation failed:"
        Write-Host $Result -ForegroundColor Red
        $HasErrors = $true
    }
} else {
    Write-Host "⚠ Docker not available for validation" -ForegroundColor Yellow
    Write-Host "  Install Docker to enable full validation" -ForegroundColor Gray
}

# Summary
if ($HasErrors) {
    Write-Host "`n❌ Configuration has issues that should be fixed" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n✅ Configuration validation passed!" -ForegroundColor Green
    Write-Host "Ready to deploy with: .\scripts\deploy.ps1" -ForegroundColor White
}