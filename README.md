# Gatus Monitoring Workspace

A modular Gatus health monitoring system for managing multiple client websites. Easily add new sites with automated configuration generation.

## Quick Start

### Add a new WooCommerce site:
```powershell
.\scripts\new-site.ps1 -type woocommerce -url "https://shop.example.com" -name "Example Shop"
.\scripts\validate.ps1
.\scripts\deploy.ps1
```

### Add a WordPress site:
```powershell
.\scripts\new-site.ps1 -type wordpress -url "https://blog.example.com" -name "Example Blog"
```

### Add a static website:
```powershell
.\scripts\new-site.ps1 -type static-site -url "https://company.com" -name "Company Website"
```

## Project Structure

```
monitor-gatus/
├── docker-compose.yml        # Gatus container configuration
├── .env                      # Environment variables (Slack webhooks)
├── config/
│   ├── gatus.yaml           # Main configuration (combines all sites)
│   ├── config.yaml.backup   # Original config backup
│   └── sites/               # Individual site configurations
│       ├── internal.yaml        # Infrastructure monitoring
│       └── sloane-bangkok.yaml  # Client site example
├── templates/               # Site templates for quick setup
│   ├── woocommerce.yaml.template
│   ├── wordpress.yaml.template
│   └── static-site.yaml.template
├── scripts/                 # Automation tools
│   ├── new-site.ps1         # Add new monitoring sites
│   ├── validate.ps1         # Test configurations
│   └── deploy.ps1           # Deploy to server
└── docs/                    # Documentation
    ├── adding-sites.md      # How to add new sites
    └── templates.md         # Template customization guide
```

## Server Details

- **Server**: 152.42.241.103 (DigitalOcean)
- **Path**: /opt/gatus/
- **Web Interface**: https://monitor.webifyseo.com/
- **Container**: Port 8081 → 8080

## Workflow

1. **Local Development**: Add/modify configurations in this workspace
2. **Validation**: Run `.\scripts\validate.ps1` to test changes
3. **Git Commit**: Changes are automatically committed during deploy
4. **Deploy**: Run `.\scripts\deploy.ps1` to push to server
5. **Monitor**: Check https://monitor.webifyseo.com/ for live status

## Currently Monitored

### Infrastructure
- Uptime Kuma (internal & public)
- Gatus self-monitoring
- SSL certificates

### Client Sites
- **Sloane's Bangkok** (WooCommerce)
  - Checkout functionality
  - Performance monitoring
  - Asset availability
  - SSL certificate

## Environment Variables

Each client gets their own Slack webhook in `.env`:
```bash
CLIENT1_SLACK=https://hooks.slack.com/services/...     # Sloane's Bangkok
CLIENT_NEWSHOP_SLACK=https://hooks.slack.com/services/...  # New sites...
```

## Documentation

- [Adding New Sites](docs/adding-sites.md) - Complete workflow for new monitoring
- [Templates Guide](docs/templates.md) - Customizing monitoring templates

## Deployment

The deploy script handles:
- ✅ Configuration validation
- ✅ Git commit and push
- ✅ File sync to server (rsync/scp)
- ✅ Gatus service restart
- ✅ Health check verification

```powershell
# Full deployment workflow
.\scripts\new-site.ps1 -type woocommerce -url "https://newsite.com" -name "New Site"
.\scripts\deploy.ps1

# Dry run (test without changes)
.\scripts\deploy.ps1 -DryRun
```
