# Gatus Monitor Configuration

This repository contains the configuration files for our Gatus health monitoring setup.

## Files

- docker-compose.yml - Docker Compose configuration for running Gatus
- config/config.yaml - Main Gatus configuration with monitoring endpoints
- .env - Environment variables (contains sensitive data)

## Usage

1. Clone this repository
2. Update the .env file with your Slack webhook URLs
3. Run with Docker Compose: docker-compose up -d

## Server Details

- **Server**: 152.42.241.103 (DigitalOcean)
- **Installation Path**: /opt/gatus/
- **Web Interface**: https://monitor.webifyseo.com/

## Monitored Services

- Uptime Kuma (internal & public)
- Gatus self-check
- Client websites (Sloane's Bangkok)
- TLS certificates
