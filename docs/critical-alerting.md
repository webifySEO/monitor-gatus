# Critical Alerting Setup Guide

## 🚨 Emergency Alert Configuration

This guide sets up **CRITICAL ALERTS** that will wake you up for serious outages (10+ minute downtimes).

## 1. Create Dedicated Slack Channel

### Create Channel:
1. In Slack, create a new channel: `#critical-alerts` 
2. Set the channel purpose: "EMERGENCY MONITORING - Critical site outages (10+ min downtime)"

### Create Critical Webhook:
1. Go to: https://api.slack.com/apps
2. Create a new app or use existing webifySEO app
3. Add "Incoming Webhooks" 
4. Create webhook specifically for `#critical-alerts` channel
5. Copy the webhook URL

## 2. Configure Phone Notifications

### Slack Mobile App Settings:
1. Open Slack mobile app
2. Go to **Settings** → **Notifications** 
3. Find `#critical-alerts` channel
4. Set **Notification Schedule**: **All the time** (overrides Do Not Disturb)
5. Set **Mobile Push**: **All new messages**
6. Set **Sound**: Choose a **distinctive alert sound** (different from normal notifications)

### iPhone Specific:
- Go to **Settings** → **Notifications** → **Slack**
- Enable **Allow Notifications**
- Set **Alerts**: **Persistent** or **Banner**
- Enable **Critical Alerts** if available
- Set custom sound for Slack

### Android Specific:
- Go to **Settings** → **Apps** → **Slack** → **Notifications**
- Create **new notification channel** for critical alerts
- Set **Importance**: **Urgent** or **High**
- Enable **Override Do Not Disturb**
- Set custom sound and vibration pattern

## 3. Update Environment Variables

Add the critical webhook to your `.env` file:

```bash
# Add this line to your local .env file
CRITICAL_ALERTS_SLACK=https://hooks.slack.com/services/YOUR/CRITICAL/WEBHOOK_URL
```

## 4. Deploy Critical Alerting

```powershell
# Deploy the new critical alert configuration
.\scripts\deploy.ps1
```

## 5. Alert Thresholds

### **CRITICAL ALERTS** trigger when:

| **Endpoint** | **Downtime** | **Impact** |
|--------------|--------------|------------|
| **Sloane's Bangkok Checkout** | 10 minutes | Revenue loss |
| **Essex Banners Server** | 10 minutes | Total site down |  
| **Essex Banners Checkout** | 30 minutes | Revenue loss |
| **Uptime Kuma** | 5 minutes | Monitoring blind |
| **Gatus System** | 5 minutes | All monitoring down |

### **Regular Alerts** (existing):
- Trigger immediately (1-3 failures)  
- Go to client-specific channels
- Normal notification priority

## 6. Test Critical Alerts

```powershell
# Test by temporarily breaking a monitored URL
# Or wait for a natural outage to verify functionality
```

## 7. Alert Message Format

Critical alerts use this format:
```
🚨 CRITICAL: SLOANE'S BANGKOK CHECKOUT DOWN FOR 10+ MINUTES - IMMEDIATE ACTION REQUIRED 🚨
```

- **🚨 CRITICAL** prefix for visual recognition
- **SITE NAME** and **ISSUE** clearly stated  
- **DURATION** to understand severity
- **ACTION REQUIRED** to indicate urgency

## 8. Escalation Process

1. **Critical alert fires** → You get woken up
2. **Check monitoring dashboard**: https://monitor.webifyseo.com/
3. **Investigate the specific endpoint** that's failing
4. **Contact client** if widespread outage
5. **Document incident** and resolution

## 9. Testing

Test critical alerts work by:
- Ensuring your phone bypasses silence for Slack notifications
- Verifying the webhook posts to `#critical-alerts` channel  
- Confirming alerts fire after specified failure thresholds

---

**⚠️ IMPORTANT**: Only use critical alerts for true emergencies. Too many false positives will lead to alert fatigue!