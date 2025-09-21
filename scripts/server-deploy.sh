#!/bin/bash
# GitHub Webhook Deployment Script for Gatus
# Place this on your server at /opt/scripts/deploy-gatus.sh

set -e

REPO_DIR="/opt/gatus"
LOG_FILE="/var/log/gatus-deploy.log"

echo "$(date): Starting Gatus deployment..." >> $LOG_FILE

cd $REPO_DIR

# Pull latest changes
echo "$(date): Pulling latest changes from GitHub..." >> $LOG_FILE
git pull origin main >> $LOG_FILE 2>&1

# Restart Gatus
echo "$(date): Restarting Gatus service..." >> $LOG_FILE
docker compose down >> $LOG_FILE 2>&1
docker compose up -d >> $LOG_FILE 2>&1

# Verify deployment
sleep 5
if docker compose ps | grep -q "gatus.*Up"; then
    echo "$(date): ✅ Gatus deployment successful!" >> $LOG_FILE
    curl -X POST -H 'Content-type: application/json' \
        --data '{"text":"✅ Gatus monitoring updated and deployed successfully!"}' \
        "$SLACK_WEBHOOK_URL" >> $LOG_FILE 2>&1
else
    echo "$(date): ❌ Gatus deployment failed!" >> $LOG_FILE
    curl -X POST -H 'Content-type: application/json' \
        --data '{"text":"❌ Gatus deployment failed! Check server logs."}' \
        "$SLACK_WEBHOOK_URL" >> $LOG_FILE 2>&1
    exit 1
fi

echo "$(date): Deployment completed successfully!" >> $LOG_FILE