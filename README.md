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

## 🚀 Quick Start Guide

### Installation
```bash
# Clone the repository
git clone https://github.com/fertigq/crowdsecmetrics.git
cd crowdsecmetrics

# Install dependencies
npm install

# Configure environment
cp example.env .env
nano .env  # Customize your configuration
```

### Running the Project
```bash
# Start the development server
node server.js

# Build for production
npm run build

# Start production server
npm start
```

## ⚡ Configuration Options
Edit the `.env` file to customize:

- `PORT`: Port number (default: 3456)
- `HOST`: Host address (default: 0.0.0.0)
- `ENVIRONMENT`: Environment settings

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

### Recommended Practices
- Regularly update dependencies
- Monitor system logs

## ⚠️ Precautionary Warning
**No warranties whatsoever**

Production Use: Not recommended for mission-critical systems without thorough testing.

## 🔍 Troubleshooting Guide

| Symptom | Checks |
|---------|--------|
| Unable to connect to CrowdSec instance | Check CrowdSec instance status and configuration |
| Dashboard not refreshing | Check auto-refresh interval and system logs |

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
