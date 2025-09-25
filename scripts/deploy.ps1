# Deploy Gatus Configuration to Server
# Usage: .\scripts\deploy.ps1

param(
    [Parameter(Mandatory=$false)]
    [string]$Server = "152.42.241.103",
    
    [Parameter(Mandatory=$false)]
    [string]$RemotePath = "/opt/gatus/",
    
    [Parameter(Mandatory=$false)]
    [string]$User = "root",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

Write-Host "Deploying Gatus configuration to server..." -ForegroundColor Green

# Validate configuration first
Write-Host "Running validation..." -ForegroundColor Cyan
& ".\scripts\validate.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Configuration validation failed. Fix issues before deploying."
    exit 1
}

# Check if we have git changes to commit
$GitStatus = git status --porcelain 2>$null
if ($GitStatus) {
    Write-Host "Found uncommitted changes:" -ForegroundColor Yellow
    git status --short
    
    $Commit = Read-Host "`nCommit changes before deploy? (Y/n)"
    if ($Commit -ne "n" -and $Commit -ne "N") {
        $CommitMessage = Read-Host "Commit message (or press Enter for default)"
        if ([string]::IsNullOrEmpty($CommitMessage)) {
            $CommitMessage = "Update monitoring configuration - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        }
        
        git add .
        git commit -m $CommitMessage
        Write-Host "✓ Changes committed" -ForegroundColor Green
    }
}

# Push to GitHub if configured
$GitRemote = git remote get-url origin 2>$null
if ($GitRemote) {
    Write-Host "Pushing to GitHub..." -ForegroundColor Cyan
    git push
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Pushed to GitHub" -ForegroundColor Green
    } else {
        Write-Warning "Failed to push to GitHub, continuing with deploy..."
    }
}

# Prepare file list for deployment
$FilesToDeploy = @(
    "docker-compose.yml",
    "config/gatus.yaml",
    "config/sites/",
    ".env"
)

Write-Host "`nDeploying to server: $User@$Server" -ForegroundColor Cyan

# Check if rsync is available (recommended for efficient deployment)
if (Get-Command rsync -ErrorAction SilentlyContinue) {
    Write-Host "Using rsync for deployment..." -ForegroundColor Cyan
    
    $RsyncArgs = @(
        "-avz",
        "--delete",
        "--exclude='.git/'",
        "--exclude='scripts/'",
        "--exclude='templates/'",
        "--exclude='docs/'",
        "--exclude='README.md'",
        ".",
        "$User@${Server}:$RemotePath"
    )
    
    if ($DryRun) {
        $RsyncArgs += "--dry-run"
        Write-Host "DRY RUN - Would sync:" -ForegroundColor Yellow
    }
    
    & rsync @RsyncArgs
    
} elseif (Get-Command scp -ErrorAction SilentlyContinue) {
    Write-Host "Using scp for deployment..." -ForegroundColor Cyan
    
    foreach ($File in $FilesToDeploy) {
        if (Test-Path $File) {
            if ($DryRun) {
                Write-Host "DRY RUN - Would copy: $File" -ForegroundColor Yellow
            } else {
                scp -r $File "$User@${Server}:$RemotePath"
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✓ Copied: $File" -ForegroundColor Green
                } else {
                    Write-Error "Failed to copy: $File"
                }
            }
        }
    }
    
} else {
    Write-Error "Neither rsync nor scp available. Please install OpenSSH or WSL with rsync."
    Write-Host "Alternative: Manually copy files to server at $RemotePath" -ForegroundColor Yellow
    exit 1
}

if (-not $DryRun) {
    # Restart Gatus on the server
    Write-Host "`nRestarting Gatus service on server..." -ForegroundColor Cyan
    
    ssh "$User@$Server" "cd $RemotePath; docker compose down; docker compose up -d"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Gatus service restarted" -ForegroundColor Green
        Write-Host "`n✅ Deployment completed successfully!" -ForegroundColor Green
        Write-Host "Monitor: https://monitor.webifyseo.com/" -ForegroundColor White
    } else {
        Write-Error "Failed to restart Gatus service"
        exit 1
    }
} else {
    Write-Host "`n✅ Dry run completed - no changes made" -ForegroundColor Green
}