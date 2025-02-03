#!/bin/bash

# CrowdSec Metrics Dashboard Installer

# Fail on any error and exit on undefined variables
set -eu

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

error() {
    echo -e "${RED}[ERROR]${NC} $*"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

# Check for root/sudo permissions
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        error "Please run as root or with sudo"
    fi
}

# Detect the operating system
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    else
        error "Unsupported operating system"
    fi
}

# Validate system requirements
validate_requirements() {
    # Check Node.js
    if ! command -v node &> /dev/null; then
        error "Node.js is not installed. Please install Node.js 16+ first."
    fi

    # Check npm
    if ! command -v npm &> /dev/null; then
        error "npm is not installed. Please install npm first."
    fi

    # Check CrowdSec
    if ! command -v cscli &> /dev/null; then
        error "CrowdSec is not installed. Please install CrowdSec first."
    fi
}

# Select and validate port
select_port() {
    local PORT
    while true; do
        read -p "Enter dashboard port (default: 47392): " PORT
        PORT=${PORT:-47392}

        # Validate port is a number
        if [[ ! "$PORT" =~ ^[0-9]+$ ]]; then
            error "Port must be a number"
        fi

        # Check port range
        if (( PORT < 1024 || PORT > 65535 )); then
            error "Port must be between 1024 and 65535"
        fi

        # Check if port is already in use
        if nc -z localhost "$PORT" 2>/dev/null; then
            warning "Port $PORT is already in use. Please choose another."
        else
            echo "$PORT"
            break
        fi
    done
}

# Detect server IP
detect_server_ip() {
    local SERVER_IP
    # Try to get the primary network interface IP
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    read -p "Enter server IP (default: $SERVER_IP): " USER_IP
    SERVER_IP=${USER_IP:-$SERVER_IP}
    echo "$SERVER_IP"
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
            error "Unsupported operating system: $OS"
            ;;
    esac
}

# Clone the repository
clone_repository() {
    local PROJECT_DIR="/opt/crowdsecmetrics"
    log "Cloning CrowdSec Metrics Dashboard repository..."
    
    # Remove existing directory if it exists
    if [ -d "$PROJECT_DIR" ]; then
        warning "Existing project directory found. Removing..."
        rm -rf "$PROJECT_DIR"
    fi
    
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
    local PORT HOST
    log "Configuring environment..."
    
    # Copy example environment file
    cp .env.example .env
    
    # Select port
    PORT=$(select_port)
    
    # Detect server IP
    HOST=$(detect_server_ip)
    
    # Update .env file
    sed -i "s/PORT=.*/PORT=$PORT/" .env
    sed -i "s/HOST=.*/HOST=$HOST/" .env
    
    # Set CrowdSec container name
    sed -i "s/CROWDSEC_CONTAINER=.*/CROWDSEC_CONTAINER=crowdsec/" .env
    
    success "Environment configured successfully"
}

# Setup systemd service
setup_systemd_service() {
    local PROJECT_DIR="/opt/crowdsecmetrics"
    log "Setting up systemd service..."
    
    cat > /etc/systemd/system/crowdsecmetrics.service << EOL
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
    systemctl enable crowdsecmetrics
    systemctl start crowdsecmetrics
}

# Configure firewall
configure_firewall() {
    local PORT
    PORT=$(grep PORT .env | cut -d '=' -f2)
    
    log "Configuring firewall..."
    if command -v ufw &> /dev/null; then
        ufw allow "$PORT/tcp"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port="$PORT/tcp"
        firewall-cmd --reload
    else
        warning "No firewall utility found. Please manually configure firewall."
    fi
}

# Main installation process
main() {
    # Clear the screen for a clean installation view
    clear
    
    log "🚀 CrowdSec Metrics Dashboard Installer 🚀"
    log "----------------------------------------"
    
    # Run installation steps
    check_sudo
    detect_os
    validate_requirements
    install_dependencies
    clone_repository
    install_project_dependencies
    configure_environment
    setup_systemd_service
    configure_firewall
    
    # Final success message
    echo ""
    success "Installation completed successfully!"
    echo "Dashboard URL: http://$(grep HOST .env | cut -d '=' -f2):$(grep PORT .env | cut -d '=' -f2)"
    echo ""
    echo "Useful commands:"
    echo "  View service status: systemctl status crowdsecmetrics"
    echo "  Stop service: systemctl stop crowdsecmetrics"
    echo "  Start service: systemctl start crowdsecmetrics"
}

# Run the main installation function
main
