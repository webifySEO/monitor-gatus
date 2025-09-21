# Automated Deployment Setup

This document covers two options for automated deployment from GitHub to your server.

## Option 1: GitHub Actions (Recommended)

### 1. Configure GitHub Repository Secrets

In your GitHub repository (`webifySEO/monitor-gatus`), go to **Settings > Secrets and variables > Actions** and add:

```
SERVER_HOST=152.42.241.103
SERVER_USER=root
SERVER_SSH_KEY=<your-private-ssh-key>
```

### 2. Prepare Server

```bash
# On your server (152.42.241.103)
cd /opt
git clone https://github.com/webifySEO/monitor-gatus.git gatus
cd gatus

# Ensure SSH key authentication works
# Test: ssh root@152.42.241.103 (should work without password)
```

### 3. Test Deployment

Push any change to the `main` branch - GitHub Actions will automatically:
- SSH to your server
- Pull latest changes
- Restart Gatus with `docker compose`

## Option 2: Webhook Server (Alternative)

### 1. Install Webhook Server

```bash
# On your server
cd /opt/gatus
pip3 install flask

# Copy deployment scripts
cp scripts/server-deploy.sh /opt/scripts/
cp scripts/webhook-server.py /opt/scripts/
chmod +x /opt/scripts/server-deploy.sh

# Set environment variables
export GITHUB_WEBHOOK_SECRET="your-secret-here"
export SLACK_WEBHOOK_URL="your-slack-webhook"
```

### 2. Run Webhook Server

```bash
# Start webhook server (consider using systemd for production)
cd /opt/scripts
python3 webhook-server.py &

# Or create systemd service for auto-start
```

### 3. Configure GitHub Webhook

In GitHub repository settings:
- **Payload URL**: `http://152.42.241.103:5000/webhook/gatus`
- **Content type**: `application/json`
- **Secret**: Your webhook secret
- **Events**: Just the push event

### 4. Nginx Proxy (Optional)

```nginx
# /etc/nginx/sites-available/webhook
server {
    listen 80;
    server_name webhook.yourdomain.com;
    
    location /webhook/gatus {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Security Considerations

### GitHub Actions
- ✅ No exposed ports
- ✅ Encrypted secrets
- ✅ Runs in GitHub's secure environment

### Webhook Server
- ⚠️ Requires exposed port/endpoint
- ⚠️ Needs signature verification
- ⚠️ Additional server maintenance

## Recommendation

**Use GitHub Actions** (Option 1) for:
- Better security (no exposed endpoints)
- Zero server maintenance
- Built-in logging and monitoring
- Easier troubleshooting

**Use Webhook Server** (Option 2) only if:
- GitHub Actions are restricted in your environment
- You need custom deployment logic
- You prefer server-side control

## Testing Your Setup

1. Make a small change to any monitoring config
2. Commit and push to `main` branch
3. Check deployment logs:
   - **GitHub Actions**: Repository > Actions tab
   - **Webhook**: `/var/log/gatus-deploy.log`
4. Verify Gatus is updated: `docker compose ps`

## Troubleshooting

### GitHub Actions Issues
```bash
# Check SSH connectivity
ssh -i /path/to/key root@152.42.241.103

# Verify git repository
cd /opt/gatus && git status
```

### Webhook Issues
```bash
# Check webhook server logs
journalctl -f -u webhook-server

# Test webhook endpoint
curl -X POST http://127.0.0.1:5000/health

# Check deployment script
bash -x /opt/scripts/deploy-gatus.sh
```