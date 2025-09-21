# Adding New Sites to Gatus Monitoring

This guide explains how to add new websites to your Gatus monitoring setup using the automated scripts.

## Quick Start

### Add a WooCommerce Site
```powershell
.\scripts\new-site.ps1 -type woocommerce -url "https://shop.example.com" -name "Example Shop"
```

### Add a WordPress Site
```powershell
.\scripts\new-site.ps1 -type wordpress -url "https://blog.example.com" -name "Example Blog"
```

### Add a Static Site
```powershell
.\scripts\new-site.ps1 -type static-site -url "https://company.com" -name "Company Website"
```

## Complete Workflow

1. **Add the site:**
   ```powershell
   .\scripts\new-site.ps1 -type woocommerce -url "https://newshop.com" -name "New Shop"
   ```

2. **Add Slack webhook to .env (if prompted):**
   ```
   CLIENT_NEWSHOP_SLACK=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
   ```

3. **Validate the configuration:**
   ```powershell
   .\scripts\validate.ps1
   ```

4. **Deploy to server:**
   ```powershell
   .\scripts\deploy.ps1
   ```

5. **Check the monitoring dashboard:**
   https://monitor.webifyseo.com/

## Site Types

### WooCommerce
- Monitors checkout page functionality
- Checks for WooCommerce-specific elements
- Tests both cached and uncached responses
- Monitors static assets (jQuery)
- SSL certificate monitoring

### WordPress
- Monitors homepage and admin access
- Checks for WordPress-specific markers
- Tests static assets (jQuery)
- SSL certificate monitoring

### Static Site
- Monitors homepage, about, and contact pages
- Basic HTML validation
- SSL certificate monitoring

## Manual Configuration

If you need to customize monitoring beyond the templates:

1. Create your config file in `config/sites/yoursite.yaml`
2. Add the endpoints manually based on the template structure
3. Update `config/gatus.yaml` to include your new endpoints
4. Follow the validation and deployment steps

## Environment Variables

Each site should have its own Slack webhook environment variable:
- `CLIENT1_SLACK` - for first client
- `CLIENT_NEWSHOP_SLACK` - auto-generated based on domain
- `CLIENT_COMPANY_SLACK` - for company.com, etc.

Add these to your `.env` file with the actual Slack webhook URLs.

## Troubleshooting

### Validation Fails
- Check YAML syntax (spaces, not tabs)
- Ensure all environment variables are defined in `.env`
- Verify URLs are accessible

### Deployment Fails  
- Check SSH access to server (152.42.241.103)
- Verify server path (/opt/gatus/) exists
- Ensure Docker is running on server

### Site Not Monitoring
- Check Gatus logs: `docker compose logs gatus`
- Verify endpoint configuration in the web UI
- Test URLs manually from server