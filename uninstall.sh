#!/bin/bash

# CrowdSec Metrics Dashboard Uninstaller

# Color codes for logging
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*"
    exit 1
}

# Check for root/sudo permissions
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        error "Please run as root or with sudo"
    fi
}

# Find project directory
find_project_directory() {
    local COMMON_DIRS=("/opt/crowdsecmetrics" "/usr/local/crowdsecmetrics" "$HOME/crowdsecmetrics")
    
    for dir in "${COMMON_DIRS[@]}"; do
        if [ -d "$dir" ] && [ -f "$dir/package.json" ] && grep -q "crowdsecmetrics" "$dir/package.json"; then
            echo "$dir"
            return 0
        fi
    done

    # If no directory found, use current directory
    pwd
}

# Uninstall process
uninstall() {
    check_sudo

    # Find project directory
    local PROJECT_DIR
    PROJECT_DIR=$(find_project_directory)

    # Stop and disable systemd service
    log "Stopping and disabling systemd service..."
    systemctl stop crowdsecmetrics || warning "Could not stop crowdsecmetrics service"
    systemctl disable crowdsecmetrics || warning "Could not disable crowdsecmetrics service"
    rm -f /etc/systemd/system/crowdsecmetrics.service || warning "Could not remove systemd service file"

    # Remove firewall rules
    log "Removing firewall rules..."
    if command -v ufw &> /dev/null; then
        PORT=$(grep PORT "$PROJECT_DIR/.env" | cut -d '=' -f2 2>/dev/null)
        if [ -n "$PORT" ]; then
            ufw delete allow "$PORT/tcp" || warning "Could not remove UFW rule"
        fi
    elif command -v firewall-cmd &> /dev/null; then
        PORT=$(grep PORT "$PROJECT_DIR/.env" | cut -d '=' -f2 2>/dev/null)
        if [ -n "$PORT" ]; then
            firewall-cmd --permanent --remove-port="$PORT/tcp" || warning "Could not remove firewall rule"
            firewall-cmd --reload || warning "Could not reload firewall"
        fi
    fi

    # Remove npm global packages
    log "Removing global npm packages..."
    npm uninstall -g postcss tailwindcss vite typescript || warning "Could not remove global npm packages"

    # Remove project directory
    log "Removing project directory..."
    rm -rf "$PROJECT_DIR" || warning "Could not remove project directory"

    # Clean up npm cache
    log "Cleaning npm cache..."
    npm cache clean --force || warning "Could not clean npm cache"

    # Remove any lingering node modules
    log "Removing node modules..."
    find / -name "node_modules" 2>/dev/null | grep "crowdsecmetrics" | xargs rm -rf || warning "Could not remove all node_modules"

    # Reload systemd to reflect changes
    systemctl daemon-reload

    success "CrowdSec Metrics Dashboard has been completely uninstalled."
}

# Cleanup additional potential remnants
additional_cleanup() {
    log "Performing additional cleanup..."

    # Remove any remaining log files
    find /var/log -name "*crowdsecmetrics*" -delete || warning "Could not remove log files"

    # Remove any remaining configuration files
    rm -f /etc/crowdsecmetrics.conf || warning "Could not remove configuration file"
    rm -f ~/.config/crowdsecmetrics.json || warning "Could not remove user configuration"

    # Remove npm-related files
    rm -rf ~/.npm/_logs/crowdsecmetrics* || warning "Could not remove npm logs"

    success "Additional cleanup completed."
}

# Main uninstall process
main() {
    clear
    
    log "🗑️ CrowdSec Metrics Dashboard Uninstaller 🗑️"
    log "-------------------------------------------"

    # Confirm uninstallation
    read -p "Are you sure you want to uninstall CrowdSec Metrics Dashboard? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log "Uninstallation cancelled."
        exit 0
    fi

    # Run uninstallation steps
    uninstall
    additional_cleanup

    # Final message
    echo ""
    success "Uninstallation complete. All CrowdSec Metrics Dashboard components have been removed."
}

# Run the main uninstall function
main
