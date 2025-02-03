// @ts-check
const express = require('express');
const { exec } = require('child_process');
const path = require('path');
const cors = require('cors');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3456;

// Enable CORS for development
app.use(cors());

// Serve static files from the 'dist' directory after building
app.use(express.static(path.join(__dirname, 'dist')));

// Utility function for safe command execution
function executeCommand(command, container = null) {
    return new Promise((resolve, reject) => {
        const fullCommand = container 
            ? `docker exec ${container} ${command}` 
            : command;
        
        exec(fullCommand, { timeout: 10000 }, (error, stdout, stderr) => {
            if (error) {
                console.error(`Command execution error: ${error}`);
                resolve({ error: true, message: error.message });
                return;
            }
            resolve({ 
                error: false, 
                output: stdout.trim() 
            });
        });
    });
}

// CrowdSec Metrics Route
app.get('/api/crowdsec-metrics', async (req, res) => {
    try {
        // Fetch local API decisions
        const decisionsResult = await executeCommand('cscli metrics', 'crowdsec');
        
        if (decisionsResult.error) {
            throw new Error(decisionsResult.message);
        }

        // Parse the metrics output
        const decisionLines = decisionsResult.output.split('\n')
            .slice(2) // Remove header lines
            .filter(line => line.trim() && !line.includes('----'))
            .map(line => {
                const parts = line.trim().split('|').map(p => p.trim());
                return {
                    reason: parts[0].replace('crowdsecurity/', ''),
                    origin: parts[1],
                    action: parts[2],
                    count: parseInt(parts[3]) || 0
                };
            })
            .filter(item => item.count > 0)
            .sort((a, b) => b.count - a.count);

        res.json(decisionLines);
    } catch (error) {
        console.error('Error fetching CrowdSec metrics:', error);
        res.status(500).json({ 
            error: true, 
            message: 'Failed to retrieve CrowdSec metrics' 
        });
    }
});

// System Metrics Route
app.get('/api/system-metrics', async (req, res) => {
    try {
        const [uptimeResult, memoryResult, diskResult] = await Promise.all([
            executeCommand('uptime'),
            executeCommand('free -h'),
            executeCommand('df -h /')
        ]);
        
        // Parse uptime
        const uptimeMatch = uptimeResult.output.match(/up\s+(.+?),\s+\d+ users?,\s+load average:\s+(.+)/);
        
        // Parse memory
        const memoryLines = memoryResult.output.split('\n');
        const memoryInfo = memoryLines[1].split(/\s+/);
        
        // Parse disk
        const diskLine = diskResult.output.split('\n')[1].split(/\s+/);
        
        const metrics = {
            uptime: uptimeMatch ? uptimeMatch[1] : 'Unable to retrieve',
            loadAverage: uptimeMatch ? uptimeMatch[2] : 'Unable to retrieve',
            memory: {
                total: memoryInfo[1],
                used: memoryInfo[2],
                free: memoryInfo[3]
            },
            disk: {
                total: diskLine[1],
                used: diskLine[2],
                available: diskLine[3],
                usePercentage: diskLine[4]
            }
        };
        
        res.json(metrics);
    } catch (error) {
        console.error('Error gathering system metrics:', error);
        res.status(500).json({ 
            error: true, 
            message: 'Failed to retrieve system metrics' 
        });
    }
});

// Catch-all route to serve the React app
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'dist', 'index.html'));
});

// Start the server
app.listen(port, '0.0.0.0', () => {
    console.log(`CrowdSec Metrics Dashboard running on http://0.0.0.0:${port}`);
});