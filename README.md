# 🚀 CrowdSec Metrics Dashboard

## 🎯 Project Purpose
A beautiful, real-time dashboard for monitoring CrowdSec metrics and system statistics.

### What This Project Does
- Real-time metrics display
- System statistics monitoring
- Beautiful, responsive UI
- Auto-refresh every 30 seconds
- Easy installation

### Not Designed For
- Complex data analysis
- Long-term data storage
- High-performance computing

## ⚙️ Technical Overview
CrowdSec Metrics Dashboard is built using Node.js and utilizes Docker for containerized deployment. It connects to a running CrowdSec instance to fetch metrics and system statistics.

### Core Technologies
- Node.js
- Docker
- CrowdSec

## 📋 Requirements
- Node.js 16+
- CrowdSec installed and running
- Docker (if using containerized CrowdSec)
- Sudo access

## 🚀 Quick Start Guide

### Automatic Installation
```bash
# Clone the repository
git clone https://github.com/fertigq/crowdsecmetrics.git

# Run the installation script
cd crowdsecmetrics
sudo ./install.sh
```

The installation script will:
- Prompt for dashboard port
- Detect server IP
- Install dependencies
- Configure firewall
- Set up systemd service

### Manual Installation
```bash
# Clone the repository
git clone https://github.com/fertigq/crowdsecmetrics.git
cd crowdsecmetrics

# Install dependencies
npm install

# Configure environment
cp .env.example .env
nano .env  # Customize your configuration

# Build the project
npm run build

# Start the server
npm start
```

## 🗑️ Uninstallation

### Automatic Uninstallation
```bash
# Navigate to the project directory
cd /opt/crowdsecmetrics

# Run the uninstall script with sudo
sudo ./uninstall.sh
```

### What the Uninstaller Does
- Stops and disables the systemd service
- Removes firewall rules
- Deletes the project directory
- Cleans up any global npm packages

### Manual Cleanup
If you want to completely remove all traces:
```bash
# Remove systemd service
sudo systemctl stop crowdsecmetrics
sudo systemctl disable crowdsecmetrics
sudo rm /etc/systemd/system/crowdsecmetrics.service

# Remove project directory
sudo rm -rf /opt/crowdsecmetrics

# Remove firewall rules (adjust as needed)
sudo ufw delete allow 47392/tcp  # Replace with your actual port
```

## ⚡ Configuration Options
Edit the `.env` file to customize:

- `PORT`: Dashboard port (default: 47392)
- `HOST`: Host IP address
- `CROWDSEC_CONTAINER`: Docker container name
- `HOST_METRICS`: Enable host-level metrics
- `DOCKER_METRICS`: Enable Docker metrics
- `REFRESH_INTERVAL`: Metrics refresh rate

## 📊 Key Features
- Real-time metrics display
- System statistics monitoring
- Beautiful, responsive UI
- Auto-refresh every 30 seconds
- Easy installation

## 🔒 Security Advisory
### Critical Considerations
- Ensure proper configuration of CrowdSec instance
- Limit access to the dashboard
- Use a firewall to restrict access

### Recommended Practices
- Regularly update dependencies
- Monitor system logs
- Use strong, unique ports

## ⚠️ Precautionary Warning
**No warranties whatsoever**

Production Use: Not recommended for mission-critical systems without thorough testing.

## 🔍 Troubleshooting Guide

| Symptom | Checks |
|---------|--------|
| Unable to connect to CrowdSec instance | Check CrowdSec instance status and configuration |
| Dashboard not refreshing | Check auto-refresh interval and system logs |
| Port already in use | Choose a different port during installation |

## 🤝 Contribution Guidelines
Contributions are welcome! Please follow these steps:
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📜 Credits & Recognition
### Essential Dependencies
- Node.js
- Docker
- CrowdSec

### Development Acknowledgement
This project is a work in progress. Powered by creativity and continuous learning.

## 📄 License
MIT

**Disclaimer:** This is an independent project. Use at your own risk.
