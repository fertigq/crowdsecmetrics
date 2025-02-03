#!/bin/bash

# CrowdSec Metrics Dashboard Uninstaller

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[LOG]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check for root/sudo permissions
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        error "Please run as root or with sudo"
    fi
}

# Main uninstallation function
uninstall_crowdsec_metrics() {
    check_sudo

    # Project configuration
    PROJECT_DIR="/opt/crowdsecmetrics"

    # Stop and disable systemd service
    log "Stopping and disabling systemd service..."
    systemctl stop crowdsecmetrics
    systemctl disable crowdsecmetrics
    rm -f /etc/systemd/system/crowdsecmetrics.service

    # Remove firewall rules
    log "Removing firewall rules..."
    PORT=$(grep PORT "$PROJECT_DIR/.env" | cut -d '=' -f2)
    if [ -n "$PORT" ]; then
        if command -v ufw &> /dev/null; then
            ufw delete allow "$PORT/tcp"
        elif command -v firewall-cmd &> /dev/null; then
            firewall-cmd --permanent --remove-port="$PORT/tcp"
            firewall-cmd --reload
        fi
    fi

    # Remove project directory
    log "Removing project directory..."
    rm -rf "$PROJECT_DIR"

    # Optional: Remove npm global packages if installed
    log "Removing global npm packages (if any)..."
    npm uninstall -g crowdsec-metrics-dashboard 2>/dev/null

    # Reload systemd
    systemctl daemon-reload

    # Final success message
    success "CrowdSec Metrics Dashboard has been completely uninstalled."
    echo "To fully clean up, you may want to:"
    echo "1. Remove any remaining configuration files in your home directory"
    echo "2. Check for any leftover npm packages"
}

# Confirmation prompt
confirm_uninstall() {
    read -p "Are you sure you want to uninstall CrowdSec Metrics Dashboard? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        uninstall_crowdsec_metrics
    else
        warning "Uninstallation cancelled."
        exit 0
    fi
}

# Run the uninstallation
confirm_uninstall 
