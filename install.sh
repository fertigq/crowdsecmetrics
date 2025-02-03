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

# Find project directory
find_project_directory() {
    local SCRIPT_DIR
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    
    # Check if current directory contains project files
    if [ -f "$SCRIPT_DIR/package.json" ] && grep -q "crowdsecmetrics" "$SCRIPT_DIR/package.json"; then
        echo "$SCRIPT_DIR"
        return 0
    fi

    # Try common installation directories
    local COMMON_DIRS=("/opt/crowdsecmetrics" "/usr/local/crowdsecmetrics" "$HOME/crowdsecmetrics")
    
    for dir in "${COMMON_DIRS[@]}"; do
        if [ -d "$dir" ] && [ -f "$dir/package.json" ] && grep -q "crowdsecmetrics" "$dir/package.json"; then
            echo "$dir"
            return 0
        fi
    done

    # If no directory found, use a default
    echo "/opt/crowdsecmetrics"
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

# Install Node.js and npm with robust dependency handling
install_nodejs() {
    log "Installing Node.js and npm..."
    
    # Attempt to fix broken packages first
    apt-get update
    apt-get install -f

    # Remove conflicting packages
    apt-get remove -y nodejs npm node-gyp

    # Install required dependencies
    apt-get install -y curl software-properties-common

    # Clean up any existing Node.js repositories
    rm -f /etc/apt/sources.list.d/*nodesource*

    # Install NodeSource repository and Node.js
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -

    # Install Node.js with all dependencies
    apt-get install -y --no-install-recommends nodejs

    # Verify and display versions
    log "Node.js version: $(node --version)"
    log "npm version: $(npm --version)"

    # Install npm globally with recommended packages
    npm install -g npm@latest
}

# Validate system requirements with enhanced error handling
validate_requirements() {
    # Comprehensive Node.js and npm check
    if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
        warning "Node.js or npm not found. Attempting comprehensive installation..."
        install_nodejs
    else
        # Check Node.js version
        NODE_VERSION=$(node --version | cut -d'.' -f1 | sed 's/v//')
        if [[ "$NODE_VERSION" -lt 16 ]]; then
            warning "Node.js version is too old. Upgrading..."
            install_nodejs
        fi
    fi

    # Additional development tools
    apt-get install -y build-essential

    # CrowdSec check remains the same
    if ! command -v cscli &> /dev/null; then
        error "CrowdSec is not installed. Please install CrowdSec first."
    fi
}

# Install system dependencies with fallback
install_dependencies() {
    log "Installing system dependencies..."
    
    # Ensure package lists are up to date
    apt-get update

    # Install core dependencies
    apt-get install -y \
        git \
        nginx \
        curl \
        software-properties-common \
        ca-certificates \
        gnupg \
        lsb-release \
        net-tools \
        build-essential

    # Additional error handling for dependency installation
    if [ $? -ne 0 ]; then
        error "Failed to install system dependencies. Please check your package manager."
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

# Clone the repository
clone_repository() {
    local PROJECT_DIR
    PROJECT_DIR=$(find_project_directory)
    log "Using project directory: $PROJECT_DIR"
    
    # Ensure directory exists
    mkdir -p "$PROJECT_DIR"
    
    # If directory is empty, clone the repository
    if [ -z "$(ls -A "$PROJECT_DIR")" ]; then
        log "Cloning CrowdSec Metrics Dashboard repository..."
        git clone https://github.com/fertigq/crowdsecmetrics.git "$PROJECT_DIR" || error "Failed to clone repository"
    else
        log "Using existing project directory"
    fi
    
    # Change to project directory
    cd "$PROJECT_DIR" || error "Unable to change to project directory"
    
    # Verify repository contents
    if [ ! -f "package.json" ]; then
        error "Invalid project directory. Missing package.json"
    fi
}

# Install project dependencies
install_project_dependencies() {
    log "Installing project dependencies..."
    
    # Install global dependencies
    npm install -g postcss tailwindcss vite typescript

    # Ensure configuration files exist
    if [ ! -f "postcss.config.js" ]; then
        log "Creating postcss.config.js..."
        cat > postcss.config.js << 'EOL'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOL
    fi

    if [ ! -f "tailwind.config.js" ]; then
        log "Creating tailwind.config.js..."
        cat > tailwind.config.js << 'EOL'
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOL
    fi

    # Install project dependencies with force
    npm install --force || {
        warning "Standard npm install failed. Attempting alternative installation..."
        rm -rf node_modules package-lock.json
        npm install --legacy-peer-deps
    }

    # Ensure Tailwind and PostCSS are installed
    npm install -D postcss tailwindcss autoprefixer @vitejs/plugin-react

    # Run build process with additional error handling
    log "Building project..."
    npm run build || {
        error "Project build failed. Check your build configuration and dependencies."
    }
}

# Configure environment
configure_environment() {
    local PORT HOST
    log "Configuring environment..."
    
    # Copy example environment file if .env doesn't exist
    if [ ! -f .env ]; then
        cp .env.example .env || error "Failed to create .env file"
    fi
    
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
    local PROJECT_DIR
    PROJECT_DIR=$(find_project_directory)
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
