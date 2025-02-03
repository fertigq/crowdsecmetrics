#!/bin/bash

# CrowdSec Metrics Dashboard Installation Script

# Fail on any error and exit on undefined variables
set -eu

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Check for root/sudo permissions
if [ "$EUID" -ne 0 ]; then
    log "Please run as root or with sudo"
    exit 1
fi

# Detect the operating system
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    else
        log "Unsupported operating system"
        exit 1
    fi
}

# Validate system requirements
validate_requirements() {
    # Check Node.js
    if ! command -v node &> /dev/null; then
        log "Node.js is not installed. Please install Node.js 16+ first."
        exit 1
    fi

    # Check npm
    if ! command -v npm &> /dev/null; then
        log "npm is not installed. Please install npm first."
        exit 1
    fi

    # Check CrowdSec
    if ! command -v cscli &> /dev/null; then
        log "CrowdSec is not installed. Please install CrowdSec first."
        exit 1
    }
}

# Install system dependencies
install_dependencies() {
    log "Installing system dependencies..."
    case "$OS" in
        "Ubuntu"|"Debian GNU/Linux")
            apt-get update
            apt-get install -y nodejs npm nginx git
            ;;
        "CentOS Linux"|"Red Hat Enterprise Linux")
            yum update
            yum install -y nodejs npm nginx git
            ;;
        *)
            log "Unsupported operating system: $OS"
            exit 1
            ;;
    esac
}

# Clone the repository
clone_repository() {
    log "Cloning CrowdSec Metrics Dashboard repository..."
    PROJECT_DIR="/opt/crowdsec-metrics"
    mkdir -p "$PROJECT_DIR"
    git clone https://github.com/fertigq/crowdsecmetrics.git "$PROJECT_DIR"
    cd "$PROJECT_DIR"
}

# Install project dependencies
install_project_dependencies() {
    log "Installing project dependencies..."
    npm install
}

# Configure environment
configure_environment() {
    log "Configuring environment..."
    cp example.env .env
    
    # Prompt for configuration
    read -p "Enter dashboard port (default: 3456): " PORT
    PORT=${PORT:-3456}
    sed -i "s/PORT=.*/PORT=$PORT/" .env

    read -p "Enter host IP (default: 0.0.0.0): " HOST
    HOST=${HOST:-0.0.0.0}
    sed -i "s/HOST=.*/HOST=$HOST/" .env
}

# Setup systemd service
setup_systemd_service() {
    log "Setting up systemd service..."
    cat > /etc/systemd/system/crowdsec-metrics.service << EOL
[Unit]
Description=CrowdSec Metrics Dashboard
After=network.target

[Service]
Type=simple
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/bin/npm start
Restart=on-failure
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOL

    systemctl daemon-reload
    systemctl enable crowdsec-metrics
    systemctl start crowdsec-metrics
}

# Configure firewall
configure_firewall() {
    log "Configuring firewall..."
    if command -v ufw &> /dev/null; then
        ufw allow "$PORT/tcp"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port="$PORT/tcp"
        firewall-cmd --reload
    fi
}

# Main installation process
main() {
    log "Starting CrowdSec Metrics Dashboard installation..."
    
    detect_os
    validate_requirements
    install_dependencies
    clone_repository
    install_project_dependencies
    configure_environment
    setup_systemd_service
    configure_firewall

    log "Installation completed successfully!"
    log "Access your dashboard at: http://$HOST:$PORT"
}

# Run the main installation function
main
