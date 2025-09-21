# Monitoring Templates

This document explains the available monitoring templates and how to customize them.

## Available Templates

### WooCommerce (`woocommerce.yaml.template`)
**Best for:** Online stores using WooCommerce

**Monitors:**
- Checkout page functionality (with WooCommerce-specific checks)
- Cached and non-cached responses  
- Static assets (jQuery)
- SSL certificate expiration

**Key Features:**
- Validates WooCommerce checkout elements
- Tests page performance under different cache conditions
- Comprehensive Slack alerting

### WordPress (`wordpress.yaml.template`)
**Best for:** WordPress blogs and websites

**Monitors:**
- Homepage with WordPress detection
- Admin login page accessibility
- Static assets (jQuery)
- SSL certificate expiration

**Key Features:**
- WordPress-specific content validation
- Admin area monitoring for maintenance detection
- Less aggressive monitoring than WooCommerce

### Static Site (`static-site.yaml.template`)
**Best for:** Simple websites, landing pages, corporate sites

**Monitors:**
- Homepage
- About page  
- Contact page
- SSL certificate expiration

**Key Features:**
- Basic HTML validation
- Common page structure monitoring
- Lightweight monitoring approach

## Template Variables

All templates use these replacement variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `{{SITE_NAME}}` | Display name for the site | "Example Shop" |
| `{{SITE_URL}}` | Full URL without trailing slash | "https://shop.example.com" |
| `{{SITE_DOMAIN}}` | Domain only | "shop.example.com" |
| `{{SITE_SLUG}}` | Short identifier | "exampleshop" |
| `{{SLACK_WEBHOOK_VAR}}` | Environment variable name | "CLIENT_EXAMPLE_SLACK" |

## Customizing Templates

### Adding New Endpoints
To add monitoring for additional pages:

```yaml
- name: {{SITE_NAME}} Custom Page
  group: content
  url: {{SITE_URL}}/custom-page/
  interval: 180s
  conditions:
    - "[STATUS] < 400"
    - "[RESPONSE_TIME] < 2000ms"
    - "[BODY] == pat(*specific-content*)"
```

### Adjusting Thresholds

**Response Time:**
```yaml
conditions:
  - "[RESPONSE_TIME] < 3000ms"  # Increase for slower sites
```

**Alert Sensitivity:**
```yaml
alerts:
  - failure-threshold: 2  # Require 2 failures before alerting
    success-threshold: 1  # Send resolved after 1 success
```

**Monitoring Frequency:**
```yaml
interval: 300s  # Check every 5 minutes instead of 1 minute
```

### Content Validation

**For WooCommerce sites:**
```yaml
conditions:
  - "[BODY] == pat(*woocommerce-checkout*)"      # WooCommerce active
  - "[BODY] == pat(*Add to cart*)"               # Shop functionality
  - "[BODY] != pat(*maintenance*)"               # Not in maintenance
```

**For WordPress sites:**
```yaml
conditions:
  - "[BODY] == pat(*wp-content*)"                # WordPress assets
  - "[BODY] == pat(*<meta name=\"generator\" content=\"WordPress*)" # WP version
  - "[BODY] != pat(*Fatal error*)"               # No PHP errors
```

**For static sites:**
```yaml
conditions:
  - "[BODY] == pat(*<title>*)"                   # Has title tag
  - "[BODY] == pat(*<meta charset*)"             # Proper HTML structure
  - "[BODY] != pat(*404*)"                       # Not a 404 page
```

## Creating Custom Templates

1. **Copy an existing template:**
   ```powershell
   copy templates\woocommerce.yaml.template templates\custom.yaml.template
   ```

2. **Modify the endpoints and conditions**

3. **Update the new-site.ps1 script to include your template:**
   ```powershell
   [ValidateSet("woocommerce", "wordpress", "static-site", "custom")]
   ```

4. **Test with a sample site:**
   ```powershell
   .\scripts\new-site.ps1 -type custom -url "https://test.com" -name "Test Site"
   ```

## Best Practices

### Monitoring Intervals
- **Critical pages:** 60s (checkout, homepage)
- **Content pages:** 180s (about, contact)
- **Assets:** 300s (CSS, JS files)
- **Certificates:** 6h (SSL monitoring)

### Alert Configuration
- **E-commerce:** Low threshold, immediate alerts
- **Blogs:** Higher threshold, less urgent alerts
- **Static sites:** Medium threshold, moderate urgency

### Response Time Targets
- **Homepage:** < 2000ms
- **Checkout/Critical:** < 2000ms  
- **Admin areas:** < 3000ms
- **Static assets:** < 1200ms

### Content Validation
- Always include a positive check (element that should exist)
- Consider negative checks (error messages that shouldn't exist)
- Use stable selectors that won't change with design updates
- Test patterns with actual site content before deploying