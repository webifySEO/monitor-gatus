# GitHub Actions Deployment Setup - Step by Step

This guide will set up automated deployment from GitHub to your DigitalOcean server (152.42.241.103).

## Prerequisites

- Access to your DigitalOcean server (152.42.241.103)
- Admin access to GitHub repository `webifySEO/monitor-gatus`
- PowerShell or terminal access

---

## Step 1: Generate SSH Key Pair for GitHub Actions

### On Your Local Machine:

```powershell
# Create a dedicated SSH key for GitHub Actions (no passphrase)
ssh-keygen -t ed25519 -f ~/.ssh/gatus_deploy_key -N ""

# This creates two files:
# ~/.ssh/gatus_deploy_key (private key - for GitHub)
# ~/.ssh/gatus_deploy_key.pub (public key - for server)
```

### View the keys:

```powershell
# View public key (you'll need this for the server)
Get-Content ~/.ssh/gatus_deploy_key.pub

# View private key (you'll need this for GitHub secrets)
Get-Content ~/.ssh/gatus_deploy_key
```

**📋 Copy both keys to a text file - you'll need them in the next steps.**

---

## Step 2: Configure Server SSH Access

### SSH to your server:

```powershell
ssh root@152.42.241.103
```

### Add the public key to authorized_keys:

```bash
# On the server, add your public key
echo "YOUR_PUBLIC_KEY_CONTENT_HERE" >> ~/.ssh/authorized_keys

# Set proper permissions
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

### Test SSH access from your local machine:

```powershell
# Test the new key works (should login without password)
ssh -i ~/.ssh/gatus_deploy_key root@152.42.241.103
```

**✅ If this works without asking for a password, SSH is configured correctly.**

---

## Step 3: Set Up Git Repository on Server

### While SSH'd to your server:

```bash
# Create the directory structure
mkdir -p /opt
cd /opt

# Clone the repository
git clone https://github.com/webifySEO/monitor-gatus.git gatus

# Set up proper permissions
cd gatus
chown -R root:root /opt/gatus

# Test git operations
git status
git log --oneline -5
```

### Verify Docker Compose works:

```bash
# Make sure docker compose command works
cd /opt/gatus
docker compose --version
docker compose config

# Test the current setup
docker compose down
docker compose up -d
docker compose ps
```

**✅ Repository should be cloned and Docker Compose should work.**

---

## Step 4: Add GitHub Repository Secrets

### Go to GitHub Repository Settings:

1. Open https://github.com/webifySEO/monitor-gatus
2. Click **Settings** tab
3. In left sidebar, click **Secrets and variables > Actions**
4. Click **New repository secret**

### Add these 3 secrets:

#### Secret 1: SERVER_HOST
- **Name**: `SERVER_HOST`
- **Value**: `152.42.241.103`

#### Secret 2: SERVER_USER
- **Name**: `SERVER_USER`
- **Value**: `root`

#### Secret 3: SERVER_SSH_KEY
- **Name**: `SERVER_SSH_KEY`
- **Value**: Your private key content (from `~/.ssh/gatus_deploy_key`)

**⚠️ Important**: For SERVER_SSH_KEY, copy the ENTIRE private key including:
```
-----BEGIN OPENSSH PRIVATE KEY-----
[key content]
-----END OPENSSH PRIVATE KEY-----
```

---

## Step 5: Test Automated Deployment

### Make a test change:

```powershell
# In your local repository, make a small change
cd "d:\webifySEO.com\_GATUS"

# Edit a file (add a comment)
echo "# Test deployment - $(Get-Date)" >> README.md

# Commit and push
git add README.md
git commit -m "Test automated deployment"
git push origin main
```

### Monitor the deployment:

1. Go to https://github.com/webifySEO/monitor-gatus/actions
2. You should see a new workflow run starting
3. Click on it to watch the progress
4. Look for the "Deploy to server" step

### Verify on server:

```bash
# SSH to server and check
ssh root@152.42.241.103
cd /opt/gatus

# Check if the change was deployed
git log --oneline -1
cat README.md

# Check if Gatus is running
docker compose ps
```

---

## Troubleshooting

### If GitHub Actions fails with SSH connection:

```bash
# On server, check SSH configuration
cat ~/.ssh/authorized_keys
ls -la ~/.ssh/

# Verify the key format is correct
ssh-keygen -lf ~/.ssh/authorized_keys
```

### If git pull fails:

```bash
# On server, check git configuration
cd /opt/gatus
git remote -v
git status

# Reset if needed
git reset --hard origin/main
```

### If Docker Compose fails:

```bash
# On server, check Docker status
systemctl status docker
docker --version
docker compose --version

# Check for port conflicts
netstat -tlnp | grep :8080
```

---

## Security Notes

- ✅ Dedicated SSH key (not your personal key)
- ✅ Key has no passphrase (required for automation)
- ✅ Private key stored securely in GitHub secrets
- ✅ Public key only on target server
- ⚠️ Never commit private keys to git

---

## What Happens When You Push?

1. **GitHub detects push to main branch**
2. **GitHub Actions starts workflow**
3. **Connects to server via SSH**
4. **Pulls latest code from GitHub**
5. **Restarts Gatus with docker compose**
6. **Reports success/failure**

---

## Daily Usage

After setup, your workflow is:

1. **Edit monitoring configs locally**
2. **Commit and push to main**
3. **GitHub automatically deploys to server**
4. **Check Gatus is updated**

No more manual `scp` or server commands needed! 🎉